# Common Mistakes

## 🚫 Missing Code Reuse Opportunities

**Problem**: Not searching for existing similar functionality

**Bad**:
```
Plan: Create new UserValidator class
(Did not search - UserValidator already exists!)
```

**Good**:
```bash
# Search first
grep -r "class.*Validator" src/
# Found: UserValidator, EmailValidator, PhoneValidator

Plan: Extend existing UserValidator class
```

---

## 🚫 Insufficient Research Depth

**Problem**: Planning without understanding existing codebase

**Bad**:
```
Plan: Use MongoDB for data storage
(Tech stack uses PostgreSQL!)
```

**Good**:
```
1. Read docs/project/tech-stack.md
2. Confirmed: PostgreSQL with Prisma ORM
3. Plan: Extend existing Prisma schema
```

---

## 🚫 Vague Architecture Descriptions

**Problem**: Too high-level, no concrete details

**Bad**:
```
Architecture: We'll have a backend and frontend
```

**Good**:
```
Architecture:
- Backend: FastAPI with layered architecture
  - Models: User, Enrollment (SQLAlchemy)
  - Services: AuthService, EnrollmentService
  - Routes: /api/v1/auth/*, /api/v1/enrollments/*
- Frontend: Next.js with App Router
  - Pages: /auth/login, /dashboard
  - Components: LoginForm, EnrollmentList
  - Hooks: useAuth, useEnrollments
```

---

## 🚫 Missing API Contract Details

**Problem**: No request/response schemas defined

**Bad**:
```
POST /api/users - Create user
```

**Good**:
```
POST /api/v1/users
Request:
  {
    "email": "string (required, valid email)",
    "name": "string (required, 2-100 chars)",
    "age": "number (optional, 13-120)"
  }
Response (201):
  {
    "id": "number",
    "email": "string",
    "name": "string",
    "age": "number | null",
    "createdAt": "ISO8601"
  }
Errors:
  400: Validation error
  409: Email already exists
```

**See [../reference.md](../reference.md#common-mistakes) for complete list**
