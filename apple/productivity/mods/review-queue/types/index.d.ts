// risk is the part after `zenable/risk:` of that label; null before Zenable set one.
export type Pr = {
  number: number
  title: string
  url: string
  author: string
  createdAt: string
  risk: string | null
  // A comment or the description of the PR names me.
  isRequested: boolean
}

// My own PRs, up for review and not blocked.
export type Mine = {
  // Checks pass, and approved or low risk.
  ready: Pr[]
  // A check failed.
  broken: Pr[]
}

// The list that is open under the buttons.
export type Panel = 'reviews' | 'ready' | 'broken'

// waiting and mine are null when gh could not answer: unknown, never a false "none".
declare module 'claude-code' {
  interface PluginState {
    'review-queue': { waiting: Pr[] | null; mine: Mine | null; panel: Panel | null }
  }
}
