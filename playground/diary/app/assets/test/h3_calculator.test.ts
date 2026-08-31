import { expect, test, describe } from "bun:test"
import { toApproximateLocation, ApproximateLocationResult } from "../js/utils/h3_calculator"

describe("H3 Calculator Utility", () => {
  test("calculates valid Resolution 8 and Resolution 7 H3 indices and coordinates", () => {
    // Tokyo Tower coordinates (35.6586, 139.7454)
    const lat: number = 35.6586
    const lng: number = 139.7454

    const result: ApproximateLocationResult = toApproximateLocation(lat, lng)

    // Verify Resolution 8 properties
    expect(typeof result.h3IndexRes8).toBe("string")
    expect(result.h3IndexRes8.length).toBeGreaterThan(0)
    expect(result.approxLat8).toBeCloseTo(lat, 1)
    expect(result.approxLng8).toBeCloseTo(lng, 1)

    // Verify Resolution 7 properties
    expect(typeof result.h3IndexRes7).toBe("string")
    expect(result.h3IndexRes7.length).toBeGreaterThan(0)
    expect(result.approxLat7).toBeCloseTo(lat, 1)
    expect(result.approxLng7).toBeCloseTo(lng, 1)
  })
})
