# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) documenting key architectural decisions made during the development of the GitHub Governance Terraform module.

## What is an ADR?

An Architecture Decision Record (ADR) is a document that captures an important architectural decision made along with its context and consequences. ADRs help teams understand:

- **Why** certain decisions were made
- **What** alternatives were considered
- **When** the decision was made
- **Who** was involved in the decision
- **What** are the consequences (positive and negative)

## ADR Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](./001-repository-integration-vs-submodule.md) | Repository Integration vs Submodule | ✅ Accepted | 2024-11 |
| [ADR-002](./002-dual-mode-pattern.md) | Dual Mode Pattern (Organization vs Project) | ✅ Accepted | 2024-11 |
| [ADR-003](./003-settings-cascade-priority.md) | Settings Cascade Priority | ✅ Accepted | 2024-11 |

## ADR Template

When creating a new ADR, use the following template:

```markdown
# ADR-XXX: [Title]

**Status:** [Proposed | Accepted | Deprecated | Superseded]
**Date:** YYYY-MM-DD
**Deciders:** [List of people involved]
**Technical Story:** [Link to issue/PR if applicable]

## Context and Problem Statement

[Describe the context and problem statement, e.g., in free form using two to three sentences.]

## Decision Drivers

- [Driver 1]
- [Driver 2]
- [Driver 3]

## Considered Options

- [Option 1]
- [Option 2]
- [Option 3]

## Decision Outcome

Chosen option: "[Option X]", because [justification].

### Positive Consequences

- [Positive consequence 1]
- [Positive consequence 2]

### Negative Consequences

- [Negative consequence 1]
- [Negative consequence 2]

## Pros and Cons of the Options

### [Option 1]

- **Good**, because [argument a]
- **Good**, because [argument b]
- **Bad**, because [argument c]

### [Option 2]

- **Good**, because [argument a]
- **Bad**, because [argument b]
- **Bad**, because [argument c]

## Links

- [Link type] [Link to ADR]
- [Link type] [Link to documentation]
```

## References

- [Documenting Architecture Decisions - Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [ADR GitHub Organization](https://adr.github.io/)
- [Markdown Architectural Decision Records (MADR)](https://adr.github.io/madr/)
