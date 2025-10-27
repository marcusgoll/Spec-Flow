# Development Workflow

**Last Updated**: [DATE]
**Team Size**: [Number of developers]
**Related Docs**: See `deployment-strategy.md` for CI/CD, `tech-stack.md` for tools

## Team Structure

**Current Team**:
- [Role 1]: [Name] - [Responsibilities]
- [Role 2]: [Name] - [Responsibilities]

**Example**:
**Current Team**:
- Product/Eng: Marcus - Full-stack development, product decisions, DevOps
- Domain Advisor: John (CFI) - Domain expertise, user testing, ACS validation

**As Team Grows** (future):
- Frontend Engineer
- Backend Engineer
- Product Manager
- Designer

---

## Git Workflow

**Strategy**: [Git Flow | GitHub Flow | Trunk-Based]
**Main Branches**: [List branches]

**Example**:
**Strategy**: GitHub Flow (simplified, works for small teams)

**Branches**:
- `main` - Production code (always deployable)
- `staging` - Staging environment (pre-production)
- `feature/[name]` - Feature branches (short-lived)

**Flow**:
```
main (production)
  ↑
staging (pre-production)
  ↑
feature/add-student-dashboard (active work)
```

### Branch Naming

**Format**: `[type]/[ticket-id]-[short-description]`

**Types**:
- `feature/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation
- `chore/` - Maintenance, dependencies

**Examples**:
- `feature/001-student-progress-dashboard`
- `fix/gh-42-login-redirect-loop`
- `refactor/api-error-handling`
- `docs/update-api-docs`
- `chore/upgrade-nextjs-14`

### Creating a Feature Branch

```bash
# Start from latest main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/001-student-dashboard

# Work on feature (commit frequently)
git add .
git commit -m "feat: add student progress component"

# Push to remote
git push -u origin feature/001-student-dashboard

# Create PR on GitHub
gh pr create --base staging --title "Add student progress dashboard"
```

---

## Pull Request Process

### Creating a PR

**Required Information**:
- **Title**: Clear, concise (e.g., "Add student progress dashboard")
- **Description**: What changed, why, how to test
- **Linked Issues**: Reference GitHub issue (e.g., "Closes #42")
- **Screenshots**: For UI changes

**PR Template** (`.github/pull_request_template.md`):
```markdown
## Summary
[Brief description of changes]

## Changes
- [Change 1]
- [Change 2]

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if UI change)
[Add screenshots]

## Checklist
- [ ] Code follows style guide
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] No sensitive data in code

