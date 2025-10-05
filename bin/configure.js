#!/usr/bin/env node

const inquirer = require('inquirer');
const fs = require('fs');
const path = require('path');
const chalk = require('chalk');

// Helper to get current date in ISO format
function getCurrentDate() {
  return new Date().toISOString().split('T')[0];
}

// Helper to slugify text
function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

// Helper to calculate ICE score
function calculateICE(impact, confidence, effort) {
  return ((impact * confidence) / effort).toFixed(2);
}

// Constitution Configuration
async function configureConstitution() {
  console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
  console.log(chalk.cyan.bold(' Configure Engineering Constitution'));
  console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));

  console.log(chalk.white('Let\'s customize your engineering standards!\n'));

  const answers = {};

  // Project Type
  const projectTypeAnswer = await inquirer.prompt([{
    type: 'list',
    name: 'projectType',
    message: 'What type of project is this?',
    choices: [
      'Web App',
      'API/Backend',
      'Mobile App',
      'CLI Tool',
      'Library/Package',
      new inquirer.Separator(),
      { name: 'Other (specify)', value: 'custom' }
    ]
  }]);

  if (projectTypeAnswer.projectType === 'custom') {
    const customType = await inquirer.prompt([{
      type: 'input',
      name: 'value',
      message: 'Enter your project type:',
      validate: input => input.trim() ? true : 'Project type cannot be empty'
    }]);
    answers.projectType = customType.value;
  } else {
    answers.projectType = projectTypeAnswer.projectType;
  }

  // Test Coverage
  const coverageAnswer = await inquirer.prompt([{
    type: 'list',
    name: 'coverage',
    message: 'Minimum test coverage requirement?',
    choices: [
      { name: '50% - Basic', value: 50 },
      { name: '70% - Standard', value: 70 },
      { name: '80% - Recommended (default)', value: 80 },
      { name: '90% - Strict', value: 90 },
      new inquirer.Separator(),
      { name: 'Custom percentage', value: 'custom' }
    ],
    default: 2
  }]);

  if (coverageAnswer.coverage === 'custom') {
    const customCoverage = await inquirer.prompt([{
      type: 'number',
      name: 'value',
      message: 'Enter coverage percentage (0-100):',
      validate: input => (input >= 0 && input <= 100) ? true : 'Must be between 0 and 100'
    }]);
    answers.coverage = customCoverage.value;
  } else {
    answers.coverage = coverageAnswer.coverage;
  }

  // Performance Targets (based on project type)
  if (answers.projectType === 'API/Backend') {
    const apiPerfAnswer = await inquirer.prompt([{
      type: 'list',
      name: 'apiPerf',
      message: 'API response time target?',
      choices: [
        { name: '<200ms p50, <500ms p95 (recommended)', value: { p50: 200, p95: 500 } },
        { name: '<100ms p50, <300ms p95 (strict)', value: { p50: 100, p95: 300 } },
        { name: '<500ms p50, <1000ms p95 (relaxed)', value: { p50: 500, p95: 1000 } },
        new inquirer.Separator(),
        { name: 'Custom', value: 'custom' }
      ]
    }]);

    if (apiPerfAnswer.apiPerf === 'custom') {
      const customApiPerf = await inquirer.prompt([
        {
          type: 'number',
          name: 'p50',
          message: 'p50 target (ms):',
          default: 200
        },
        {
          type: 'number',
          name: 'p95',
          message: 'p95 target (ms):',
          default: 500
        }
      ]);
      answers.apiPerf = customApiPerf;
    } else {
      answers.apiPerf = apiPerfAnswer.apiPerf;
    }
  } else if (answers.projectType === 'Web App') {
    const webPerfAnswer = await inquirer.prompt([{
      type: 'list',
      name: 'webPerf',
      message: 'Page load performance target?',
      choices: [
        { name: '<2s FCP, <3s LCP (recommended)', value: { fcp: 2, lcp: 3 } },
        { name: '<1s FCP, <2s LCP (strict)', value: { fcp: 1, lcp: 2 } },
        { name: '<3s FCP, <4s LCP (relaxed)', value: { fcp: 3, lcp: 4 } },
        new inquirer.Separator(),
        { name: 'Custom', value: 'custom' }
      ]
    }]);

    if (webPerfAnswer.webPerf === 'custom') {
      const customWebPerf = await inquirer.prompt([
        {
          type: 'number',
          name: 'fcp',
          message: 'First Contentful Paint target (seconds):',
          default: 2
        },
        {
          type: 'number',
          name: 'lcp',
          message: 'Largest Contentful Paint target (seconds):',
          default: 3
        }
      ]);
      answers.webPerf = customWebPerf;
    } else {
      answers.webPerf = webPerfAnswer.webPerf;
    }
  }

  // Accessibility (for Web/Mobile)
  if (answers.projectType === 'Web App' || answers.projectType === 'Mobile App') {
    const a11yAnswer = await inquirer.prompt([{
      type: 'list',
      name: 'a11y',
      message: 'WCAG compliance level?',
      choices: [
        { name: 'Level A - Minimum', value: 'A' },
        { name: 'Level AA - Recommended (default)', value: 'AA' },
        { name: 'Level AAA - Strict', value: 'AAA' },
        new inquirer.Separator(),
        { name: 'Skip accessibility requirements', value: 'skip' }
      ],
      default: 1
    }]);
    answers.a11y = a11yAnswer.a11y;
  }

  // Additional Principles
  const additionalAnswer = await inquirer.prompt([{
    type: 'input',
    name: 'additional',
    message: 'Any project-specific principles? (optional, e.g., "Mobile-first design"):',
  }]);
  answers.additional = additionalAnswer.additional.trim();

  return answers;
}

