//
//  HumanFatigueEngine.swift
//  MaClicker
//

import Foundation

/// Simulates human fatigue patterns for the auto-clicker.
///
/// Five layers designed to defeat statistical bot-detection:
/// - **Stage multiplier**: piecewise fatigue arc (warmup → steady → onset → exhaustion)
/// - **Random-walk drift**: correlated tempo clusters (nearby clicks stay similar)
/// - **Burst rhythm**: humans click in micro-bursts with brief pauses (bimodal timing)
/// - **Collapse events**: probabilistic micro/macro pauses
/// - **Log-normal jitter**: right-skewed per-click noise matching human reaction-time distributions
final class HumanFatigueEngine {

    let seed: Double

    // Random walk state — creates correlated tempo drift
    private var walkState: Double = 0.0
    private var walkVelocity: Double = 0.0

    // Burst rhythm state — tracks consecutive fast clicks to decide when to gap
    private var consecutiveFast: Int = 0

    init(seed: Double) {
        self.seed = seed
    }

    // MARK: - Stage Multiplier

    /// Returns a speed multiplier based on elapsed session time.
    /// Values > 1.0 mean slower (more delay); < 1.0 mean faster.
    static func stageMultiplier(elapsed: Double) -> Double {
        if elapsed < 30 {
            // Warmup (0–30s): quick ramp-up to peak speed
            let progress = elapsed / 30.0
            return 1.0 - (0.08 * progress)

        } else if elapsed < 180 {
            // Steady (30–180s): near-peak performance, very slow degradation
            let progress = (elapsed - 30.0) / 150.0
            return 0.92 + (progress * 0.18)

        } else if elapsed < 480 {
            // Onset (180–480s): noticeable fatigue creeping in
            let progress = (elapsed - 180.0) / 300.0
            return 1.1 + (progress * 0.5)

        } else {
            // Exhaustion (480s+): plateau with high randomness
            return 1.6 + Double.random(in: -0.15...0.4)
        }
    }

    // MARK: - Random Walk

    /// Advances the random walk one step (called once per click).
    /// Momentum carries 80% so nearby clicks stay correlated — creates the
    /// organic "chunky" tempo drift seen in real human clicking.
    private func stepWalk(elapsed: Double) {
        // Walk bounds grow with fatigue: ±12% when fresh → ±20% when exhausted
        let maxBound = 0.12 + 0.08 * min(elapsed / 600.0, 1.0)
        let maxVel   = 0.05 + 0.03 * min(elapsed / 600.0, 1.0)

        walkVelocity = walkVelocity * 0.80 + Double.random(in: -0.03...0.03)
        walkVelocity = min(maxVel, max(-maxVel, walkVelocity))
        walkState += walkVelocity
        walkState = min(maxBound, max(-maxBound, walkState))
    }

    // MARK: - Noise Multiplier

    /// Combines a slow sine drift (long-term baseline wander) with the correlated
    /// random walk (dominant visible variation). Returns a multiplier ~[0.80, 1.20].
    func noiseMultiplier(elapsed: Double) -> Double {
        stepWalk(elapsed: elapsed)

        // Slow sine drift — barely visible on short runs, adds session uniqueness
        let f = 0.04
        let wave = (
            0.50 * sin(f * 1.0 * elapsed + seed) +
            0.30 * sin(f * 2.6 * elapsed + seed * 1.3 + 1.1) +
            0.20 * sin(f * 5.3 * elapsed + seed * 0.7 + 2.7)
        )
        let driftStrength = 0.02 + 0.04 * min(elapsed / 600.0, 1.0)
        let sineDrift = wave * driftStrength

        // walkState: positive = faster (lower delay), negative = slower
        return 1.0 - walkState + sineDrift
    }

    // MARK: - Burst Rhythm

