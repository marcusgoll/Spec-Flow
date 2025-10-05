# Feature Specification: [FEATURE NAME]

**Branch**: `[###-feature-name]`
**Created**: [DATE]
**Status**: Draft

## User Scenarios

### Primary User Story
[Describe the main user journey in plain language]

### Acceptance Scenarios
1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

### Edge Cases
- What happens when [boundary condition]?
- How does system handle [error scenario]?

## Visual References

See `./visuals/README.md` for UI research and design patterns (if applicable)

## Context Strategy & Signal Design

- **System prompt altitude**: [Describe cue level and rationale]
- **Tool surface**: [Essential tools + why token-efficient]
- **Examples in scope**: [3 canonical examples]
- **Context budget**: [Target tokens + compaction trigger]
- **Retrieval strategy**: [JIT vs. upfront; identifiers]
- **Memory artifacts**: [NOTES.md, TODO.md update cadence]
- **Compaction cadence**: [Summaries every N turns]
- **Sub-agents**: [If used, scope + handoff contract]

## Requirements

### Functional (testable only)

- **FR-001**: System MUST [specific capability]
- **FR-002**: Users MUST be able to [key interaction]
- **FR-003**: System MUST [data requirement]

*Mark ambiguities:*
- **FR-XXX**: [NEEDS CLARIFICATION: specific question]

### Non-Functional

- **NFR-001**: Performance: [specific target with metrics]
- **NFR-002**: Accessibility: [compliance standard]
- **NFR-003**: Mobile: [responsive requirements]
- **NFR-004**: Error Handling: [user experience]

### Key Entities (if data involved)

- **[Entity]**: [Purpose, key attributes, relationships]

---

## Quality Gates *(all must pass before `/plan`)*

- [ ] No implementation details (tech stack, APIs, code)
- [ ] Requirements testable and unambiguous
- [ ] Success criteria measurable
- [ ] Context strategy documented
- [ ] No [NEEDS CLARIFICATION] markers
- [ ] Constitution aligned (performance, UX, data, access)