// Roadmap Configuration
async function configureRoadmap() {
  console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
  console.log(chalk.cyan.bold(' Configure Product Roadmap'));
  console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));

  console.log(chalk.white('Let\'s build your product roadmap!\n'));
  console.log(chalk.gray('ICE Scoring:'));
  console.log(chalk.gray('  - Impact (1-5): Value for users'));
  console.log(chalk.gray('  - Effort (1-5): Implementation complexity'));
  console.log(chalk.gray('  - Confidence (0-1): Estimate certainty'));
  console.log(chalk.gray('  - ICE Score = (Impact × Confidence) ÷ Effort\n'));

  const features = [];

  const addFirstAnswer = await inquirer.prompt([{
    type: 'confirm',
    name: 'addFirst',
    message: 'Add your first feature now?',
    default: true
  }]);

  if (!addFirstAnswer.addFirst) {
    return features;
  }

  let addMore = true;
  let featureCount = 0;
  const maxFeatures = 5;

  while (addMore && featureCount < maxFeatures) {
    const feature = {};

    // Feature Title
    const titleAnswer = await inquirer.prompt([{
      type: 'input',
      name: 'title',
      message: `Feature ${featureCount + 1} - What's the feature?`,
      validate: input => input.trim() ? true : 'Feature title cannot be empty'
    }]);
    feature.title = titleAnswer.title;
    feature.slug = slugify(titleAnswer.title);

    // Area
    const areaAnswer = await inquirer.prompt([{
      type: 'list',
      name: 'area',
      message: 'What area is this?',
      choices: [
        'marketing',
        'app',
        'api',
        'infra',
        'design',
        new inquirer.Separator(),
        { name: 'Other (specify)', value: 'custom' }
      ]
    }]);

    if (areaAnswer.area === 'custom') {
      const customArea = await inquirer.prompt([{
        type: 'input',
        name: 'value',
        message: 'Enter area:',
        validate: input => input.trim() ? true : 'Area cannot be empty'
      }]);
      feature.area = customArea.value;
    } else {
      feature.area = areaAnswer.area;
    }

    // Role
    const roleAnswer = await inquirer.prompt([{
      type: 'list',
      name: 'role',
      message: 'Who is this for?',
      choices: [
        'all',
        'free',
        'student',
        'cfi',
        'school',
        new inquirer.Separator(),
        { name: 'Other (specify)', value: 'custom' }
      ]
    }]);

    if (roleAnswer.role === 'custom') {
      const customRole = await inquirer.prompt([{
        type: 'input',
        name: 'value',
        message: 'Enter role:',
        validate: input => input.trim() ? true : 'Role cannot be empty'
      }]);
      feature.role = customRole.value;
    } else {
      feature.role = roleAnswer.role;
    }

    // Impact
    const impactAnswer = await inquirer.prompt([{
      type: 'list',
      name: 'impact',
      message: 'Impact (value for users)?',
      choices: [
        { name: '1 - Nice to have', value: 1 },
        { name: '2 - Useful', value: 2 },
        { name: '3 - Important improvement', value: 3 },
        { name: '4 - High value', value: 4 },
        { name: '5 - Game changer', value: 5 }
      ]
    }]);
    feature.impact = impactAnswer.impact;

    // Effort
    const effortAnswer = await inquirer.prompt([{
      type: 'list',
      name: 'effort',
      message: 'Effort (complexity to build)?',
      choices: [
        { name: '1 - Few hours', value: 1 },
        { name: '2 - 1-2 days', value: 2 },
        { name: '3 - 3-5 days', value: 3 },
        { name: '4 - 1-2 weeks', value: 4 },
        { name: '5 - 2+ weeks', value: 5 }
      ]
    }]);
    feature.effort = effortAnswer.effort;

    // Confidence
    const confidenceAnswer = await inquirer.prompt([{
      type: 'list',
      name: 'confidence',
      message: 'Confidence (certainty of estimates)?',
      choices: [
        { name: '0.5 - Wild guess', value: 0.5 },
        { name: '0.7 - Rough estimate', value: 0.7 },
        { name: '0.9 - Very confident', value: 0.9 },
        { name: '1.0 - Certain', value: 1.0 }
      ]
    }]);
    feature.confidence = confidenceAnswer.confidence;

    // Calculate ICE score
    feature.score = calculateICE(feature.impact, feature.confidence, feature.effort);

    // Requirements
    const requirementsAnswer = await inquirer.prompt([{
      type: 'input',
      name: 'requirements',
      message: 'Key requirements (comma-separated, or press Enter to skip):',
    }]);
    feature.requirements = requirementsAnswer.requirements
      ? requirementsAnswer.requirements.split(',').map(r => r.trim()).filter(Boolean)
      : [];

    features.push(feature);

    console.log(chalk.green(`\n✓ Feature added: ${feature.slug}`));
    console.log(chalk.white(`  Impact: ${feature.impact} | Effort: ${feature.effort} | Confidence: ${feature.confidence}`));
    console.log(chalk.white(`  ICE Score: ${feature.score}\n`));

    featureCount++;

    if (featureCount < maxFeatures) {
      const moreAnswer = await inquirer.prompt([{
        type: 'confirm',
        name: 'more',
        message: 'Add another feature?',
        default: true
      }]);
      addMore = moreAnswer.more;
    } else {
      addMore = false;
    }
  }

  // Sort by ICE score
  features.sort((a, b) => parseFloat(b.score) - parseFloat(a.score));

  return features;
}

