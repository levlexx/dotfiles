---
description: Draw or refresh an architecture diagram of this repo from the code (D2, rendered to SVG in docs/diagrams)
argument-hint: "[what to draw: overview | request <route> | deploy | c4 | db <dsn> | deps] [extra instructions]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(diag *), Bash(d2 *), Bash(git ls-files *), Bash(go list *), Bash(ls *)
---

## Request
$ARGUMENTS

## Existing diagrams
!`ls docs/diagrams 2>/dev/null || echo "(none yet)"`

## Repo layout
!`git ls-files | grep -vE '(^|/)(node_modules|vendor|dist|\.nx|\.angular)/' | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -40`

## How to work

Draw what the code actually does, not a generic picture. Read before
drawing: entry points (`main.go`, `cmd/*`, Angular `app.routes.ts`,
`main.ts`), HTTP routes and handlers, clients for other services, DB
access and migrations, queues/topics, and deploy config (Dockerfile,
`cloudbuild.yaml`, `.github/workflows`, Cloud Run/k8s manifests, Tiltfile,
DO app spec).

What to produce, by request:
- overview (default): components and how they talk; one box per deployable
  or major package, edges labelled with the protocol or the call
- `request <route>`: a sequence diagram (`shape: sequence_diagram`) of that
  route from the handler down to storage and back, including auth, external
  calls and events
- `deploy`: where each part runs and how code gets there (CI, registry,
  Cloud Run/DO/k8s, secrets, databases)
- `c4`: C4 container view: system boundary, containers labelled
  "Name\n[tech]", people and external systems
- `db <dsn>`: run `diag db <dsn>` (tbls) and summarize the schema
- `deps`: run `diag deps` and point out layering problems (cycles, handlers
  importing storage directly, etc.)

D2 rules:
- start from a template when one fits: `diag new <name> <service|sequence|c4|deploy>`
  then edit the file; keep one diagram per concern, at most ~20 nodes
- quote labels with special characters (`"API [Go]"`), use `\n` for a
  second line, `shape: cylinder` for stores, `shape: queue` for topics,
  `shape: person` for users; containers (`api: { ... }`) for boundaries
- no tooltips or links: they do not survive as a static SVG on GitHub
- if updating an existing diagram, edit it in place and keep names stable

Then render with `diag render docs/diagrams/<name>.d2` and fix every
compile error. Finish with: the file paths, a 3-5 line summary of what the
diagram shows, anything you could not determine from the code, and a
markdown snippet to embed it (`![<name>](docs/diagrams/<name>.svg)`).
