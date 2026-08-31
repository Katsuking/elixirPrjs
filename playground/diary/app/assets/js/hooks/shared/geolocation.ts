import { toApproximateLocation, ApproximateLocationResult } from "../../utils/h3_calculator"

export interface LiveViewHook {
  el: HTMLElement
  intervalId: number | ReturnType<typeof setInterval> | null
  clearTimer?: () => void
  startInterval?: () => void
  pushEvent(event: string, payload: object): void
  handleEvent(event: string, callback: (payload: any) => void): void
  mounted(): void
  disconnected(): void
  reconnected(): void
  destroyed(): void
}

// JS Hook for browser Geolocation API integration with memory-leak safety, initial mount check, and seamless reconnect support
export const Geolocation = {
  mounted(this: LiveViewHook) {
    this.intervalId = null

    // Safe timer cleanup helper to prevent memory leaks
    this.clearTimer = () => {
      if (this.intervalId !== null) {
        clearInterval(this.intervalId)
        this.intervalId = null
      }
    }

    // Internal helper function to fetch current position and convert to H3 approximate location
    const fetchLocation = () => {
      if (!navigator.geolocation) {
        this.pushEvent("geolocation_error", {
          message: "Geolocation is not supported by your browser."
        })
        return
      }

      navigator.geolocation.getCurrentPosition(
        (position: GeolocationPosition) => {
          const lat: number = position.coords.latitude
          const lng: number = position.coords.longitude

          // Calculate Resolution 8 and Resolution 7 H3 index and approximate center coordinates
          const locationData: ApproximateLocationResult = toApproximateLocation(lat, lng)

          // Push privacy-friendly H3 approximate location coordinates back to LiveView (No exact raw coordinates sent!)
          this.pushEvent("geolocation_success", {
            accuracy: Math.round(position.coords.accuracy),
            h3_index_res8: locationData.h3IndexRes8,
            approx_latitude_res8: locationData.approxLat8,
            approx_longitude_res8: locationData.approxLng8,
            h3_index_res7: locationData.h3IndexRes7,
            approx_latitude_res7: locationData.approxLat7,
            approx_longitude_res7: locationData.approxLng7
          })
        },
        (error: GeolocationPositionError) => {
          // Push permission/device error back to LiveView server process
          this.pushEvent("geolocation_error", {
            code: error.code,
            message: error.message
          })
        },
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
      )
    }

    // Helper function to safely start periodic 5-minute interval
    this.startInterval = () => {
      fetchLocation()
      if (this.clearTimer) this.clearTimer()
      this.intervalId = setInterval(fetchLocation, 5 * 60 * 1000)
    }

    // Auto-start 5-minute tracking on initial mount if server rendered toggle as checked
    const toggleInput = this.el.querySelector('#location-toggle-input') as HTMLInputElement | null
    if (toggleInput && toggleInput.checked) {
      this.startInterval()
    }

    // Single request handler
    this.handleEvent("request_geolocation", () => {
      fetchLocation()
    })

    // Start periodic 5-minute location updates (300,000 ms)
    this.handleEvent("start_periodic_geolocation", () => {
      if (this.startInterval) this.startInterval()
    })

    // Stop periodic location updates when toggle is OFF
    this.handleEvent("stop_periodic_geolocation", () => {
      if (this.clearTimer) this.clearTimer()
    })
  },

  // Called when LiveView connection drops
  disconnected(this: LiveViewHook) {
    if (this.clearTimer) this.clearTimer()
  },

  // Called when LiveView reconnects: clear any old timer and resume if toggle is ON
  reconnected(this: LiveViewHook) {
    if (this.clearTimer) this.clearTimer()

    // Check specific location toggle switch by ID in DOM and resume interval tracking safely
    const toggleInput = this.el.querySelector('#location-toggle-input') as HTMLInputElement | null
    if (toggleInput && toggleInput.checked && this.startInterval) {
      this.startInterval()
    }
  },

  // Called when the Hook element is removed from the DOM
  destroyed(this: LiveViewHook) {
    if (this.clearTimer) this.clearTimer()
  }
}
