// JS Hook for browser Geolocation API integration with memory-leak safety, initial mount check, and seamless reconnect support
export const Geolocation = {
  mounted() {
    this.intervalId = null

    // Safe timer cleanup helper to prevent memory leaks
    this.clearTimer = () => {
      if (this.intervalId !== null) {
        clearInterval(this.intervalId)
        this.intervalId = null
      }
    }

    // Internal helper function to fetch current position
    const fetchLocation = () => {
      if (!navigator.geolocation) {
        this.pushEvent("geolocation_error", {
          message: "Geolocation is not supported by your browser."
        })
        return
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          // Push location coordinates back to LiveView server process
          this.pushEvent("geolocation_success", {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: Math.round(position.coords.accuracy)
          })
        },
        (error) => {
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
      this.clearTimer()
      this.intervalId = setInterval(fetchLocation, 5 * 60 * 1000)
    }

    // Auto-start 5-minute tracking on initial mount if server rendered toggle as checked
    const toggleInput = this.el.querySelector('#location-toggle-input')
    if (toggleInput && toggleInput.checked) {
      this.startInterval()
    }

    // Single request handler
    this.handleEvent("request_geolocation", () => {
      fetchLocation()
    })

    // Start periodic 5-minute location updates (300,000 ms)
    this.handleEvent("start_periodic_geolocation", () => {
      this.startInterval()
    })

    // Stop periodic location updates when toggle is OFF
    this.handleEvent("stop_periodic_geolocation", () => {
      this.clearTimer()
    })
  },

  // Called when LiveView connection drops
  disconnected() {
    this.clearTimer && this.clearTimer()
  },

  // Called when LiveView reconnects: clear any old timer and resume if toggle is ON
  reconnected() {
    this.clearTimer && this.clearTimer()

    // Check specific location toggle switch by ID in DOM and resume interval tracking safely
    const toggleInput = this.el.querySelector('#location-toggle-input')
    if (toggleInput && toggleInput.checked && this.startInterval) {
      this.startInterval()
    }
  },

  // Called when the Hook element is removed from the DOM
  destroyed() {
    this.clearTimer && this.clearTimer()
  }
}
