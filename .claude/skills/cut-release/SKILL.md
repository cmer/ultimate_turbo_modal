---
name: cut-release
description: Prep a new release of ultimate_turbo_modal by bumping the VERSION file, updating CHANGELOG.md, and committing. Stops short of publishing — the user runs ./script/build_and_release.sh themselves because it prompts for 2FA. Use when the user asks to "cut a release", "release vX.Y.Z", "prep a release", or "bump the version".
---

# Cut Release

Prep work for a new gem + npm release. Does **not** publish — the user runs `./script/build_and_release.sh` themselves because that script prompts for 2FA codes interactively.

## What this skill does

1. Determines target version (asks user if not provided as argument)
2. Updates the `VERSION` file at the repo root
3. Updates `CHANGELOG.md`:
   - Renames the `## [Unreleased]` section to `## [X.Y.Z] - YYYY-MM-DD`
   - Adds bullets for any commits since the last tag that aren't already represented in the Unreleased section
   - Adds a fresh empty `## [Unreleased]` section at the top
4. Updates `demo-app/package-lock.json` to point at the new version of the linked `../javascript` package
5. Commits the three changes with a message like `Bump version to X.Y.Z`
6. Tells the user to run `./script/build_and_release.sh` themselves

## Steps

### 1. Determine version

If the user passed a version as an argument, use it. Otherwise read the current version and ask:

```bash
cat VERSION
```

Ask the user: "Current version is X.Y.Z. What version should I bump to?" Wait for an answer before proceeding. Do not guess.

### 2. Gather changelog material

```bash
git tag --sort=-v:refname | head -5         # find the latest release tag
git log <last-tag>..HEAD --oneline           # commits since that tag
```

Read `CHANGELOG.md` to see what's already in the `## [Unreleased]` section. For any commit since the last tag that isn't reflected there, add a one-line bullet describing the user-facing change (not the implementation). Skip purely internal commits (lockfile bumps, doc-only README tweaks, CI changes) unless they're meaningful to consumers.

### 3. Update files

- Replace contents of `VERSION` with the new version (no trailing newline beyond what the file already has — match the existing format).
- In `CHANGELOG.md`:
  - Change `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` using today's date.
  - Insert a new empty `## [Unreleased]` section at the very top (before the renamed section), so future changes have a place to go.
- In `demo-app/package-lock.json`, bump the version of the `ultimate_turbo_modal` package — the entry keyed `"../javascript"` near the top of `"packages"`, identifiable by `"name": "ultimate_turbo_modal"`. Update only its `"version"` field to the new version, e.g.:

  ```json
  "../javascript": {
    "name": "ultimate_turbo_modal",
    "version": "X.Y.Z",
    ...
  }
  ```

  Do not touch any other `"version"` field in the file (transitive dependencies live under `node_modules/*` and have unrelated versions). This keeps the lockfile in sync so the demo app doesn't show a phantom diff after `npm install`.

### 4. Commit

Stage `VERSION`, `CHANGELOG.md`, and `demo-app/package-lock.json`. Do not stage anything else. Use a commit message in the style of recent release commits — check `git log --oneline -20` for the convention. A short message like `Bump version to X.Y.Z` is fine.

Do NOT push. Do NOT tag (the release script does that via `bundle exec rake release`).

### 5. Hand off to the user

Tell the user clearly:

> Version bumped and committed. Run `./script/build_and_release.sh` yourself to publish — it prompts for 2FA codes for both RubyGems and npm, so it can't be automated.

## Things to NOT do

- Do not run `./script/build_and_release.sh`
- Do not run `gem push`, `npm publish`, or `git tag`
- Do not push the commit
- Do not modify `javascript/package.json` version (the release script syncs it from `VERSION`)
- Do not run `npm install` to update the lockfile — edit the `version` field directly to keep the diff minimal
