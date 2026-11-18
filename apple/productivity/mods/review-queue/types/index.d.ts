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

// waiting is null when gh could not answer: unknown, never a false "none".
declare module 'claude-code' {
  interface PluginState {
    'review-queue': { waiting: Pr[] | null; isOpen: boolean }
  }
}
