# Technology Stack

**Last Updated**: 2025-10-24
**Project**: FlightPro (MVP)
**Team Size**: Solo developer

---

## Stack Overview

| Layer | Technology | Version | Purpose | Rationale |
|-------|-----------|---------|---------|-----------|
| **Frontend** | Next.js | 14.2.x | Server-rendered React UI | Solo dev productivity, Vercel deploy |
| **UI Framework** | Tailwind CSS | 3.4.x | Utility-first CSS | Fast prototyping, low CSS overhead |
| **State Management** | SWR | 2.2.x | Data fetching, caching | Simple, works great with Next.js |
| **Backend** | FastAPI | 0.110.x | Python async API | Fast async, auto OpenAPI docs |
| **Database** | PostgreSQL | 15.x | Relational data storage | ACID compliance, mature ecosystem |
| **ORM** | SQLAlchemy | 2.0.x | Database abstraction | Industry standard, type-safe |
| **Migrations** | Alembic | 1.13.x | Schema versioning | Standard with SQLAlchemy |
| **Auth** | Clerk | Latest | User authentication | Fastest setup, free tier, Next.js SDK |
| **Deployment (FE)** | Vercel | - | Frontend hosting | Free tier, auto-deploy, edge network |
| **Deployment (BE)** | Railway | - | Backend API hosting | $5/mo Starter, Postgres included |
| **CI/CD** | GitHub Actions | - | Automated testing, deploy | Free for public repos, easy setup |
| **Monitoring** | Vercel Analytics | - | Frontend performance | Built-in, free tier |
| **Error Tracking** | (Planned) | - | Error monitoring | Sentry or PostHog (TBD) |

---

## Frontend Stack

### Next.js 14.2.x (App Router)

**Why Next.js?**

- **Solo dev productivity**: File-based routing, built-in API routes, server components
- **Performance**: SSR + ISR for fast page loads, critical for UX
- **Deployment**: One-click Vercel deploy, zero config
- **Type safety**: Works seamlessly with TypeScript
- **Ecosystem**: Huge community, well-documented

**Alternatives rejected**:

- **Create React App (CRA)**: No SSR, deprecated by React team
- **Vite + React**: Requires custom SSR setup, more boilerplate
- **SvelteKit**: Smaller ecosystem, less familiar to potential contributors
- **Remix**: Similar to Next.js but smaller community

**Configuration**:

```json
// package.json (key dependencies)
{
  "dependencies": {
    "next": "14.2.3",
    "react": "18.3.0",
    "react-dom": "18.3.0"
  }
}
```

---

### Tailwind CSS 3.4.x

**Why Tailwind?**

- **Fast prototyping**: No need to write custom CSS for MVP
- **Consistency**: Design system built-in (spacing, colors, typography)
- **Performance**: Purges unused CSS, small bundle size
- **Responsive**: Mobile-first by default
- **Maintenance**: No CSS files to manage, all styles in JSX

**Alternatives rejected**:

- **CSS Modules**: More verbose, slower for MVP
- **Styled-components**: Heavier bundle, runtime overhead
- **Bootstrap**: Too opinionated, harder to customize
- **Custom CSS**: Slower, error-prone, hard to maintain

**Configuration**:

```js
// tailwind.config.js
module.exports = {
  content: ['./app/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: '#0070f3',
        secondary: '#ff6b6b',
      },
    },
  },
}
```

---

### SWR 2.2.x (State Management)

**Why SWR?**

- **Simple API**: `const { data, error } = useSWR('/api/students', fetcher)`
- **Built-in caching**: No need for Redux or Zustand
- **Automatic revalidation**: Refetch on focus, reconnect, interval
- **Optimistic updates**: Fast UI for mutations
- **Next.js integration**: Made by Vercel, perfect fit

**Alternatives rejected**:

- **Redux Toolkit**: Overkill for MVP, too much boilerplate
- **Zustand**: Good for global state, but SWR handles data fetching better
- **TanStack Query (React Query)**: Similar to SWR, but SWR is lighter
- **Native fetch**: No caching, no revalidation, manual loading states

**Example usage**:

