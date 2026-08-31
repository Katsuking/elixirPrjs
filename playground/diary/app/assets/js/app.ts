// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
// Import Socket type and constructor from phoenix package
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
// @ts-ignore - Ignore colocated hooks module resolution in TypeScript
import { hooks as colocatedHooks } from "phoenix-colocated/diary"
// @ts-ignore - Vendor topbar without type declaration
import topbar from "../vendor/topbar"
import customHooks from "./hooks"

// Declare custom window properties for Google Analytics and LiveSocket debugging
declare global {
  interface Window {
    gtag?: (...args: any[]) => void
    gtagId?: string
    liveSocket?: any
    liveReloader?: any
  }
}

// Combine colocated hooks with custom modularized hooks
const hooks = {
  ...colocatedHooks,
  ...customHooks
}

const csrfTokenMeta = document.querySelector("meta[name='csrf-token']")
const csrfToken = csrfTokenMeta ? csrfTokenMeta.getAttribute("content") : ""
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => {
  topbar.hide()

  // Track page view event on LiveView navigation if Google Analytics is enabled
  if (typeof window.gtag === "function" && window.gtagId) {
    window.gtag("config", window.gtagId, {
      page_path: window.location.pathname
    })
  }
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation
window.liveSocket = liveSocket

// Enable quality of life phoenix_live_reload development features in dev environment
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", (e: Event) => {
    const detail = (e as CustomEvent).detail
    const reloader = detail ? detail.reloader : null
    if (!reloader) return

    // Enable server log streaming to client console
    reloader.enableServerLogs()

    let keyDown: string | null = null
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
