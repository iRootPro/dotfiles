import type { Plugin } from "@opencode-ai/plugin"
import { spawn } from "node:child_process"

type State = "working" | "waiting" | "idle" | "unknown"

const script = `${process.env.HOME}/.config/tmux/scripts/tmux-opencode-session-manager.sh`

function setState(state: State, sessionID?: string) {
  if (!process.env.TMUX_PANE) return

  const child = spawn(script, ["state", state, sessionID ?? ""], {
    detached: true,
    env: process.env,
    stdio: "ignore",
  })
  child.unref()
}

export default (async () => {
  return {
    "chat.message": async (input) => {
      setState("working", input.sessionID)
    },

    "permission.ask": async (input) => {
      setState("waiting", input.sessionID)
    },

    "tool.execute.before": async (input) => {
      setState("working", input.sessionID)
    },

    "tool.execute.after": async (input) => {
      setState("working", input.sessionID)
    },

    event: async ({ event }) => {
      switch (event.type) {
        case "session.status": {
          const state = event.properties.status.type
          if (state === "busy") setState("working", event.properties.sessionID)
          if (state === "idle") setState("idle", event.properties.sessionID)
          if (state === "retry") setState("working", event.properties.sessionID)
          break
        }

        case "session.idle":
          setState("idle", event.properties.sessionID)
          break

        case "permission.updated":
          setState("waiting", event.properties.sessionID)
          break

        case "permission.replied":
          setState("working", event.properties.sessionID)
          break
      }
    },
  }
}) satisfies Plugin
