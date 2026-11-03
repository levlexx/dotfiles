---
description: Commit the current changes as conventional commits, split by concern, no AI attribution
argument-hint: "[extra instructions]"
allowed-tools: Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git add *), Bash(git commit *), Bash(git switch *), Bash(git branch *)
disable-model-invocation: true
---

## Current state
!`git status -sb`

!`git diff HEAD --stat`

## Recent history (match its style)
!`git log --oneline -10`

## Task
Commit these changes.

1. On the default branch (`main`/`master`), create a branch first, named
   `<type>/<short-topic>`.
2. Group the changes by concern. Each group becomes one commit; don't mix an
   unrelated fix into a feature commit.
3. Message: `type(scope): subject`. Types: feat, fix, refactor, perf, docs,
   test, build, ci, chore. Subject in lowercase imperative, no trailing period,
   72 characters at most. Add a body only when the *why* isn't obvious.
4. Never add Co-Authored-By, "Generated with" or any other AI attribution.
5. Hooks (commitlint, typos, gitleaks) must pass. Fix what they report;
   never use `--no-verify` unless I ask.
6. Don't push.

Finish with the list of commits you made (`git log --oneline` of the new ones).

$ARGUMENTS