// Design Inspirations Configuration
async function configureDesignInspirations() {
  console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
  console.log(chalk.cyan.bold(' Configure Design Inspirations'));
  console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));

  console.log(chalk.white('Let\'s curate your design inspirations!\n'));
  console.log(chalk.gray('Design inspirations help maintain visual consistency by referencing:'));
  console.log(chalk.gray('  - Color palettes and typography'));
  console.log(chalk.gray('  - Component styles and patterns'));
  console.log(chalk.gray('  - Layout and spacing systems'));
  console.log(chalk.gray('  - Animation and interaction patterns\n'));

  const inspirations = [];

  const addFirstAnswer = await inquirer.prompt([{
    type: 'confirm',
    name: 'addFirst',
    message: 'Add design inspiration now?',
    default: true
  }]);

  if (!addFirstAnswer.addFirst) {
    return inspirations;
  }

  let addMore = true;
  let count = 0;
  const maxInspirations = 3;

  while (addMore && count < maxInspirations) {
    const inspiration = {};

    // Name
    const nameAnswer = await inquirer.prompt([{
      type: 'input',
      name: 'name',
      message: `Inspiration ${count + 1} - Site or app name?`,
      validate: input => input.trim() ? true : 'Name cannot be empty'
    }]);
    inspiration.name = nameAnswer.name;

    // URL
    const urlAnswer = await inquirer.prompt([{
      type: 'input',
      name: 'url',
      message: 'URL:',
      validate: input => {
        if (!input.trim()) return 'URL cannot be empty';
        if (!input.startsWith('http://') && !input.startsWith('https://')) {
          return 'URL must start with http:// or https://';
        }
        return true;
      }
    }]);
    inspiration.url = urlAnswer.url;

    // Aspects
    const aspectsAnswer = await inquirer.prompt([{
      type: 'checkbox',
      name: 'aspects',
      message: 'What aspects inspire you? (select all that apply)',
      choices: [
        { name: 'Colors', checked: true },
        { name: 'Typography', checked: true },
        { name: 'Layout', checked: false },
        { name: 'Components', checked: false },
        { name: 'Animations', checked: false }
      ],
      validate: input => input.length > 0 ? true : 'Select at least one aspect'
    }]);
    inspiration.aspects = aspectsAnswer.aspects;

    // Notes
    const notesAnswer = await inquirer.prompt([{
      type: 'input',
      name: 'notes',
      message: 'What specific elements stand out? (optional):',
    }]);
    inspiration.notes = notesAnswer.notes.trim();

    inspirations.push(inspiration);

    console.log(chalk.green(`\n✓ Added: ${inspiration.name}\n`));

    count++;

    if (count < maxInspirations) {
      const moreAnswer = await inquirer.prompt([{
        type: 'confirm',
        name: 'more',
        message: 'Add another inspiration?',
        default: false
      }]);
      addMore = moreAnswer.more;
    } else {
      addMore = false;
    }
  }

  return inspirations;
}

