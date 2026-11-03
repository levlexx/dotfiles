---
description: Push the current branch and open a GitHub PR with a reviewer-friendly description
argument-hint: "[base branch] [extra instructions]"
allowed-tools: Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git push *), Bash(git branch *), Bash(gh pr *), Bash(gh repo view *)
disable-model-invocation: true
---

## Branch
!`git branch --show-current`

## Commits not on the default branch
!`git log --oneline origin/HEAD..HEAD`

## Changed files
!`git diff origin/HEAD...HEAD --stat`

## Task
Open a pull request for this branch.

1. Refuse if the working tree is dirty or the branch is the default branch;
   tell me what to do instead.
2. Push with `git push -u origin HEAD`.
3. Title: one conventional-commit line covering the whole branch.
4. Body, short and concrete:
   - **What**: two to four bullets on the user-visible change.
   - **Why**: the problem it solves.
   - **How to test**: commands or steps.
   - **Risks**: migrations, config changes, anything to watch on deploy.
5. No AI attribution anywhere in the title or body.
6. `gh pr create --base <base> --title ... --body ...`; base is the first
   argument if given, otherwise the repo's default branch. Open as draft if
   any commit message says WIP.

Reply with the PR URL.

$ARGUMENTS
