# ADR-0054: Require verified continuity for automatic Path migration

## Status

Accepted. Supersedes ADR-0013's weak-fingerprint eligibility for Library sync.

## Context

Equal resource type, size and page count can describe unrelated works. Even a unique candidate can transfer metadata, locks, history, Finished marks, covers and Series references incorrectly.

## Decision

Library sync never automatically rekeys a removed/added pair based only on weak fingerprints. Such pairs follow ordinary orphan removal and new import. Consequently automatic rename preservation is reduced; old user state is not guaranteed to survive an unverified rename.

Location identity (ADR-0001) and explicit readable Local root relative-path remapping remain unchanged. Folder series inference requires eligible Comic migrations and retains whole-membership, common-parent and destination-conflict checks; weak candidates provide no eligible migrations.

Eligible explicit rekeys retain transaction-time metadata merges and atomic reference preservation. Stronger rename evidence requires a separate decision; no hash store or confirmation UI is introduced.

## Consequences

Unrelated Resources cannot inherit user state through fingerprint coincidence. Users should use explicit root updates for supported root moves. Ordinary renames can lose continuity on reconciliation.