```typescript
// app/components/StudentList.tsx
import useSWR from 'swr'

export function StudentList() {
  const { data, error, isLoading } = useSWR('/api/v1/students', fetcher)

  if (isLoading) return <Loading />
  if (error) return <Error message={error.message} />

  return (
    <ul>
      {data.students.map(student => (
        <StudentCard key={student.id} student={student} />
      ))}
    </ul>
  )
}
```

---

## Backend Stack

### FastAPI 0.110.x

**Why FastAPI?**

- **Async by default**: Fast I/O for database queries, external APIs
- **Auto-generated docs**: OpenAPI (Swagger) UI at `/docs` for free
- **Type hints**: Pydantic models enforce validation
- **Python**: Easy to write business logic (ACS scoring, progress calc)
- **Modern**: WebSockets, GraphQL support if needed later

**Alternatives rejected**:

- **Django**: Too heavyweight, more setup, slower for simple APIs
- **Flask**: No built-in async, less structure, manual validation
- **Node.js (Express)**: Would require TypeScript, less familiar to domain experts
- **Go**: Faster but longer dev time, harder to find contributors

**Configuration**:

```python
# requirements.txt (key dependencies)
fastapi==0.110.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.27
alembic==1.13.1
psycopg2-binary==2.9.9  # PostgreSQL driver
pydantic==2.6.1
```

**Project structure**:

```
api/
├── main.py             # FastAPI app entry
├── models/             # SQLAlchemy models
│   ├── user.py
│   ├── student.py
│   └── lesson.py
├── schemas/            # Pydantic schemas (request/response)
│   ├── student.py
│   └── lesson.py
├── routes/             # API endpoints
│   ├── students.py     # /api/v1/students
│   └── lessons.py      # /api/v1/lessons
├── services/           # Business logic
│   ├── student_service.py
│   └── progress_calculator.py
└── alembic/            # Database migrations
    └── versions/
```

---

### PostgreSQL 15.x + SQLAlchemy 2.0.x

**Why PostgreSQL?**

- **Relational data**: Student-Lesson-Progress relationships fit relational model
- **ACID compliance**: Critical for FAA-compliant records (no data loss)
- **Mature ecosystem**: ORMs, tools, hosting all support it
- **Performance**: Handles 100-1K users easily on Railway Starter plan
- **JSON support**: Can store flexible ACS task data as JSONB if needed

**Why SQLAlchemy?**

- **Industry standard**: Most widely used Python ORM
- **Type safety**: Works with Pydantic for end-to-end typing
- **Async support**: SQLAlchemy 2.0 has native async queries
- **Migration tool**: Alembic is the standard migration tool

**Alternatives rejected**:

- **MongoDB**: No ACID guarantees, overkill for simple relational data
- **MySQL**: Similar to PostgreSQL but worse JSON support, less features
- **SQLite**: Not suitable for production web app (concurrency issues)
- **Prisma (JS)**: Would require Node.js backend

**Example model**:

```python
# api/models/student.py
from sqlalchemy import Column, String, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

class Student(Base):
    __tablename__ = "students"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    cfi_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    certificate_type = Column(String(50), nullable=False)  # "private", "instrument", "commercial"
    total_hours = Column(Float, default=0.0)

    # Relationships
    cfi = relationship("User", back_populates="students")
    lessons = relationship("Lesson", back_populates="student")
```

---

## Authentication & Authorization

### Clerk (Latest)

**Why Clerk?**

- **Fastest setup**: Drop-in React components, 5 minutes to auth
- **Free tier**: Up to 5K MAUs (enough for MVP)
- **Multi-tenancy**: CFI-student role separation built-in
- **Next.js SDK**: `useUser()`, `useAuth()` hooks work seamlessly
- **Security**: JWT tokens, refresh tokens, session management handled

**Alternatives rejected**:

- **Auth0**: More expensive ($25/mo), complex setup
- **Supabase Auth**: Ties us to Supabase backend (we use FastAPI)
- **NextAuth.js**: Manual setup, need to manage OAuth providers
- **Custom auth**: Too time-consuming, security risk for solo dev

**Implementation**:

```typescript
// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs'

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html>
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}
```

```typescript
// Middleware for API routes
import { authMiddleware } from '@clerk/nextjs'

export default authMiddleware({
  publicRoutes: ['/api/v1/health'],
})
```

**Roles**:

