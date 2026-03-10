---
name: code-change-guard
description: Mandatory process for any code changes in this repo, including requirement clarification, SOLID/DI and layer separation, view simplicity, tests, documentation updates, previews, and unit-test execution. Use when adding features, fixing bugs, refactoring, or otherwise modifying code or Views.
---

# Code Change Guard

## Before Changes

- If the task is underspecified, ask clarifying questions before editing code.
- Document changes in `/Users/ozavhorodianskyi/Documents/xCode/WIMM_2/CONTEXT_HANDOFF_2026-03-06.md` after code changes.

## During Changes

- Follow SOLID principles.
- Use dependency injection (DI) for collaborators and services.
- Maximize separation between layers to improve testability.
- Keep Views simple and small.

## After Changes

- Document the changes in `/Users/ozavhorodianskyi/Documents/xCode/WIMM_2/CONTEXT_HANDOFF_2026-03-06.md`.
- Update existing unit tests for changed code when tests are needed.
- Add new unit tests for new modules or classes when tests are needed.
- Run unit tests under the dedicated unit-test scheme `WIMM-UnitTests` and confirm they pass.
- Explain what was changed and why.
- Add or update previews for every changed View.

## Prohibited

- Do not modify non-View code without updating unit tests when tests are needed.
- Do not leave a changed View without a preview.
