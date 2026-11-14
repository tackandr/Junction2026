# Repository Guidelines

## Project Structure & Documents

This repository currently contains planning documents rather than application source code. `docs/ideas.md` is a structured worksheet for brainstorming, grouping, and evaluating ideas. `docs/adr/adr-template.md` is the template for recording architecture or project decisions. Keep new documentation in `docs/`, and put each decision record in `docs/adr/` so related material stays easy to find.

## Editing and Style

Write in Markdown with descriptive headings, short paragraphs, and actionable prompts. Match the existing templates: use checklists for work to be completed, tables for comparisons, and metadata near the top when it helps readers understand status, date, or ownership. Use clear filenames; name decision records with a zero-padded number and a short topic, for example `adr-0001-record-format.md`. Preserve the template's decision status vocabulary and update its change history when revising an ADR.

## Build, Test, and Validation

There is no configured build system, automated test suite, or formatter in the repository. For documentation-only changes, review the rendered Markdown and check links, heading hierarchy, spelling, and completed placeholders before submitting. If executable code or tooling is added later, document its setup and validation commands here.

## Commits and Pull Requests

The available Git history contains only the initial commit (`init docs`), so no established commit convention can be inferred. Use a short, imperative subject that describes the change, such as `Add ADR for decision tracking`. In pull requests, explain the purpose and scope, link related issues or ADRs, and include screenshots only when they clarify a rendered-document change. Keep unrelated document changes in separate commits where practical.

## Decision Records

Create ADRs from `docs/adr/adr-template.md`. Give each a unique sequential number, state the decision and its context, record trade-offs and validation criteria, and link related documents or issues. Update an ADR's status when the decision changes; create a superseding ADR when a new decision replaces it rather than silently rewriting the original rationale.