Closes #[issue number]
```

### Code Review Requirements

**Minimum Reviews**: [Number]
**Who Can Approve**: [Team members]
**Required Checks**: [CI steps that must pass]

**Example**:
**Minimum Reviews**: 1 approval required
**Who Can Approve**: Any team member (or self-approve for solo dev)
**Required Checks**:
- ✅ Lint (ESLint, Ruff)
- ✅ Type check (TypeScript, Pyright)
- ✅ Unit tests (Jest, pytest)
- ✅ Build succeeds

**Review Focus**:
- **Correctness**: Does it work? Does it meet requirements?
- **Security**: Any vulnerabilities? Input validation?
- **Performance**: Any slow queries? Unnecessary re-renders?
- **Maintainability**: Clear code? Comments where needed?
- **Testing**: Adequate test coverage?

**Review Turnaround**: < 24 hours (or same day for small PRs)

### Approval & Merge

**Merge Strategy**: [Squash | Merge commit | Rebase]

**Example**:
**Merge Strategy**: Squash and merge (keeps main branch clean)

**Process**:
1. PR created
2. CI runs checks (auto)
3. Code review (1 approval)
4. Address feedback (if any)
5. Approval received
6. **Squash and merge** to `staging`
7. Auto-deploy to staging
8. Manual validation in staging
9. If good: PR `staging` → `main`
10. Manual approval gate
11. Deploy to production

**Merge Commit Message**:
```
feat: add student progress dashboard (#42)

- Displays ACS-mapped progress chart
- Shows weak areas requiring practice
- Lighthouse performance: 92

Closes #42
```

---

## Commit Conventions

**Format**: [Conventional Commits](https://www.conventionalcommits.org/)

**Structure**: `<type>(<scope>): <subject>`

**Types**:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Formatting, no code change
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance

**Examples**:
```
feat(students): add progress chart component
fix(api): resolve login redirect loop
docs(readme): update installation instructions
refactor(utils): extract date formatting to utility
test(students): add unit tests for progress calculation
chore(deps): upgrade Next.js to 14.2.0
```

**Why**: Enables automatic changelog generation, semantic versioning

---

## Development Environment Setup

**Prerequisites**:
- Node.js 20+
- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- Docker (optional, for DB)

**First-Time Setup**:
```bash
# 1. Clone repo
git clone https://github.com/[org]/[repo].git
cd [repo]

# 2. Install dependencies
# Frontend
cd apps/web
pnpm install

# Backend
cd ../../api
uv sync  # or pip install -r requirements.txt

# 3. Setup databases (Docker)
docker-compose up -d postgres redis

# 4. Run migrations
cd api
uv run alembic upgrade head

# 5. Seed data (optional)
uv run python scripts/seed_dev_data.py

# 6. Copy environment variables
cp .env.example .env.local
# Edit .env.local with your secrets

# 7. Start dev servers
# Terminal 1: Frontend
cd apps/web
pnpm dev  # http://localhost:3000

# Terminal 2: Backend
cd api
uv run uvicorn main:app --reload  # http://localhost:8000
```

**Onboarding Time**: ~30 minutes for first-time setup

---

## Code Style Guidelines

### Frontend (TypeScript/React)

**Linting**: ESLint with Next.js config
**Formatting**: Prettier (auto-format on save)

**Key Rules**:
- Use functional components (not class components)
- Use TypeScript (no `any` types)
- Use `const` over `let` (immutability)
- Extract complex logic to custom hooks
- Use semantic HTML (`<button>` not `<div onClick>`)

**Component Structure**:
```typescript
// Good
export function StudentCard({ student }: { student: Student }) {
  const { data, error } = useSWR(`/api/students/${student.id}`)

  if (error) return <ErrorState />
  if (!data) return <LoadingState />

  return (
    <Card>
      <h2>{student.name}</h2>
      <ProgressChart data={data.progress} />
    </Card>
  )
}
```

**File Naming**:
- Components: `StudentCard.tsx` (PascalCase)
- Utilities: `formatDate.ts` (camelCase)
- Types: `student.types.ts`
- Tests: `StudentCard.test.tsx`

### Backend (Python/FastAPI)

**Linting**: Ruff (replaces Pylint, Flake8, isort)
**Formatting**: Black (auto-format)
**Type Checking**: Pyright

**Key Rules**:
- Use type hints for all function signatures
- Use Pydantic models for request/response
- Follow PEP 8 (automated by Black)
- Extract business logic to services (not in route handlers)
- Use async/await for I/O operations

**Module Structure**:
```python
# Good
from fastapi import APIRouter, Depends
from app.services.student_service import StudentService
from app.schemas.student import StudentCreate, StudentResponse

router = APIRouter()

@router.post("/students", response_model=StudentResponse)
async def create_student(
    data: StudentCreate,
    service: StudentService = Depends(),
) -> StudentResponse:
    """Create new student."""
    return await service.create_student(data)
```

**File Naming**:
- Modules: `student_service.py` (snake_case)
- Classes: `StudentService` (PascalCase)
- Functions: `create_student` (snake_case)
- Tests: `test_student_service.py`

---

## Testing Strategy

**Test Pyramid**:
```
        /\
       /  \  E2E Tests (10%)
      /____\
     /      \  Integration Tests (30%)
    /________\
   /          \  Unit Tests (60%)
  /______________\
```

### Unit Tests

**What to Test**: Business logic, utilities, pure functions

**Tools**:
- Frontend: Jest + React Testing Library
- Backend: pytest

**Coverage Target**: 80% line coverage

**Example**:
```typescript
// Frontend
describe('calculateProficiency', () => {
  it('returns 0.0 for no lessons', () => {
    expect(calculateProficiency([])).toBe(0.0)
  })

  it('calculates average proficiency', () => {
    const lessons = [
      { proficiency: 0.6 },
      { proficiency: 0.8 },
    ]
    expect(calculateProficiency(lessons)).toBe(0.7)
  })
})
```

```python
# Backend
def test_create_student_success(db_session):
    service = StudentService(db_session)
    data = StudentCreate(name="John Doe", email="john@example.com")

    student = await service.create_student(data)

    assert student.id is not None
    assert student.name == "John Doe"
```

### Integration Tests

**What to Test**: API endpoints (request → response), database interactions

**Tools**:
- Backend: pytest with TestClient
- Database: Test database (isolated per test)

**Example**:
```python
def test_create_student_endpoint(client, db_session):
    response = client.post("/api/v1/students", json={
        "name": "John Doe",
        "email": "john@example.com",
        "certificate_type": "private"
    })

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "John Doe"
    assert "id" in data
```

### E2E Tests

**What to Test**: Critical user flows (login, create student, log lesson)

**Tool**: Playwright

**Example**:
```typescript
test('instructor can create new student', async ({ page }) => {
  await page.goto('http://localhost:3000/login')
  await page.fill('[name="email"]', 'cfi@example.com')
  await page.fill('[name="password"]', 'password')
  await page.click('button[type="submit"]')

  await page.click('text=Add Student')
  await page.fill('[name="name"]', 'Test Student')
  await page.fill('[name="email"]', 'student@example.com')
  await page.selectOption('[name="certificate_type"]', 'private')
  await page.click('button:has-text("Create")')

  await expect(page.locator('text=Test Student')).toBeVisible()
})
```

**When to Run**:
- Locally: Before creating PR
- CI: On every PR
- Pre-deployment: Before staging/production deploy

---

## Definition of Done

**Checklist before marking task complete**:

- [ ] **Code Complete**
  - [ ] Feature implemented per spec
  - [ ] Edge cases handled
  - [ ] Error handling implemented

- [ ] **Tests**
  - [ ] Unit tests added (80% coverage)
  - [ ] Integration tests added (if API changes)
  - [ ] E2E test added (if critical flow)
  - [ ] All tests pass locally

- [ ] **Code Quality**
  - [ ] Linter passes (no warnings)
  - [ ] Type checker passes (no errors)
  - [ ] No console.log or debug code
  - [ ] Code reviewed (if team > 1)

- [ ] **Documentation**
  - [ ] Code comments for complex logic
  - [ ] API docs updated (if API changes)
  - [ ] README updated (if setup changes)
  - [ ] CHANGELOG updated

- [ ] **Deployment**
  - [ ] Environment variables documented (if new)
  - [ ] Database migration created (if schema change)
  - [ ] Tested in staging
  - [ ] Rollback plan documented (if risky change)

**Only merge PR when all boxes checked**

---

## Issue Tracking

**Tool**: [GitHub Issues | Jira | Linear]
**Board**: [Kanban | Scrum]

**Example**:
**Tool**: GitHub Issues + Projects
**Board**: Kanban (Backlog → In Progress → Review → Done)

**Issue Labels**:
- `type:feature` - New feature
- `type:bug` - Bug fix
- `type:enhancement` - Improvement to existing feature
- `type:chore` - Maintenance work
- `priority:high` - Urgent
- `priority:medium` - Normal
- `priority:low` - Nice-to-have
- `size:small` - < 4 hours
- `size:medium` - 4-8 hours
- `size:large` - > 8 hours

**Issue Template**:
```markdown
## Description
[What needs to be done]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Technical Notes
[Any technical details]

## Related
- Spec: specs/001-student-dashboard/spec.md
- Design: Figma link (if applicable)
```

---

## Release Process

**Cadence**: [How often]
**Versioning**: [Semantic versioning]

**Example**:
**Cadence**: Weekly releases (every Tuesday)
**Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)

**Release Workflow**:
1. Cut release branch: `release/v1.2.0` from `staging`
2. Update version in `package.json`
3. Generate changelog from commits
4. Create release PR: `release/v1.2.0` → `main`
5. Review and approve
6. Merge to `main` (triggers production deploy)
7. Tag commit: `git tag v1.2.0`
8. Create GitHub release with changelog

**Hotfix Process** (for critical bugs in production):
1. Branch from `main`: `hotfix/critical-login-bug`
2. Fix bug
3. PR to `main` (fast-track, skip staging)
4. Deploy immediately
5. Bump PATCH version (1.2.0 → 1.2.1)
6. Backport to `staging`

---

## Communication

**Daily Standups** (if team > 1):
- When: Daily, 10am EST (async in Slack for remote)
- Format: What did yesterday, what doing today, blockers

**Weekly Planning** (if using sprints):
- When: Mondays, 2pm EST
- What: Review roadmap, prioritize tasks, assign work

**Retrospectives**:
- When: Every 2 weeks
- What: What went well, what to improve, action items

**Tools**:
- Slack: Real-time chat (#general, #dev, #deploys)
- GitHub Discussions: Async technical discussions
- Loom: Screen recordings for complex explanations

---

## Onboarding New Developers

**Checklist for new team members**:

**Day 1**:
- [ ] Access to GitHub repo
- [ ] Access to staging/production environments (read-only)
- [ ] Access to Slack workspace
- [ ] Read `README.md`, `CONTRIBUTING.md`, `docs/architecture.md`
- [ ] Setup local development environment
- [ ] Run app locally

**Week 1**:
- [ ] Pair with team member on small task
- [ ] Read project docs: `docs/project/`
- [ ] Understand deployment workflow
- [ ] Make first PR (small fix or docs improvement)

**Month 1**:
- [ ] Ship first feature to production
- [ ] Understand full stack (frontend + backend + DB)
- [ ] Participate in code reviews

**Buddy System**: Assign experienced developer as mentor for first month

---

## Tools & Subscriptions

**Development**:
- GitHub (version control, CI/CD)
- VS Code / Cursor (IDE)
- Postman (API testing)
- Docker Desktop (local DB)

**Monitoring**:
- PostHog (analytics, feature flags)
- Railway logs (backend logs)
- Vercel analytics (frontend performance)

**Communication**:
- Slack (team chat)
- Loom (screen recordings)

**Design** (if applicable):
- Figma (UI design)

**Cost**: ~$100/mo (for tools, separate from infrastructure)

---

## Best Practices

### Code Reviews

**As Reviewer**:
- Review within 24 hours
- Be constructive (suggest improvements, don't just criticize)
- Approve if minor issues (can fix in follow-up)
- Block if critical issues (security, major bugs)

**As Author**:
- Keep PRs small (< 500 lines)
- Provide context in description
- Respond to feedback promptly
- Don't take feedback personally

### Debugging

**Process**:
1. Reproduce the bug locally
2. Write failing test that captures the bug
3. Fix the bug
4. Verify test now passes
5. Add to PR

**Tools**:
- Browser DevTools (frontend debugging)
- Python debugger (pdb, VS Code debugger)
- Database query logs (slow queries)

### Performance

**Monitor**:
- Bundle size (keep < 200KB)
- API response time (p95 < 500ms)
- Database query time (< 100ms)
- Lighthouse score (≥ 85)

**Optimize**:
- Lazy load components
- Cache API responses
- Add database indexes
- Compress images

---

## Change Log

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| [DATE] | [What] | [Why] | [Effect] |

**Example**:

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| 2025-10-15 | Switched from npm to pnpm | 3x faster installs | Faster CI, less disk space |
| 2025-10-01 | Added Ruff linter | Replaces 5 tools (Pylint, Flake8, isort, etc.) | Simpler config, faster linting |
| 2025-09-20 | Adopted Conventional Commits | Enables automatic changelog | Better release notes |
