import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Mine, Panel, Pr } from '../types'

// gh pr list adds is:open is:pr itself; the web page needs them spelled.
const QUERY =
  '-label:"Automatic update" -label:blocked -label:paused -label:"zenable/risk:low" -author:@me review:none draft:false sort:created-asc'
const PERIOD_MS = 5 * 60 * 1000
const RISK_LABEL = 'zenable/risk:'
const NO_RISK = 'no risk yet'
const RISK_TONE: Record<string, string> = {
  low: 'success',
  medium: 'warning',
  high: 'error',
  critical: 'error',
}

const LIST = ['gh', 'pr', 'list', '--search']
// Asks me (or a team of mine) for a review. Code owner requests are routine,
// so these wait with the rest, under the same filters, and not under Requested.
const OWED = QUERY.replace('review:none', 'review-requested:@me')
// `mentions:` misses a mention made in a review comment on the diff; the text
// search finds it. It takes a login, as @me is not expanded inside a phrase.
const mentions = (login: string) => `"@${login}" in:body,comments -author:@me sort:created-asc`
const WHOAMI = ['gh', 'api', 'user', '--jq', '.login']
// What can name me in a PR. Only a review thread can be resolved.
const TEXTS =
  'body comments(last:50){nodes{body}} reviews(last:50){nodes{body}} reviewThreads(last:50){nodes{isResolved comments(first:20){nodes{body}}}}'

type Texts = {
  body: string
  comments: { nodes: { body: string }[] }
  reviews: { nodes: { body: string }[] }
  reviewThreads: { nodes: { isResolved: boolean; comments: { nodes: { body: string }[] } }[] }
}

// My own PRs that are up for review. A blocked or paused one is neither ready
// to merge nor broken: it waits on purpose.
const MINE = 'author:@me draft:false -label:blocked -label:paused sort:created-asc'
const LOW = 'low'
// The checks of the last commit, and whether the branch rules require each.
const checks = (number: number) =>
  `mergeable commits(last:1){nodes{commit{statusCheckRollup{contexts(first:100){nodes{__typename ... on CheckRun{conclusion isRequired(pullRequestNumber:${number})} ... on StatusContext{state isRequired(pullRequestNumber:${number})}}}}}}}`
const PASSED = new Set(['SUCCESS', 'NEUTRAL', 'SKIPPED'])
const RUNNING = new Set(['PENDING', 'EXPECTED'])

type Check = { conclusion?: string | null; state?: string; isRequired: boolean }
type Checks = {
  mergeable: string
  commits: { nodes: { commit: { statusCheckRollup: { contexts: { nodes: Check[] } } | null } }[] }
}

// Only the required checks decide, as a failed optional one does not stop a
// merge; a repo that requires none is judged on all of them.
const ci = (pr: Checks): 'passing' | 'failing' | 'running' => {
  const all = pr.commits.nodes[0]?.commit.statusCheckRollup?.contexts.nodes ?? []
  const required = all.filter(check => check.isRequired)
  const results = (required.length > 0 ? required : all).map(check => {
    // A check run has a conclusion, null until it ends; a status has a state.
    const result = 'state' in check ? check.state : check.conclusion
    if (!result || RUNNING.has(result)) return 'running'
    return PASSED.has(result) ? 'passing' : 'failing'
  })
  if (results.includes('failing')) return 'failing'
  return results.includes('running') ? 'running' : 'passing'
}

type GhPr = Pick<Pr, 'number' | 'title' | 'url' | 'createdAt'> & {
  // APPROVED, CHANGES_REQUESTED, REVIEW_REQUIRED, or '' when no rule asks for a review.
  reviewDecision: string
  author: { login: string }
  labels: { name: string }[]
}

const waiting = atom({ plugin: 'review-queue', key: 'waiting' } as const, null as Pr[] | null)
const mine = atom({ plugin: 'review-queue', key: 'mine' } as const, null as Mine | null)
const panel = atom({ plugin: 'review-queue', key: 'panel' } as const, null as Panel | null)

const listed = (pr: GhPr, isRequested: boolean): Pr => ({
  isRequested,
  number: pr.number,
  title: pr.title,
  url: pr.url,
  createdAt: pr.createdAt,
  author: pr.author.login,
  risk: pr.labels.find(label => label.name.startsWith(RISK_LABEL))?.name.slice(RISK_LABEL.length) ?? null,
})

