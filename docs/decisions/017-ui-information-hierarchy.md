# ADR-017: UI information hierarchy

Status: Accepted

## Decision

The first BOTAI UI direction uses four primary tabs: Today, Library, Progress and Profile. Friends/challenges remain contextual in v1.

Today prioritizes the next learning action over analytics. The screen separates long-term Goal pace, streak, adaptive BOTAI plan and habit minimum. Progress owns week/month/long-term comparisons and deeper statistics.

The visual storyboard is a design direction, not a pixel-perfect implementation contract. SwiftUI components must preserve the information hierarchy and accessibility rules even when visual details change.

## Readiness metric

Do not ship an arbitrary `readiness %`. A readiness score may be introduced only after the product defines its inputs, calibration, uncertainty and user-facing meaning. Until then use evidence-backed pace and progress descriptions.