// Generate Constitution File
function generateConstitution(answers, targetDir) {
  const constitutionPath = path.join(targetDir, '.spec-flow', 'memory', 'constitution.md');

  let perfSection = '';
  if (answers.apiPerf) {
    perfSection = `- API responses: <${answers.apiPerf.p50}ms p50, <${answers.apiPerf.p95}ms p95`;
  } else if (answers.webPerf) {
    perfSection = `- Page loads: <${answers.webPerf.fcp}s First Contentful Paint, <${answers.webPerf.lcp}s Largest Contentful Paint`;
  } else {
    perfSection = `- Define performance thresholds appropriate for ${answers.projectType}`;
  }

  let a11ySection = '';
  if (answers.a11y && answers.a11y !== 'skip') {
    a11ySection = `
### 4. Accessibility (a11y)

**Principle**: All UI features must meet WCAG 2.1 Level ${answers.a11y} standards.

**Why**: Inclusive design reaches more users and is often legally required.

**Implementation**:
- Semantic HTML, ARIA labels where needed
- Keyboard navigation support (no mouse-only interactions)
- Color contrast ratios: 4.5:1 for text, 3:1 for UI components
- Screen reader testing during \`/preview\` phase
- Use automated tools (axe, Lighthouse) in \`/optimize\` phase

**Violations**:
- ❌ Mouse-only interactions
- ❌ Low contrast text
- ❌ Missing alt text, ARIA labels, or focus states

---
`;
  }

  let additionalSection = '';
  if (answers.additional) {
    additionalSection = `
### ${a11ySection ? '5' : '4'}. ${answers.additional}

**Principle**: [Customize this principle based on your project needs]

**Why**: [Explain why this principle matters for your project]

**Implementation**:
- [Add specific implementation guidelines]

**Violations**:
- ❌ [Define what violates this principle]

---
`;
  }

  const content = `# Engineering Constitution

**Version**: 1.0.0
**Last Updated**: ${getCurrentDate()}
**Status**: Active
**Project Type**: ${answers.projectType}

> This document defines the core engineering principles that govern all feature development in this project. Every specification, plan, and implementation must align with these principles.

---

## Purpose

The Engineering Constitution serves as the Single Source of Truth (SSOT) for engineering standards and decision-making. When in doubt, refer to these principles. When principles conflict with convenience, principles win.

---

## Core Principles

### 1. Specification First

**Principle**: Every feature begins with a written specification that defines requirements, success criteria, and acceptance tests before any code is written.

**Why**: Specifications prevent scope creep, align stakeholders, and create an auditable trail of decisions.

**Implementation**:
- Use \`/spec-flow\` to create specifications from roadmap entries
- Specifications must define: purpose, user stories, acceptance criteria, out-of-scope items
- No implementation work starts until spec is reviewed and approved
- Changes to requirements require spec updates first

**Violations**:
- ❌ Starting implementation without a spec
- ❌ Adding features not in the spec without updating it first
- ❌ Skipping stakeholder review of specifications

---

### 2. Testing Standards

**Principle**: All production code must have automated tests with minimum ${answers.coverage}% code coverage.

**Why**: Tests prevent regressions, document behavior, and enable confident refactoring.

**Implementation**:
- Unit tests for business logic (${answers.coverage}%+ coverage required)
- Integration tests for API contracts
- E2E tests for critical user flows
- Tests written alongside implementation (not after)
- Use \`/tasks\` phase to include test tasks in implementation plan

**Violations**:
- ❌ Merging code without tests
- ❌ Skipping tests for "simple" features
- ❌ Writing tests only after implementation is complete

---

### 3. Performance Requirements

**Principle**: Define and enforce performance thresholds for all user-facing features.

**Why**: Performance is a feature, not an optimization task. Users abandon slow experiences.

**Implementation**:
${perfSection}
- Database queries: <50ms for reads, <100ms for writes
- Define thresholds in spec, measure in \`/optimize\` phase
- Use Lighthouse, Web Vitals, or similar tools for validation

**Violations**:
- ❌ Shipping features without performance benchmarks
- ❌ Ignoring performance regressions in code review
- ❌ N+1 queries, unbounded loops, blocking operations

---
${a11ySection}${additionalSection}
### ${a11ySection && additionalSection ? '6' : a11ySection || additionalSection ? '5' : '4'}. Security Practices

**Principle**: Security is not optional. All features must follow secure coding practices.

**Why**: Breaches destroy trust and can be catastrophic for users and the business.

**Implementation**:
- Input validation on all user-provided data
- Parameterized queries (no string concatenation for SQL)
- Authentication/authorization checks on all protected routes
- Secrets in environment variables, never committed to code
- Security review during \`/optimize\` phase

**Violations**:
- ❌ Trusting user input without validation
- ❌ Exposing sensitive data in logs, errors, or responses
- ❌ Hardcoded credentials or API keys

---

### ${a11ySection && additionalSection ? '7' : a11ySection || additionalSection ? '6' : '5'}. Code Quality

**Principle**: Code must be readable, maintainable, and follow established patterns.

**Why**: Code is read 10x more than it's written. Optimize for future maintainers.

**Implementation**:
- Follow project style guides (linters, formatters)
- Functions <50 lines, classes <300 lines
- Meaningful names (no \`x\`, \`temp\`, \`data\`)
- Comments explain "why", not "what"
- DRY (Don't Repeat Yourself): Extract reusable utilities
- KISS (Keep It Simple, Stupid): Simplest solution that works

**Violations**:
- ❌ Copy-pasting code instead of extracting functions
- ❌ Overly clever one-liners that obscure intent
- ❌ Skipping code review feedback

---

### ${a11ySection && additionalSection ? '8' : a11ySection || additionalSection ? '7' : '6'}. Documentation Standards

**Principle**: Document decisions, not just code. Future you will thank you.

**Why**: Context decays fast. Documentation preserves the "why" behind decisions.

**Implementation**:
- Update \`NOTES.md\` during feature development (decisions, blockers, pivots)
- API endpoints: Document request/response schemas (OpenAPI/Swagger)
- Complex logic: Add inline comments explaining rationale
- Breaking changes: Update CHANGELOG.md
- User-facing features: Update user docs

**Violations**:
- ❌ Undocumented API changes
- ❌ Empty NOTES.md after multi-week features
- ❌ Cryptic commit messages ("fix stuff", "updates")

---

### ${a11ySection && additionalSection ? '9' : a11ySection || additionalSection ? '8' : '7'}. Do Not Overengineer

**Principle**: Ship the simplest solution that meets requirements. Iterate later.

**Why**: Premature optimization wastes time and creates complexity debt.

**Implementation**:
- YAGNI (You Aren't Gonna Need It): Build for today, not hypothetical futures
- Use proven libraries instead of custom implementations
- Defer abstractions until patterns emerge (Rule of Three)
- Ship MVPs, gather feedback, iterate

**Violations**:
- ❌ Building frameworks when a library exists
- ❌ Abstracting after one use case
- ❌ Optimization without profiling data

---

## Conflict Resolution

When principles conflict (e.g., "ship fast" vs "test thoroughly"), prioritize in this order:

1. **Security** - Never compromise on security
2. **Accessibility** - Legal and ethical obligation
3. **Testing** - Prevents regressions, enables velocity
4. **Specification** - Alignment prevents waste
5. **Performance** - User experience matters
6. **Code Quality** - Long-term maintainability
7. **Documentation** - Preserves context
8. **Simplicity** - Avoid premature optimization

---

## Amendment Process

This constitution evolves with the project. To propose changes:

1. Run \`/constitution "describe proposed change"\`
2. Claude will update the constitution and bump the version:
   - **MAJOR**: Removed principle or added mandatory requirement
   - **MINOR**: Added principle or expanded guidance
   - **PATCH**: Fixed typo or updated date
3. Review the diff and approve/reject
4. Commit the updated constitution

---

## References

- **Spec-Flow Commands**: \`.claude/commands/\`
- **Templates**: \`.spec-flow/templates/\`
- **Roadmap**: \`.spec-flow/memory/roadmap.md\`
- **Design Inspirations**: \`.spec-flow/memory/design-inspirations.md\`

---

**Maintained by**: Engineering Team + Claude Code
**Review Cycle**: Quarterly or after major project milestones
`;

  fs.writeFileSync(constitutionPath, content, 'utf8');
  console.log(chalk.green(`✓ Constitution saved: ${constitutionPath}`));
}

