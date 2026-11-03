# Global instructions

Personal setup lives in ~/dotfiles and is synced across two Macs; change
tools and config there, not in place.

## Git
- Conventional commits (`feat(scope): …`, `fix(scope): …`); commitlint and a
  typos pre-commit hook enforce them globally.
- Never add Co-Authored-By, "Generated with" or any other AI attribution to
  commits or PR bodies.
- Branch before committing on the default branch.

## Tooling
- Runtimes and CLIs come from mise (`~/.config/mise/config.toml`) or the
  Brewfile. Prefer ubi/aqua release binaries over npm packages that need a
  postinstall download (they break on the second Mac).
- Available and preferred: `rg`, `fd`, `ast-grep` (structural search and
  rewrite), `difft`, `jq`, `gh`, `task`.

## Stack
Go, Angular/Nx (TypeScript), Kubernetes (k3d locally), Cloud Run.

## Compact instructions
When compacting, keep: the user's goal and constraints for this session,
decisions made and why, files changed (paths), commands that verified the
work and their results, open problems and the next step. Drop: full file
contents, long command output, superseded attempts.