    /// Applies micro-burst pattern: humans naturally click in bursts of 2-6 fast
    /// clicks with a brief natural pause between bursts. This creates a bimodal
    /// timing distribution that pure jitter-randomisation cannot replicate.
    ///
    /// - Parameter baseDelay: The current core delay before burst modulation.
    /// - Returns: Burst-modulated delay.
    private func applyBurstRhythm(_ baseDelay: Double) -> Double {
        // Gap probability increases the longer the current fast run.
        // Starts at 15% → rises ~7% per consecutive fast click → caps at 60%.
        // Creates variable-length bursts averaging 3-5 clicks.
        let gapChance = min(0.15 + Double(consecutiveFast) * 0.07, 0.60)

        if Double.random(in: 0...1) < gapChance {
            // Inter-burst gap: a natural brief pause
            consecutiveFast = 0
            return baseDelay * Double.random(in: 1.25...1.8)
        } else {
            // Intra-burst: slightly faster than base
            consecutiveFast += 1
            return baseDelay * Double.random(in: 0.82...0.97)
        }
    }

    // MARK: - Collapse Events

    /// Returns an extra pause duration in seconds (0.0 if no event triggered).
    ///
    /// Three event types:
    /// - **Micro collapse**: brief attention lapse (~0.4s), probability rises from 0.1% → 3% over 10 min
    /// - **Macro collapse**: real fatigue wall (1.5–4.5s), only after 3 min, up to 1% chance
    /// - **Rhythm break**: ~2% per click chance of a short rest
    static func collapseDelay(elapsed: Double, clickCount: Int) -> Double {
        // Micro collapse: momentary lapse
        let microProb = min(0.001 + (elapsed / 600.0) * 0.029, 0.03)
        if Double.random(in: 0...1) < microProb {
            return max(0.0, gaussianRandom(mean: 0.4, sd: 0.15))
        }

        // Macro collapse: real fatigue wall (only after 3 minutes)
        if elapsed > 180 {
            let macroProb = min((elapsed - 180.0) / 600.0 * 0.01, 0.01)
            if Double.random(in: 0...1) < macroProb {
                return Double.random(in: 1.5...4.5)
            }
        }

        // Rhythm break: ~2% chance per click of a short rest
        if clickCount > 0 && Double.random(in: 0...1) < 0.02 {
            return Double.random(in: 0.15...0.6)
        }

        return 0.0
    }

    // MARK: - Main Combinator

    /// Computes the next click delay in milliseconds, applying all enabled layers.
    ///
    /// Pipeline: base × stage × noise → burst rhythm → log-normal jitter → collapse
    ///
    /// - Returns: Delay in milliseconds, floored at 40ms.
    func nextDelayMs(
        baseMs: Double,
        elapsed: Double,
        clickCount: Int,
        fatigueEnabled: Bool,
        noiseEnabled: Bool,
        collapseEnabled: Bool
    ) -> Double {
        let stageMult = fatigueEnabled ? Self.stageMultiplier(elapsed: elapsed) : 1.0
        let noiseMult = noiseEnabled   ? noiseMultiplier(elapsed: elapsed)      : 1.0
        let coreDelay = baseMs * stageMult * noiseMult

        // Burst rhythm: creates bimodal distribution (fast intra-burst, slower inter-burst)
        let burstDelay = applyBurstRhythm(coreDelay)

        // Log-normal jitter: right-skewed like human reaction times
        // (occasional long delays, rare very short ones)
        let logJitter = exp(Self.gaussianRandom(mean: 0, sd: 0.06))
        let jitteredDelay = burstDelay * logJitter

        let collapseMs = collapseEnabled
            ? Self.collapseDelay(elapsed: elapsed, clickCount: clickCount) * 1000.0
            : 0.0

        return max(40.0, jitteredDelay + collapseMs)
    }

    // MARK: - Gaussian Random (Box-Muller Transform)

    static func gaussianRandom(mean: Double, sd: Double) -> Double {
        let u1 = Double.random(in: Double.leastNormalMagnitude...1)
        let u2 = Double.random(in: 0...1)
        let z  = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        return mean + sd * z
    }
}