// Generate Roadmap File
function generateRoadmap(features, targetDir) {
  const roadmapPath = path.join(targetDir, '.spec-flow', 'memory', 'roadmap.md');

  let backlogSection = '';
  if (features.length > 0) {
    backlogSection = features.map(f => `
### ${f.slug}
- **Title**: ${f.title}
- **Area**: ${f.area}
- **Role**: ${f.role}
- **Impact**: ${f.impact} | **Effort**: ${f.effort} | **Confidence**: ${f.confidence} | **Score**: ${f.score}
- **Requirements**:
${f.requirements.length > 0 ? f.requirements.map(r => `  - ${r}`).join('\n') : '  - [To be defined]'}
`).join('\n');
  }

  const content = `# Spec-Flow Product Roadmap

**Last updated**: ${getCurrentDate()}

> Features from brainstorm → shipped. Managed via \`/roadmap\`

## Shipped

<!-- Released to production -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Area**: marketing|app|api|infra|design
- **Role**: free|student|cfi|school|all
- **Date**: YYYY-MM-DD
- **Release**: vX.Y.Z - One-line release notes
-->

## In Progress

<!-- Currently implementing (linked to active branches) -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Area**: marketing|app|api|infra|design
- **Role**: free|student|cfi|school|all
- **Phase**: 0-12 (optional)
- **Impact**: 1-5 | **Effort**: 1-5 | **Confidence**: 0-1 | **Score**: X.XX
- **Requirements**:
  - Requirement 1
- **Branch**: NNN-feature-name
- **Owner**: @username (optional)
-->

## Next

<!-- Top 5-10 prioritized features (sorted by score) -->
<!-- Same format as In Progress, no Branch/Owner -->

## Later

<!-- Future features (10-20 items, sorted by score) -->
<!-- Same format as Next -->

## Backlog
${backlogSection}
<!-- All other ideas (unlimited, sorted by score) -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Area**: marketing|app|api
- **Role**: student|cfi|school|all
- **Impact**: 1-5 | **Effort**: 1-5 | **Confidence**: 0-1 | **Score**: X.XX
- **Requirements**: [CLARIFY: questions] or brief bullets
-->

## Archive

<!-- Deprecated features -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Reason**: Why archived
- **Date**: YYYY-MM-DD
-->

---

## Scoring Guide

**ICE** = Impact × Confidence ÷ Effort

- **Impact** (1-5): 1=nice-to-have, 3=useful, 5=critical
- **Effort** (1-5): 1=<1 day, 3=1-2 weeks, 5=4+ weeks
- **Confidence** (0-1): 0.5=uncertain, 0.7=some unknowns, 0.9=high, 1.0=certain

Higher score = higher priority

## Status Flow

\`\`\`
Backlog → Later → Next → In Progress → Shipped
                                ↓
                             Archive
\`\`\`

## Feature Sizing

**/spec-flow-sized**: 30 tasks, one screen/flow/API, 1-2 weeks

If larger: Break into multiple features by area or domain
`;

  fs.writeFileSync(roadmapPath, content, 'utf8');
  console.log(chalk.green(`✓ Roadmap saved: ${roadmapPath}`));
}