- `cfi` — Can create/edit students, log lessons, view all data
- `student` — Read-only access to own progress, lessons, profile

---

## Deployment & Infrastructure

### Vercel (Frontend Hosting)

**Why Vercel?**

- **Zero config**: Push to GitHub → auto-deploy
- **Free tier**: Hobby plan (no credit card required for MVP)
- **Edge network**: Global CDN for fast page loads
- **Next.js optimized**: Made by the same team
- **Preview deploys**: Every PR gets a preview URL

**Alternatives rejected**:

- **Netlify**: Similar but less Next.js-specific optimizations
- **AWS Amplify**: More complex setup, manual config
- **Self-hosted**: Too much DevOps work for solo dev

**Configuration**:

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "env": {
    "NEXT_PUBLIC_API_URL": "https://api.flightpro.app"
  }
}
```

---

### Railway (Backend Hosting + Database)

**Why Railway?**

- **All-in-one**: API + PostgreSQL in one platform ($5/mo Starter)
- **Simple deploy**: Connect GitHub, auto-deploy on push
- **Free dev tier**: $5 credit/month (enough for testing)
- **Database included**: Managed PostgreSQL (no separate setup)
- **Environment variables**: Easy secrets management

**Alternatives rejected**:

- **Heroku**: More expensive ($7/mo dyno + $9/mo DB = $16/mo)
- **DigitalOcean App Platform**: Manual Docker setup
- **Render**: Similar to Railway but slower deploys
- **AWS EC2**: Too much DevOps for solo dev

**Configuration**:

```toml
# railway.toml
[build]
builder = "nixpacks"

[deploy]
startCommand = "uvicorn main:app --host 0.0.0.0 --port $PORT"
healthcheckPath = "/api/v1/health"
restartPolicyType = "on_failure"

[env]
DATABASE_URL = "${{Postgres.DATABASE_URL}}"
```

---

## Development Tools

### TypeScript 5.x (Frontend)

**Why TypeScript?**

- **Catch bugs early**: Type errors found at compile time, not runtime
- **Better DX**: Autocomplete, refactoring support in VS Code
- **Next.js default**: No extra setup required

**Configuration**:

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["dom", "dom.iterable", "esnext"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "paths": {
      "@/*": ["./app/*"]
    }
  }
}
```

---

### Linting & Formatting

**Frontend**:

- **ESLint**: Next.js built-in config (`eslint-config-next`)
- **Prettier**: Auto-format on save
- **Husky**: Pre-commit hooks (lint before commit)

**Backend**:

- **Ruff**: Fast Python linter (replaces Pylint, Flake8, isort)
- **Black**: Auto-formatter for Python
- **Pyright**: Type checker for Python

**Configuration**:

```json
// .eslintrc.json
{
  "extends": ["next/core-web-vitals", "prettier"]
}
```

```toml
# pyproject.toml
[tool.ruff]
line-length = 100
select = ["E", "F", "I"]

[tool.black]
line-length = 100
```

---

## Testing Stack

### Frontend Testing

**Jest + React Testing Library**:

- **Unit tests**: Component logic, utility functions
- **Integration tests**: User interactions, form submissions

**Example**:

```typescript
// app/components/StudentCard.test.tsx
import { render, screen } from '@testing-library/react'
import { StudentCard } from './StudentCard'

test('displays student name', () => {
  const student = { id: '1', name: 'John Doe', total_hours: 25.5 }
  render(<StudentCard student={student} />)
  expect(screen.getByText('John Doe')).toBeInTheDocument()
})
```

---

### Backend Testing

**pytest + TestClient**:

- **Unit tests**: Service logic, progress calculations
- **Integration tests**: API endpoints, database queries

**Example**:

```python
# api/tests/test_students.py
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_create_student():
    response = client.post("/api/v1/students", json={
        "name": "John Doe",
        "email": "john@example.com",
        "certificate_type": "private"
    })
    assert response.status_code == 201
    assert response.json()["name"] == "John Doe"
```

---

### E2E Testing (Planned)

**Playwright**:

- **Critical user flows**: Login, create student, log lesson
- **Run before deploy**: Staging environment only

---

## Monitoring & Analytics (Planned)

### Vercel Analytics (Frontend)

