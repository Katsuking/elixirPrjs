import { latLngToCell, cellToLatLng, cellToParent } from "h3-js"

export interface ApproximateLocationResult {
  h3IndexRes8: string
  approxLat8: number
  approxLng8: number
  h3IndexRes7: string
  approxLat7: number
  approxLng7: number
}

/**
 * Converts exact latitude and longitude into both Resolution 8 and Resolution 7 H3 cell indices and approximate coordinates.
 * @param lat Exact latitude
 * @param lng Exact longitude
 */
export function toApproximateLocation(lat: number, lng: number): ApproximateLocationResult {
  // Resolution 8 (~0.73 km² neighborhood level)
  const h3IndexRes8: string = latLngToCell(lat, lng, 8)
  const [approxLat8, approxLng8]: [number, number] = cellToLatLng(h3IndexRes8)

  // Resolution 7 (~5.16 km² broader area level) derived from Res 8 parent
  const h3IndexRes7: string = cellToParent(h3IndexRes8, 7)
  const [approxLat7, approxLng7]: [number, number] = cellToLatLng(h3IndexRes7)

  return {
    h3IndexRes8,
    approxLat8,
    approxLng8,
    h3IndexRes7,
    approxLat7,
    approxLng7
  }
}
