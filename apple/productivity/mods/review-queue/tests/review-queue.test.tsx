import { expect, mock, test } from 'claude-code/testing'

const BAND = {
  plugin: 'review-queue',
  component: 'AbovePrompt',
  surface: 'terminal',
  props: {
    hasSurvey: false,
    isCollapsed: false,
    isWorking: false,
    maxRows: 10,
    bodyColumns: 80,
    scroll: { offset: 0, bodyRows: 10 },
    view: {},
  },
} as const

const ran = (exitCode: number, stdout: string) => ({
  value: { exitCode, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false },
})

const PR = {
  number: 7,
  title: `Add a thing ${'x'.repeat(100)}`,
  url: 'https://github.com/acme/app/pull/7',
  author: { login: 'octo' },
  createdAt: '1970-01-01T00:00:00Z',
  labels: [{ name: 'migration' }, { name: 'zenable/risk:high' }],
}

test('with PRs waiting the button is highlighted and a press lists them', async ($, on) => {
  const clock = mock.clock(on, { now: 3 * 24 * 60 * 60 * 1000 })
  const opened: string[] = []
  // #9 is a draft outside the review filter: only the mention search returns it.
  // #10 names me, so it is listed even though it is approved.
  let requested = JSON.stringify([
    { ...PR, number: 9, labels: [] },
    { ...PR, number: 8, labels: [] },
    { ...PR, number: 10, reviewDecision: 'APPROVED' },
    { ...PR, number: 13, labels: [] },
  ])
  // #13 names me only in a review thread that is resolved, so it is not listed.
  const quiet = { body: '', comments: { nodes: [] }, reviews: { nodes: [] }, reviewThreads: { nodes: [] } }
  const thread = (isResolved: boolean) => ({
    nodes: [{ isResolved, comments: { nodes: [{ body: '@Me what do you think?' }] } }],
  })
  const texts = JSON.stringify({
    data: {
      repository: {
        p9: { ...quiet, body: 'cc @me' },
        p8: { ...quiet, comments: { nodes: [{ body: '@me please look' }] } },
        p10: { ...quiet, reviewThreads: thread(false) },
        p13: { ...quiet, reviewThreads: thread(true) },
      },
    },
  })
  // #11 has an approval but still needs me as its code owner, so it waits with
  // the ready ones; #12 is approved and is not listed.
  let owned = JSON.stringify([
    { ...PR, number: 11, reviewDecision: 'REVIEW_REQUIRED' },
    { ...PR, number: 12, reviewDecision: 'APPROVED' },
  ])
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('process.run', (_, e) => {
    if (e.argv[0] !== 'open') {
      if (e.argv[1] === 'api') return ran(0, e.argv[2] === 'graphql' ? texts : 'me\n')
      if (e.argv[4] === '"@me" in:body,comments -author:@me sort:created-asc') return ran(0, requested)
      if (e.argv[4]?.includes('review-requested:@me')) return ran(0, owned)

      return ran(0, JSON.stringify([PR, { ...PR, number: 8, labels: [] }]))
    }
    opened.push(e.argv[1]!)

    return ran(0, '')
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await clock.advance(0)
  const ui = await $.ui.mount(BAND)
  const label = await ui.find({ type: 'Text', text: /Reviews/ })
  expect(label?.props).toMatchObject({ color: 'warning', inverse: true })
  expect(await ui.find({ type: 'Text', text: /octo/ })).toBeUndefined()

  await ui.press({ key: 'reviews' })
  expect((await ui.find({ type: 'Text', text: /octo/ }))?.text).toBe('  3d octo')
  expect((await ui.find({ type: 'Text', text: /high/ }))?.props.color).toBe('error')
  expect(await ui.find({ type: 'Text', text: /no risk yet/ })).toBeDefined()
  // #9 and #8 name me, so they lead under a highlighted Requested, and #8 is listed once.
  expect((await ui.find({ type: 'Text', text: /Requested/ }))?.props.inverse).toBe(true)
  const rows = (await ui.findAll({ type: 'Button' })).map(button => button.key)
  expect(rows).toEqual(['reviews', 'pr-9', 'pr-8', 'pr-10', 'pr-7', 'pr-11', 'all'])
  // 80 columns leave 58 for the title; the columns left of it keep their width.
  const long = await ui.find({ type: 'Button', key: 'pr-7' })
  expect(String(long?.props.label).length).toBe(58)

  await ui.press({ key: 'pr-7' })
  await ui.press({ key: 'all' })
  expect(opened).toEqual([
    'https://github.com/acme/app/pull/7',
    'https://github.com/acme/app/pulls?q=is%3Aopen%20is%3Apr%20-label%3A%22Automatic%20update%22%20-label%3Ablocked%20-label%3Apaused%20-label%3A%22zenable%2Frisk%3Alow%22%20-author%3A%40me%20review%3Anone%20draft%3Afalse%20sort%3Acreated-asc',
  ])

  requested = '[]'
  owned = '[]'
  await clock.advance(5 * 60 * 1000)
  expect((await ui.find({ type: 'Text', text: /Requested/ }))?.text).toBe('Requested: None')
  await ui.unmount()
})

test('with none waiting the button is plain and a press says so', async ($, on) => {
  const clock = mock.clock(on)
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('process.run', () => ran(0, '[]'))

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await clock.advance(0)
  const ui = await $.ui.mount(BAND)
  expect((await ui.find({ type: 'Button' }))?.props.label).toBe('Reviews')

  await ui.press({ key: 'reviews' })
  expect(await ui.find({ type: 'Text', text: /No PR waits/ })).toBeDefined()
  await ui.unmount()
})

test('a gh failure reads as unknown, never as none', async ($, on) => {
  const clock = mock.clock(on)
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('process.run', () => ran(1, ''))

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await clock.advance(0)
  const ui = await $.ui.mount(BAND)
  expect((await ui.find({ type: 'Button' }))?.props.label).toBe('Reviews ?')

  await ui.press({ key: 'reviews' })
  expect(await ui.find({ type: 'Text', text: /gh could not list/ })).toBeDefined()
  await ui.unmount()
})
