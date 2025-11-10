---
name: planning-phase
description: "Standard Operating Procedure for /plan phase. Covers research depth, code reuse detection, design pattern selection, and architecture planning."
allowed-tools: Read, Grep, Glob, Bash
---

# Planning Phase: Quick Reference

> **Purpose**: Generate implementation plan with reuse analysis from spec.md, ensuring alignment with project documentation and maximizing code reuse.

## Phase Overview

**Inputs**:
- `specs/NNN-slug/spec.md` - Feature specification
- `docs/project/*.md` - 8 project documentation files (if available)

**Outputs**:
- `specs/NNN-slug/plan.md` - Implementation plan
- `specs/NNN-slug/research.md` - Research findings and reuse opportunities

**Expected duration**: 1-3 hours

---

## Quick Start Checklist

**Before you begin**:
- [ ] Specification phase completed (`spec.md` exists)
- [ ] Understand feature requirements
- [ ] Project documentation available (or brownfield codebase)

**Core workflow**:
1. ✅ [Load Project Documentation](resources/project-docs-integration.md) - Read all 8 docs for constraints
2. ✅ [Research Code Reuse](resources/code-reuse-analysis.md) - Search before designing
3. ✅ [Design Architecture](resources/architecture-planning.md) - Components, layers, patterns
4. ✅ [Plan Data Model](resources/data-model-planning.md) - Entities, relationships, migrations
5. ✅ [Define API Contracts](resources/api-contracts.md) - Endpoints, schemas, validation
6. ✅ [Plan Testing Strategy](resources/testing-strategy.md) - Unit, integration, E2E coverage
7. ✅ [Estimate Complexity](resources/complexity-estimation.md) - Task count prediction

---

## Detailed Resources

### 🎯 Core Workflow
- **[Project Docs Integration](resources/project-docs-integration.md)** - Load 8 project docs for constraints
- **[Code Reuse Analysis](resources/code-reuse-analysis.md)** - Anti-duplication search patterns
- **[Architecture Planning](resources/architecture-planning.md)** - Component design, layers, patterns

### 📊 Planning Artifacts
- **[Data Model Planning](resources/data-model-planning.md)** - Entity design, ERD, migrations
- **[API Contracts](resources/api-contracts.md)** - OpenAPI specs, endpoint design
- **[Testing Strategy](resources/testing-strategy.md)** - Coverage plan, test types

### 🔧 Estimation & Validation
- **[Complexity Estimation](resources/complexity-estimation.md)** - Task count prediction (20-30 tasks)
- **[Common Mistakes](resources/common-mistakes.md)** - Anti-patterns to avoid

---

## Completion Criteria

**Required**:
- [ ] `plan.md` created with architecture, components, API contracts
- [ ] `research.md` created with reuse findings and project context
- [ ] All 8 project docs read (or brownfield research complete)
- [ ] Code reuse opportunities identified (5-15 expected)
- [ ] Testing strategy defined (unit, integration, E2E)
- [ ] Complexity estimated (20-30 tasks predicted)

**Optional** (if applicable):
- [ ] Data model ERD created (Mermaid diagram)
- [ ] API contracts in OpenAPI format
- [ ] UI/UX flow diagram (for UI features)

---

## Next Phase

After planning complete:
→ `/tasks` - Break down into concrete implementation tasks

---

**See also**:
- [reference.md](reference.md) - Comprehensive planning guide (full text)
- [examples.md](examples.md) - Good vs bad planning examples
