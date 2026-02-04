# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), 
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) 
as far as applicable to research software.

---

## [Unreleased]

### Changed
- Internal refactor to improve clarity and maintainability of the symbolic reduction pipeline

---

## [0.1.2] - 2026-02-04
**GitHub Release:** v0.1.2 | **Paclet Version:** 0.1.1

### Fixed
- Fixed unintended global symbol leakage causing context conflicts in `Needs`
- Corrected paclet packaging to ensure clean namespace isolation

### Notes
- **No changes to the underlying algorithm or mathematical formulation**
- This version supersedes v0.1.1 and v0.1.0 for all practical and scientific use
- Paclet internal version: 0.1.1
- All validation tests produce identical results to previous versions

---

## [0.1.1] - 2026-01-24
**GitHub Release:** v0.1.1 | **Paclet Version:** 0.1.0

### Changed
- Minor metadata adjustments for Zenodo archival and DOI registration

### Notes
- **No functional changes relative to v0.1.0**
- This release exists solely to ensure proper archival and DOI registration via Zenodo
- Paclet internal version remains: 0.1.0 (no regeneration)

---

## [0.1.0] - 2026-01-24
**GitHub Release:** v0.1.0 | **Paclet Version:** 0.1.0

### Added
- **Initial public release**
- Symbolic implementation of the Faddeev–Jackiw reduction using geometrically constrained matrix bordering
- Deterministic Matrix Bordering Technique formulation (theorem-driven, not procedural)
- Iterative constraint propagation with explicit rank diagnostics
- Automatic detection of constraint hierarchies and gauge symmetries via null-space analysis
- Structured, queryable symbolic output via Wolfram `SummaryBox`
- Publication-ready visualization of the inverse symplectic structure via `FJSymplecticFrame`

### Notes
- Establishes the core theoretical and software architecture of the package
- Intended for analytical and research use on finite-dimensional constrained systems
- Accompanies manuscript: *"Faddeev–Jackiw Reduction of Singular Lagrangians: A Matrix Bordering Approach with Symbolic Implementation"*

[0.1.2]: https://github.com/echanlopez/BorderedFJReduction/releases/tag/v0.1.2
[0.1.1]: https://github.com/echanlopez/BorderedFJReduction/releases/tag/v0.1.1
[0.1.0]: https://github.com/echanlopez/BorderedFJReduction/releases/tag/v0.1.0