// Generate Design Inspirations File
function generateDesignInspirations(inspirations, targetDir) {
  const designPath = path.join(targetDir, '.spec-flow', 'memory', 'design-inspirations.md');

  // Group by first aspect for organization
  const grouped = {
    'Color & Typography': [],
    'Components & Layout': [],
    'Animations': [],
    'General': []
  };

  inspirations.forEach(insp => {
    const aspects = insp.aspects.join(', ');
    if (insp.aspects.includes('Colors') || insp.aspects.includes('Typography')) {
      grouped['Color & Typography'].push({ ...insp, aspectsStr: aspects });
    } else if (insp.aspects.includes('Components') || insp.aspects.includes('Layout')) {
      grouped['Components & Layout'].push({ ...insp, aspectsStr: aspects });
    } else if (insp.aspects.includes('Animations')) {
      grouped['Animations'].push({ ...insp, aspectsStr: aspects });
    } else {
      grouped['General'].push({ ...insp, aspectsStr: aspects });
    }
  });

  let sectionsContent = '';
  Object.entries(grouped).forEach(([category, items]) => {
    if (items.length > 0) {
      sectionsContent += `\n## ${category}\n`;
      items.forEach(item => {
        sectionsContent += `\n### ${item.name}\n`;
        sectionsContent += `**URL**: ${item.url}\n`;
        sectionsContent += `**Inspiration**: ${item.aspectsStr}\n`;
        if (item.notes) {
          sectionsContent += `**Notes**: ${item.notes}\n`;
        }
        sectionsContent += `**Added**: ${getCurrentDate()}\n`;
      });
    }
  });

  const content = `# Spec-Flow Design Inspirations

**Purpose**: Global mood board of design patterns, styles, and interactions we admire. Reference this when creating specs or implementing UI features.

**Last updated**: ${getCurrentDate()}

---
${sectionsContent}
---

## Usage Guidelines

**When to add entries:**
- Found inspiring design during research
- User or team member shares good example
- Discovered pattern that solves a real user problem we face

**What to capture:**
- Quick observations (not exhaustive analysis)
- Specific elements (button styles, animations, layout patterns)
- Why it matters for our audience

**What NOT to do:**
- Don't duplicate feature-specific visuals/README.md (use that for deep dives)
- Don't add every site you see (quality > quantity)
- Don't capture patterns that conflict with our principles (simplicity, clarity, accessibility)

---

**Maintained by**: Claude Code + Team
`;

  fs.writeFileSync(designPath, content, 'utf8');
  console.log(chalk.green(`✓ Design inspirations saved: ${designPath}`));
}

