# Contributing to {{PROJECT_NAME}}

Thank you for your interest in contributing to {{PROJECT_NAME}}! This document provides guidelines for contributing to the project.

## Code of Conduct

We expect all contributors to:
- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Development Environment**:
   - {{FRONTEND}} development environment
   - {{DATABASE}} installed locally
   - {{DEPLOY_PLATFORM}} CLI (if applicable)

2. **Access**:
   - GitHub account
   - Fork of this repository
   - Local development environment set up

### Development Setup

1. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/{{PROJECT_NAME}}.git
   cd {{PROJECT_NAME}}
   ```

2. **Install dependencies**:
   ```bash
   npm install  # or yarn/pnpm based on project
   ```

3. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Fill in required values
   ```

4. **Run local development server**:
   ```bash
   npm run dev
   ```

5. **Run tests**:
   ```bash
   npm test
   ```

## Development Workflow

We follow **{{GIT_WORKFLOW}}** for all contributions.

### Branch Naming

Use descriptive branch names with the following prefixes:

- `feature/` - New features (e.g., `feature/add-user-authentication`)
- `fix/` - Bug fixes (e.g., `fix/login-redirect-error`)
- `docs/` - Documentation updates (e.g., `docs/update-readme`)
- `refactor/` - Code refactoring (e.g., `refactor/user-service`)
- `test/` - Test additions/updates (e.g., `test/add-unit-tests`)
- `chore/` - Maintenance tasks (e.g., `chore/update-dependencies`)

### Commit Messages

Follow **Conventional Commits** format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `refactor`: Code restructure (no feature change)
- `test`: Test additions/updates
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes

**Examples**:
```
feat(auth): add OAuth2 login flow

Implement OAuth2 authentication using {{AUTH_PROVIDER}}.
Includes login, logout, and token refresh.

Closes #42
```

```
fix(api): resolve race condition in user creation

Add transaction locking to prevent duplicate user records
when multiple signup requests occur simultaneously.

Fixes #156
```

## Pull Request Process

### Before Submitting

1. **Ensure all tests pass**:
   ```bash
   npm test
   npm run lint
   npm run build
   ```

2. **Update documentation**:
   - Add/update relevant docs in `docs/`
   - Update README if adding new features
   - Add JSDoc/docstrings to new functions

3. **Add tests**:
   - Unit tests for new logic
   - Integration tests for API changes
   - E2E tests for UI workflows

### Submitting PR

1. **Push your branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request**:
   - Go to GitHub repository
   - Click "New Pull Request"
   - Select your branch
   - Fill in PR template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex code sections
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added and passing
- [ ] Dependent changes merged
```

3. **Request Review**:
   - Assign relevant reviewers (see CODEOWNERS)
   - Link related issues
   - Add appropriate labels

### Code Review

- **Be responsive**: Address review comments promptly
- **Be open**: Accept constructive criticism
- **Explain**: Clarify design decisions when asked
- **Iterate**: Push updates to same branch (PR updates automatically)

### Merge Requirements

PRs must meet these criteria before merging:

- [ ] All CI checks passing
- [ ] At least 1 approving review
- [ ] No merge conflicts
- [ ] All conversations resolved
- [ ] Branch up to date with main
- [ ] Code coverage maintained or improved

## Coding Standards

### {{FRONTEND}} (Frontend)

- **Style Guide**: Follow project ESLint config
- **Components**: Use functional components with hooks
- **State Management**: [Project-specific guidance]
- **Naming**: PascalCase for components, camelCase for functions

### {{API_STYLE}} API (Backend)

- **Style Guide**: Follow project linting rules
- **Structure**: Keep routes thin, logic in services
- **Error Handling**: Use standard error responses (RFC 7807)
- **Validation**: Validate all inputs

### {{DATABASE}} (Database)

- **Migrations**: Always create migrations for schema changes
- **Naming**: `snake_case` for tables/columns
- **Indexes**: Add indexes for queried fields
- **Constraints**: Use DB constraints, not just app logic

## Testing Guidelines

### Test Coverage

- Maintain **minimum 80% code coverage**
- 100% coverage for critical business logic
- Test edge cases and error paths

### Test Structure

```typescript
describe('Feature/Component', () => {
  describe('method/function', () => {
    it('should do expected behavior under normal conditions', () => {
      // Arrange
      // Act
      // Assert
    });

    it('should handle error case gracefully', () => {
      // Test error scenarios
    });
  });
});
```

### Test Types

1. **Unit Tests**: Test individual functions/components in isolation
2. **Integration Tests**: Test API endpoints and database interactions
3. **E2E Tests**: Test complete user workflows

## Documentation

### Code Documentation

- **Functions**: Document purpose, parameters, return values, exceptions
- **Complex Logic**: Add inline comments explaining "why", not "what"
- **APIs**: Document all endpoints in OpenAPI/GraphQL schema

### Project Documentation

Update relevant docs in `docs/`:

- `docs/project/` - Architecture and design decisions
- `docs/api/` - API documentation
- `docs/guides/` - User guides and tutorials

## Security

### Reporting Vulnerabilities

**DO NOT** open public issues for security vulnerabilities.

See [SECURITY.md](SECURITY.md) for responsible disclosure process.

### Security Best Practices

- Never commit secrets (API keys, passwords)
- Use environment variables for sensitive config
- Validate and sanitize all user input
- Follow OWASP Top 10 guidelines
- Keep dependencies up to date

## Release Process

(For maintainers)

1. **Version Bump**: Update version in `package.json`
2. **Changelog**: Update `CHANGELOG.md` with release notes
3. **Tag**: Create git tag `vX.Y.Z`
4. **Deploy**: Deployment to {{DEPLOY_PLATFORM}} happens automatically on tag push
5. **Announce**: Post release notes to discussions/changelog

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Open a GitHub Issue with bug template
- **Features**: Open a GitHub Issue with feature request template
- **Chat**: [If applicable, link to Discord/Slack]

## Recognition

Contributors are recognized in:
- GitHub contributors graph
- Release notes (for significant contributions)
- Project README (for ongoing contributors)

Thank you for contributing to {{PROJECT_NAME}}!
