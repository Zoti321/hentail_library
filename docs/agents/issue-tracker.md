# Issue tracker

Use GitHub Issues through `gh` inside this clone; infer the repository from its Git remote. PRs review changes and are not the task-request surface. Publishing tickets is an external write and requires task authorization.

## Common operations

```bash
gh issue view <number> --json number,title,body,labels,comments
gh issue list --state open --json number,title,labels
gh issue create --title "..." --body-file <file>
gh issue comment <number> --body-file <file>
gh issue edit <number> --add-label "..." --remove-label "..."
gh issue close <number>
```

Use UTF-8 body files for multiline content. Apply exactly one state and one category from [triage-labels.md](triage-labels.md). Implementation tickets published by a skill use `ready-for-agent` unless the task says otherwise.

Before writing local tickets, check `gh auth status` or `gh issue list -L 1`. Only if GitHub is unreachable after retry, write child implementation tickets under `.scratch/<feature>/issues/<NN>-<slug>.md`, ordered by dependencies. Keep parent specs on GitHub when possible. When access returns, recreate/link the tickets on GitHub; keep scratch files out of commits.

## Parent tickets and dependencies

Use native GitHub sub-issues for parent/child relationships. If unavailable, add a task list to the parent and `Part of #<parent>` to each child. Use native issue dependencies when available:

```bash
gh api repos/<owner>/<repo>/issues/<blocker> --jq .id
gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-database-id>
```

Dependency APIs use numeric database IDs, not issue numbers or node IDs. If unavailable, put `Blocked by: #<number>` at the top of the child; it is ready only after every blocker is closed.

For Wayfinder, use one `wayfinder:map` issue with Notes / Decisions-so-far / Fog and child tickets labelled `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling` or `wayfinder:task`. Select the first open, unassigned child in map order with no open blockers. Claim it with `gh issue edit <number> --add-assignee @me`; on resolution, record the answer, close it and add a concise decision pointer to the map. These writes remain subject to the user's authorized task scope.
