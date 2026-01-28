# Release checklist

This checklist must be completed before creating a new release or tag.

---

## Versioning

- [ ] Version number updated in `PacletInfo.wl`
- [ ] Version number matches the intended release tag

---

## Build and installation

- [ ] `PacletBuild["BorderedFJReduction"]` runs without errors
- [ ] Local installation via `PacletInstall` succeeds
- [ ] `Needs["BorderedFJReduction`"]` loads without messages

---

## Code quality

- [ ] All public symbols have `::usage`
- [ ] No temporary or debug code remains
- [ ] Symbolic operations preserve structure and intent

---

## Examples and tests

- [ ] Example notebooks evaluate cleanly
- [ ] Tests (if present) pass successfully

---

## Repository state

- [ ] Working tree is clean (`git status`)
- [ ] Commit history is clear and descriptive
- [ ] No untracked or generated files are included

---

## Release

- [ ] Release tag created
- [ ] `.paclet` file attached to GitHub Release
- [ ] Release notes written