# Triage Labels

The skills speak in terms of five canonical triage **state** roles. This file maps those roles to the label strings used in this repo's GitHub Issues.

| Role in skills | Label in this repo | Meaning |
| -------------- | ------------------ | ------- |
| `needs-triage` | `needs-triage` | Maintainer needs to evaluate this issue |
| `needs-info` | `needs-info` | Waiting on reporter for more information |
| `ready-for-agent` | `ready-for-agent` | Fully specified, ready for an AFK agent |
| `ready-for-human` | `ready-for-human` | Requires human implementation |
| `wontfix` | `wontfix` | Will not be actioned |

**Category** roles (one per issue, alongside exactly one state role):

| Role in skills | Typical label | Meaning |
| -------------- | ------------- | ------- |
| `bug` | `bug` | Something isn't working |
| `enhancement` | `enhancement` | New feature or improvement |

When a skill says to apply the AFK-ready triage label, use `ready-for-agent`. Human maintainer triage commands: `docs/engineering/maintainer.md` (恰好一个 state 标签的约定与上表一致).