**What**: Built-in performance monitoring

- Core Web Vitals (LCP, FID, CLS)
- Real user monitoring (RUM)
- Free tier included

### PostHog (Planned - Product Analytics)

**What**: Open-source analytics + feature flags

- User behavior tracking (which features used?)
- Funnel analysis (sign-up → first lesson logged)
- Free self-hosted or $5/mo cloud

---

## Dependency Management

### Frontend (npm/pnpm)

**Why pnpm?**

- **Faster installs**: 3x faster than npm
- **Disk efficient**: Shared packages across projects
- **Strict**: Prevents phantom dependencies

**Lock file**: `pnpm-lock.yaml` (committed to git)

---

### Backend (pip/uv)

**Why uv?** (Rust-based pip alternative)

- **10x faster** than pip
- **Automatic venv** management
- **Lock file** support (like pnpm-lock.yaml)

**Lock file**: `uv.lock` (committed to git)

**Example workflow**:

```bash
# Install dependencies
uv sync

# Add new dependency
uv add fastapi

# Run app
uv run uvicorn main:app --reload
```

---

## Security

### Environment Variables

**Never commit**:

- `DATABASE_URL`
- `CLERK_SECRET_KEY`
- `STRIPE_SECRET_KEY` (future)

**Storage**:

- **Local**: `.env.local` (gitignored)
- **Vercel**: Environment Variables UI
- **Railway**: Railway dashboard

**Example**:

```bash
# .env.local (never commit)
DATABASE_URL="postgresql://user:pass@localhost:5432/flightpro"
CLERK_SECRET_KEY="sk_test_..."
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
```

---

### CORS Configuration

**Backend** (`main.py`):

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://flightpro.app", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```

---

## Versioning Strategy

### API Versioning

**URL-based**: `/api/v1/`, `/api/v2/`

- **Why**: Simple, explicit, easy to route
- **Future**: Add `/api/v2/` when breaking changes needed

### Semantic Versioning (SemVer)

**Format**: `MAJOR.MINOR.PATCH` (e.g., `1.2.3`)

- **MAJOR**: Breaking changes (v1 → v2)
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes

**Tool**: Managed in `package.json` (frontend) and `pyproject.toml` (backend)

---

## Cost Model

### MVP Costs (Month 1-3)

| Service | Plan | Cost |
|---------|------|------|
| Vercel | Hobby | $0/mo |
| Railway | Starter | $5/mo |
| Clerk | Free | $0/mo (up to 5K MAUs) |
| GitHub Actions | Free | $0/mo (2K minutes) |
| Domain | Namecheap | $1/mo (.app domain) |
| **Total** | | **$6/mo** |

---

### Scale-Up Costs (100 CFIs, 500 students)

| Service | Plan | Cost |
|---------|------|------|
| Vercel | Pro | $20/mo |
| Railway | Developer | $20/mo |
| Clerk | Essential | $25/mo (10K MAUs) |
| PostHog | Cloud | $5/mo |
| **Total** | | **$70/mo** |

**Target revenue**: 100 CFIs × $10/mo = $1,000/mo
**Profit margin**: $1,000 - $70 = $930/mo (93%)

---

## Alternatives Rejected (Summary)

### Full-Stack Frameworks

- ❌ **T3 Stack (Next.js + tRPC)**: Requires Node.js backend (we chose Python)
- ❌ **Blitz.js**: Less mature, smaller ecosystem
- ❌ **RedwoodJS**: More opinionated, GraphQL-first (we use REST)

### Databases

- ❌ **Supabase**: Ties us to their ecosystem (want flexibility)
- ❌ **PlanetScale**: MySQL-based (prefer PostgreSQL features)
- ❌ **Firebase**: NoSQL (need relational data)

### Hosting

- ❌ **AWS**: Too complex, too expensive ($50+/mo minimum)
- ❌ **GCP**: Similar complexity to AWS
- ❌ **Azure**: Microsoft-centric, overkill for MVP

---

## Change Log

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| 2025-10-24 | Initial stack | MVP planning | Baseline architecture |

---

## References

- **Next.js Docs**: https://nextjs.org/docs
- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **Railway Docs**: https://docs.railway.app/
- **Clerk Docs**: https://clerk.com/docs