const age = (ms: number) => {
  const minutes = Math.max(0, Math.floor(ms / 60_000))
  if (minutes < 60) return `${minutes}m`
  return minutes < 60 * 24 ? `${Math.floor(minutes / 60)}h` : `${Math.floor(minutes / 60 / 24)}d`
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const started = await next(e)
    if (!e.isInteractive) return started

    // shortcut: asks only about the repo the session runs in; switch to
    // `gh search prs --owner` when reviews in other repos matter.
    let login = ''
    // One GraphQL read of the same fields of each PR, keyed `p<number>`. A
    // failed read throws, so the poll reports unknown.
    const perPr = async <T,>(prs: GhPr[], fields: (number: number) => string) => {
      const [, owner, name] = prs[0]?.url.match(/\/([^/]+)\/([^/]+)\/pull\/\d+$/) ?? []
      if (!owner || !name) return {}
      const each = prs.map(pr => `p${pr.number}:pullRequest(number:${pr.number}){${fields(pr.number)}}`).join(' ')
      const read = await $.process.run([
        'gh',
        'api',
        'graphql',
        '-f',
        `query={repository(owner:"${owner}",name:"${name}"){${each}}}`,
      ])
      if (read.exitCode !== 0) throw new Error(read.stderr)
      return (JSON.parse(read.stdout) as { data: { repository: Record<string, T | null> } }).data.repository
    }
    // The PRs that still name me: in the description, a comment, a review, or
    // a review thread nobody resolved.
    const unresolved = async (prs: GhPr[]) => {
      const texts = await perPr<Texts>(prs, () => TEXTS)
      const me = `@${login.toLowerCase()}`
      const names = (nodes: { body: string }[]) => nodes.some(node => node.body.toLowerCase().includes(me))
      return prs.filter(pr => {
        const text = texts[`p${pr.number}`]
        if (!text) return false
        return (
          names([text, ...text.comments.nodes, ...text.reviews.nodes]) ||
          text.reviewThreads.nodes.some(thread => !thread.isResolved && names(thread.comments.nodes))
        )
      })
    }
    const poll = async () => {
      let found: Pr[] | null = null
      try {
        // The search index knows whom a PR names; reading every comment of
        // every PR would cost far more of the API budget per poll. Only the
        // few PRs it returns are read, to drop a mention in a resolved thread.
        // A PR that names me is requested whatever its labels, reviews or
        // draft state, so its search carries none of QUERY's filters.
        const fields = ['--json', 'number,title,url,author,createdAt,labels,reviewDecision']
        login ||= await $.process.run(WHOAMI).then(run => (run.exitCode === 0 ? run.stdout.trim() : ''))
        const runs = login
          ? await Promise.all(
              [mentions(login), QUERY, OWED].map(query => $.process.run([...LIST, query, ...fields])),
            )
          : []
        if (runs.length > 0 && runs.every(run => run.exitCode === 0)) {
          const [named = [], ...ready] = runs.map(run => JSON.parse(run.stdout) as GhPr[])
          const naming = await unresolved(named)
          // A PR that names me stays even when approved. Any other approved PR
          // can merge without me, so it leaves the list; one that still needs
          // its code owner stays REVIEW_REQUIRED and is kept.
          const asked = new Set(naming.map(pr => pr.number))
          const rest = new Map(
            ready
              .flat()
              .filter(pr => pr.reviewDecision !== 'APPROVED' && !asked.has(pr.number))
              .map(pr => [pr.number, pr]),
          )
          const oldestFirst = [...rest.values()].sort((a, b) => a.createdAt.localeCompare(b.createdAt))
          found = [...naming, ...oldestFirst].map(pr => listed(pr, asked.has(pr.number)))
        }
      } catch {
        // No gh, no repo or no network: found stays null.
      }
      await update($, waiting, () => found)
    }
    // Ready to merge: the checks pass, nothing conflicts, and it has its
    // approval, or is low risk and needs none. Unresolved comments are not
    // counted against it. Broken: a check failed.
    const pollMine = async () => {
      let found: Mine | null = null
      try {
        const run = await $.process.run([
          ...LIST,
          MINE,
          '--json',
          'number,title,url,author,createdAt,labels,reviewDecision',
        ])
        if (run.exitCode === 0) {
          const prs = JSON.parse(run.stdout) as GhPr[]
          const read = await perPr<Checks>(prs, checks)
          const state = (pr: GhPr) => {
            const checked = read[`p${pr.number}`]
            return checked ? { ci: ci(checked), mergeable: checked.mergeable } : null
          }
          const isReviewed = (pr: GhPr) =>
            pr.reviewDecision === 'APPROVED' ||
            (pr.reviewDecision !== 'CHANGES_REQUESTED' && pr.labels.some(label => label.name === RISK_LABEL + LOW))
          found = {
            ready: prs
              .filter(pr => state(pr)?.ci === 'passing' && state(pr)?.mergeable !== 'CONFLICTING' && isReviewed(pr))
              .map(pr => listed(pr, false)),
            broken: prs.filter(pr => state(pr)?.ci === 'failing').map(pr => listed(pr, false)),
          }
        }
      } catch {
        // No gh, no repo or no network: found stays null.
      }
      await update($, mine, () => found)
    }

    void poll()
    void pollMine()
    $.clock.every(PERIOD_MS, poll)
    $.clock.every(PERIOD_MS, pollMine)
    return started
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e)
    const prs = await read($, waiting)
    const own = await read($, mine)
    const open = await read($, panel)
    // A click reaches a Button on every terminal; an OSC 8 link needs cmd-click
    // or is swallowed by mouse capture. shortcut: `open` is macOS only.
    const browse = (url: string) => async () => {
      await $.process.run(['open', url])
    }

    // One list is open at a time; a press on its own button closes it.
    const tab = (key: Panel, label: string, list: Pr[] | null | undefined, color: string) => {
      const toggle = () => update($, panel, now => (now === key ? null : key))
      return list?.length ? (
        <Button key={key} plain onPress={toggle}>
          <Text bold inverse color={color}>
            {` ${label} `}
          </Text>
        </Button>
      ) : (
        <Button key={key} plain label={list ? label : `${label} ?`} onPress={toggle} />
      )
    }
    const button = (
      <Box flexDirection="row" gap={2} width={e.props.bodyColumns}>
        <Box flexGrow={1} />
        {tab('reviews', 'Reviews', prs, 'warning')}
        {tab('ready', 'Merge Ready', own?.ready, 'warning')}
        {tab('broken', 'Broken PR', own?.broken, 'error')}
      </Box>
    )
    if (!open) return button
    const note = (text: string) => (
      <Box flexDirection="column">
        {button}
        <Text dimColor>{text}</Text>
      </Box>
    )
    const now = await $.clock.now()
    // A long title must not squeeze the columns left of it: they keep their
    // width and the title is cut to what is left of the row.
    const rows = (list: Pr[], authorWidth: number) => {
      const lead = 4 + (authorWidth > 0 ? 1 + authorWidth : 0)
      const titleWidth = Math.max(10, e.props.bodyColumns - (lead + 1 + NO_RISK.length + 1))
      const cut = (text: string) => (text.length > titleWidth ? `${text.slice(0, titleWidth - 1)}…` : text)
      return list.map(pr => (
        <Box key={String(pr.number)} flexDirection="row" gap={1}>
          <Box flexShrink={0}>
            <Text dimColor>
              {age(now - Date.parse(pr.createdAt)).padStart(4)}
              {authorWidth > 0 && ` ${pr.author.padEnd(authorWidth)}`}
            </Text>
          </Box>
          <Box flexShrink={0}>
            <Text color={pr.risk ? RISK_TONE[pr.risk] : undefined} dimColor={!pr.risk}>
              {(pr.risk ?? NO_RISK).padEnd(NO_RISK.length)}
            </Text>
          </Box>
          <Button key={`pr-${pr.number}`} plain label={cut(`#${pr.number} ${pr.title}`)} onPress={browse(pr.url)} />
        </Box>
      ))
    }

    if (open !== 'reviews') {
      if (own === null) return note('gh could not list your PRs in this folder.')
      const list = open === 'ready' ? own.ready : own.broken
      if (list.length === 0) {
        return note(open === 'ready' ? 'No PR of yours waits to be merged.' : 'No PR of yours has failing CI.')
      }
      // Every row is mine, so the author column is left out.
      return (
        <Box flexDirection="column">
          {button}
          {rows(list.slice(0, Math.max(1, e.props.maxRows - 1)), 0)}
        </Box>
      )
    }
    if (prs === null) return note('gh could not list the PRs of this folder.')
    if (prs.length === 0) return note('No PR waits for a first review.')

    const authorWidth = Math.max(...prs.map(pr => pr.author.length))
    const all = `${prs[0]!.url.replace(/\/pull\/\d+$/, '')}/pulls?q=${encodeURIComponent(`is:open is:pr ${QUERY}`)}`

    // The band cuts what does not fit; requested PRs come first, so they stay.
    const shown = [...prs.filter(pr => pr.isRequested), ...prs.filter(pr => !pr.isRequested)].slice(
      0,
      Math.max(1, e.props.maxRows - 4),
    )
    const groups = [
      { title: 'Requested', isLoud: true, prs: shown.filter(pr => pr.isRequested) },
      { title: 'Ready For Review', isLoud: false, prs: shown.filter(pr => !pr.isRequested) },
    ]
    return (
      <Box flexDirection="column">
        {button}
        {groups.flatMap(group => [
          <Text key={group.title} bold inverse={group.isLoud && group.prs.length > 0} color={group.isLoud ? 'warning' : undefined}>
            {group.isLoud && group.prs.length > 0 ? ` ${group.title} ` : group.title}
            {group.prs.length === 0 && ': None'}
          </Text>,
          ...rows(group.prs, authorWidth),
        ])}
        <Button key="all" plain label="All on GitHub" onPress={browse(all)} />
      </Box>
    )
  })
}
