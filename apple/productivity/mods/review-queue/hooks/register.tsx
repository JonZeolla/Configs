import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Pr } from '../types'

// gh pr list adds is:open is:pr itself; the web page needs them spelled.
const QUERY =
  '-label:"Automatic update" -label:blocked -label:paused -author:@me review:none draft:false sort:created-asc'
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

type GhPr = Pick<Pr, 'number' | 'title' | 'url' | 'createdAt'> & {
  author: { login: string }
  labels: { name: string }[]
}

const waiting = atom({ plugin: 'review-queue', key: 'waiting' } as const, null as Pr[] | null)
const isOpen = atom({ plugin: 'review-queue', key: 'isOpen' } as const, false)

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
    const poll = async () => {
      let found: Pr[] | null = null
      try {
        // The search index knows who a PR mentions; reading every comment of
        // every PR would cost far more of the API budget per poll.
        // A PR that names me is requested whatever its labels, reviews or
        // draft state, so its search carries none of QUERY's filters.
        const fields = ['--json', 'number,title,url,author,createdAt,labels']
        const [ready, mine] = await Promise.all([
          $.process.run([...LIST, QUERY, ...fields]),
          $.process.run([...LIST, 'mentions:@me sort:created-asc', ...fields]),
        ])
        if (ready.exitCode === 0 && mine.exitCode === 0) {
          const requested = JSON.parse(mine.stdout) as GhPr[]
          const asked = new Set(requested.map(pr => pr.number))
          const rest = (JSON.parse(ready.stdout) as GhPr[]).filter(pr => !asked.has(pr.number))
          found = [...requested, ...rest].map(pr => ({
            isRequested: asked.has(pr.number),
            number: pr.number,
            title: pr.title,
            url: pr.url,
            createdAt: pr.createdAt,
            author: pr.author.login,
            risk:
              pr.labels.find(label => label.name.startsWith(RISK_LABEL))?.name.slice(RISK_LABEL.length) ??
              null,
          }))
        }
      } catch {
        // No gh, no repo or no network: found stays null.
      }
      await update($, waiting, () => found)
    }

    void poll()
    $.clock.every(PERIOD_MS, poll)
    return started
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e)
    const prs = await read($, waiting)
    const toggle = () => update($, isOpen, open => !open)
    // A click reaches a Button on every terminal; an OSC 8 link needs cmd-click
    // or is swallowed by mouse capture. shortcut: `open` is macOS only.
    const browse = (url: string) => async () => {
      await $.process.run(['open', url])
    }

    const button = (
      <Box flexDirection="row" width={e.props.bodyColumns}>
        <Box flexGrow={1} />
        {prs?.length ? (
          <Button key="reviews" plain onPress={toggle}>
            <Text bold inverse color="warning">
              {' Reviews '}
            </Text>
          </Button>
        ) : (
          <Button key="reviews" plain label={prs ? 'Reviews' : 'Reviews ?'} onPress={toggle} />
        )}
      </Box>
    )
    if (!(await read($, isOpen))) return button
    if (prs === null) {
      return (
        <Box flexDirection="column">
          {button}
          <Text dimColor>gh could not list the PRs of this folder.</Text>
        </Box>
      )
    }
    if (prs.length === 0) {
      return (
        <Box flexDirection="column">
          {button}
          <Text dimColor>No PR waits for a first review.</Text>
        </Box>
      )
    }

    const now = await $.clock.now()
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
    // A long title must not squeeze the columns left of it: they keep their
    // width and the title is cut to what is left of the row.
    const titleWidth = Math.max(10, e.props.bodyColumns - (4 + 1 + authorWidth + 1 + NO_RISK.length + 1))
    const cut = (text: string) => (text.length > titleWidth ? `${text.slice(0, titleWidth - 1)}…` : text)
    const row = (pr: Pr) => (
      <Box key={String(pr.number)} flexDirection="row" gap={1}>
        <Box flexShrink={0}>
          <Text dimColor>
            {age(now - Date.parse(pr.createdAt)).padStart(4)} {pr.author.padEnd(authorWidth)}
          </Text>
        </Box>
        <Box flexShrink={0}>
          <Text color={pr.risk ? RISK_TONE[pr.risk] : undefined} dimColor={!pr.risk}>
            {(pr.risk ?? NO_RISK).padEnd(NO_RISK.length)}
          </Text>
        </Box>
        <Button key={`pr-${pr.number}`} plain label={cut(`#${pr.number} ${pr.title}`)} onPress={browse(pr.url)} />
      </Box>
    )

    return (
      <Box flexDirection="column">
        {button}
        {groups.flatMap(group => [
          <Text key={group.title} bold inverse={group.isLoud && group.prs.length > 0} color={group.isLoud ? 'warning' : undefined}>
            {group.isLoud && group.prs.length > 0 ? ` ${group.title} ` : group.title}
            {group.prs.length === 0 && ': None'}
          </Text>,
          ...group.prs.map(row),
        ])}
        <Button key="all" plain label="All on GitHub" onPress={browse(all)} />
      </Box>
    )
  })
}
