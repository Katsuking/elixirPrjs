// Aggregates all custom LiveView hooks across shared and service-specific modules
import { Geolocation } from "./shared/geolocation"

const Hooks: Record<string, any> = {
  Geolocation
}

export default Hooks
