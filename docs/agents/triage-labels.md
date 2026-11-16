# Triage labels

Each issue has exactly one state label:

- `needs-triage`: awaiting maintainer assessment.
- `needs-info`: awaiting reporter information.
- `ready-for-agent`: specified and ready for agent implementation.
- `ready-for-human`: requires human implementation.
- `wontfix`: will not be implemented.

Add one category label, `bug` or `enhancement`, alongside the state. When a skill requests an AFK-ready label, use `ready-for-agent`. Change state by removing the previous state and adding its replacement; do not accumulate state labels. Tracker operations are documented in [issue-tracker.md](issue-tracker.md).