// Create initialization marker
function createInitMarker(targetDir) {
  const markerPath = path.join(targetDir, '.spec-flow', 'memory', '.initialized');
  const content = `Initialized: ${getCurrentDate()}\n`;
  fs.writeFileSync(markerPath, content, 'utf8');
}

// Main configuration flow
async function configure(targetDir) {
  if (!targetDir) {
    targetDir = process.cwd();
  }

  // Check if .spec-flow exists
  const specFlowDir = path.join(targetDir, '.spec-flow');
  if (!fs.existsSync(specFlowDir)) {
    console.error(chalk.red('\n✗ Error: .spec-flow directory not found.'));
    console.log(chalk.gray('  Run ' + chalk.green('spec-flow init') + ' first to install Spec-Flow.\n'));
    process.exit(1);
  }

  // Check if already initialized
  const markerPath = path.join(targetDir, '.spec-flow', 'memory', '.initialized');
  if (fs.existsSync(markerPath)) {
    const resetAnswer = await inquirer.prompt([{
      type: 'list',
      name: 'action',
      message: 'Existing configuration detected. What would you like to do?',
      choices: [
        { name: 'Update configuration (keeps existing, prompts for changes)', value: 'update' },
        { name: 'Reset configuration (clears all, starts fresh)', value: 'reset' },
        { name: 'Cancel', value: 'cancel' }
      ]
    }]);

    if (resetAnswer.action === 'cancel') {
      console.log(chalk.yellow('\nConfiguration cancelled.\n'));
      process.exit(0);
    }

    if (resetAnswer.action === 'update') {
      console.log(chalk.yellow('\nUpdate mode not yet implemented. Use reset to reconfigure.\n'));
      process.exit(0);
    }
  }

  console.log(chalk.cyan.bold('\n╔═══════════════════════════════════════════════════════════════════╗'));
  console.log(chalk.cyan.bold('║                                                                   ║'));
  console.log(chalk.cyan.bold('║            Spec-Flow Interactive Configuration                    ║'));
  console.log(chalk.cyan.bold('║                                                                   ║'));
  console.log(chalk.cyan.bold('╚═══════════════════════════════════════════════════════════════════╝\n'));

  console.log(chalk.white('This wizard will configure:'));
  console.log(chalk.white('  1. Engineering Constitution (standards & principles)'));
  console.log(chalk.white('  2. Product Roadmap (features & priorities)'));
  console.log(chalk.white('  3. Design Inspirations (visual references)\n'));

  // Constitution
  const constitutionAnswers = await configureConstitution();
  generateConstitution(constitutionAnswers, targetDir);

  // Roadmap
  const roadmapFeatures = await configureRoadmap();
  generateRoadmap(roadmapFeatures, targetDir);

  // Design Inspirations
  const designInspirations = await configureDesignInspirations();
  generateDesignInspirations(designInspirations, targetDir);

  // Create marker
  createInitMarker(targetDir);

  // Summary
  console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
  console.log(chalk.cyan.bold(' Configuration Complete!'));
  console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));

  console.log(chalk.green('✓ Engineering Constitution configured'));
  console.log(chalk.white(`  - Project Type: ${constitutionAnswers.projectType}`));
  console.log(chalk.white(`  - Test Coverage: ${constitutionAnswers.coverage}%`));

  console.log(chalk.green(`\n✓ Product Roadmap configured`));
  console.log(chalk.white(`  - Features Added: ${roadmapFeatures.length}`));
  if (roadmapFeatures.length > 0) {
    const top3 = roadmapFeatures.slice(0, 3);
    console.log(chalk.white('\n  Top Features by ICE Score:'));
    top3.forEach((f, i) => {
      console.log(chalk.gray(`    ${i + 1}. ${f.slug} (Score: ${f.score})`));
    });
  }

  console.log(chalk.green(`\n✓ Design Inspirations configured`));
  console.log(chalk.white(`  - Inspirations Added: ${designInspirations.length}`));

  console.log(chalk.cyan('\n\nNext Steps:'));
  console.log(chalk.white('  1. Open your project in Claude Code'));
  console.log(chalk.white('  2. Review the generated files:'));
  console.log(chalk.gray('     - .spec-flow/memory/constitution.md'));
  console.log(chalk.gray('     - .spec-flow/memory/roadmap.md'));
  console.log(chalk.gray('     - .spec-flow/memory/design-inspirations.md'));
  console.log(chalk.white('  3. Start building features:'));
  console.log(chalk.green('     /spec-flow "feature-name"'));
  console.log(chalk.gray('     (Or use a slug from your roadmap)\n'));
}

// Export for use in other scripts
module.exports = { configure };

// Run if called directly
if (require.main === module) {
  const targetDir = process.argv[2] || process.cwd();
  configure(targetDir).catch(err => {
    console.error(chalk.red('\n✗ Configuration failed:'), err.message);
    process.exit(1);
  });
}
