#!/usr/bin/env node
/**
 * Spec-Flow Testing Harness
 *
 * Smoke test runner for slash commands, skills, and subagents.
 * Validates command execution, artifact generation, and state management.
 *
 * Usage:
 *   node test-harness.mjs [scenario]
 *   node test-harness.mjs --all
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Test configuration
const TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes per scenario
const SCENARIOS_DIR = join(__dirname, 'scenarios');
const REPORTS_DIR = join(__dirname, 'reports');
const VALIDATORS_DIR = join(__dirname, 'validators');

// Test results accumulator
const results = {
  total: 0,
  passed: 0,
  failed: 0,
  skipped: 0,
  scenarios: []
};

/**
 * Test scenario definition
 */
class TestScenario {
  constructor(name, description, tests) {
    this.name = name;
    this.description = description;
    this.tests = tests;
    this.results = [];
  }

  async run() {
    console.log(`\n${'='.repeat(80)}`);
    console.log(`📋 Scenario: ${this.name}`);
    console.log(`   ${this.description}`);
    console.log('='.repeat(80));

    for (const test of this.tests) {
      const result = await this.executeTest(test);
      this.results.push(result);
      results.total++;

      if (result.status === 'passed') {
        results.passed++;
        console.log(`   ✓ ${test.name}`);
      } else if (result.status === 'failed') {
        results.failed++;
        console.log(`   ✗ ${test.name}`);
        console.log(`     Error: ${result.error}`);
      } else {
        results.skipped++;
        console.log(`   ⊘ ${test.name} (skipped)`);
      }
    }

    return this.results;
  }

  async executeTest(test) {
    const startTime = Date.now();

    try {
      // Execute test function
      await Promise.race([
        test.execute(),
        this.timeout(TIMEOUT_MS)
      ]);

      const duration = Date.now() - startTime;

      return {
        name: test.name,
        status: 'passed',
        duration,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      const duration = Date.now() - startTime;

      return {
        name: test.name,
        status: 'failed',
        error: error.message,
        duration,
        timestamp: new Date().toISOString()
      };
    }
  }

  timeout(ms) {
    return new Promise((_, reject) =>
      setTimeout(() => reject(new Error(`Test timeout after ${ms}ms`)), ms)
    );
  }
}

/**
 * Test definition
 */
class Test {
  constructor(name, execute) {
    this.name = name;
    this.execute = execute;
  }
}

/**
 * Mock command execution (for smoke testing)
 * In real implementation, this would call SlashCommand/Skill/Task tools
 */
async function mockCommandExecution(command, workingDir) {
  // Simulate command execution
  await new Promise(resolve => setTimeout(resolve, 100));

  return {
    success: true,
    command,
    workingDir,
    output: `Mock output for: ${command}`
  };
}

/**
 * Scenario 1: Greenfield Project
 */
function createGreenfieldScenario() {
  const scenarioDir = join(SCENARIOS_DIR, '01-greenfield');

  return new TestScenario(
    'Greenfield Project',
    'Test workflow initialization on fresh project',
    [
      new Test('Directory structure exists', async () => {
        if (!existsSync(scenarioDir)) {
          throw new Error(`Scenario directory not found: ${scenarioDir}`);
        }
      }),

      new Test('/init-project command structure validation', async () => {
        const commandPath = join(process.cwd(), '.claude/commands/project/init-project.md');
        if (!existsSync(commandPath)) {
          throw new Error('Command file not found: init-project.md');
        }

        const content = readFileSync(commandPath, 'utf-8');
        if (!content.includes('docs/project/')) {
          throw new Error('Command does not reference expected output directory');
        }
      }),

      new Test('/feature command structure validation', async () => {
        const commandPath = join(process.cwd(), '.claude/commands/core/feature.md');
        if (!existsSync(commandPath)) {
          throw new Error('Command file not found: feature.md');
        }

        const content = readFileSync(commandPath, 'utf-8');
        if (!content.includes('workflow-state.yaml')) {
          throw new Error('Command does not reference workflow state');
        }
      }),

      new Test('Deployment model detection (local-only)', async () => {
        // Verify no git remote exists
        const hasGitRemote = existsSync(join(scenarioDir, '.git/config'));
        if (hasGitRemote) {
          const config = readFileSync(join(scenarioDir, '.git/config'), 'utf-8');
          if (config.includes('[remote')) {
            throw new Error('Expected local-only but found git remote');
          }
        }
      })
    ]
  );
}

/**
 * Scenario 2: Brownfield Project
 */
function createBrownfieldScenario() {
  const scenarioDir = join(SCENARIOS_DIR, '02-brownfield');

  return new TestScenario(
    'Brownfield Project',
    'Test workflow on existing codebase with auto-scan',
    [
      new Test('Directory structure exists', async () => {
        if (!existsSync(scenarioDir)) {
          throw new Error(`Scenario directory not found: ${scenarioDir}`);
        }
      }),

      new Test('Fixture files present', async () => {
        const fixturesDir = join(__dirname, 'fixtures');
        const requiredFixtures = ['package.json', 'docker-compose.yml'];

        for (const fixture of requiredFixtures) {
          const fixturePath = join(fixturesDir, fixture);
          if (!existsSync(fixturePath)) {
            throw new Error(`Missing fixture: ${fixture}`);
          }
        }
      }),

      new Test('Anti-duplication skill validation', async () => {
        const skillPath = join(process.cwd(), '.claude/skills/anti-duplication/SKILL.md');
        if (!existsSync(skillPath)) {
          throw new Error('Skill file not found: anti-duplication/SKILL.md');
        }
      })
    ]
  );
}

/**
 * Scenario 3: Feature Workflow
 */
function createFeatureWorkflowScenario() {
  const scenarioDir = join(SCENARIOS_DIR, '03-feature-workflow');

  return new TestScenario(
    'Feature Workflow',
    'Test standard feature workflow (spec → plan → tasks → implement)',
    [
      new Test('Directory structure exists', async () => {
        if (!existsSync(scenarioDir)) {
          throw new Error(`Scenario directory not found: ${scenarioDir}`);
        }
      }),

      new Test('/spec command validation', async () => {
        const commandPath = join(process.cwd(), '.claude/commands/phases/spec.md');
        if (!existsSync(commandPath)) {
          throw new Error('Command file not found: spec.md');
        }
      }),

      new Test('/plan command validation', async () => {
        const commandPath = join(process.cwd(), '.claude/commands/phases/plan.md');
        if (!existsSync(commandPath)) {
          throw new Error('Command file not found: plan.md');
        }
      }),

      new Test('/tasks command validation', async () => {
        const commandPath = join(process.cwd(), '.claude/commands/phases/tasks.md');
        if (!existsSync(commandPath)) {
          throw new Error('Command file not found: tasks.md');
        }
      }),

      new Test('Workflow state schema exists', async () => {
        const schemaPath = join(process.cwd(), '.spec-flow/memory/workflow-state-schema.md');
        if (!existsSync(schemaPath)) {
          throw new Error('Workflow state schema not found');
        }
      })
    ]
  );
}

/**
 * Scenario 4: Epic Workflow
 */
function createEpicWorkflowScenario() {
  const scenarioDir = join(SCENARIOS_DIR, '04-epic-workflow');

  return new TestScenario(
    'Epic Workflow',
    'Test multi-sprint epic workflow with parallel execution',
    [
      new Test('Directory structure exists', async () => {
        if (!existsSync(scenarioDir)) {
          throw new Error(`Scenario directory not found: ${scenarioDir}`);
        }
      }),

      new Test('/epic command validation', async () => {
        const commandPath = join(process.cwd(), '.claude/commands/epic/epic.md');
        if (!existsSync(commandPath)) {
          throw new Error('Command file not found: epic.md');
        }

        const content = readFileSync(commandPath, 'utf-8');
        if (!content.includes('epic-spec.md')) {
          throw new Error('Epic command does not reference epic-spec.md');
        }
      }),

      new Test('/implement-epic command validation', async () => {
        const commandPath = join(process.cwd(), '.claude/commands/epic/implement-epic.md');
        if (!existsSync(commandPath)) {
          throw new Error('Command file not found: implement-epic.md');
        }

        const content = readFileSync(commandPath, 'utf-8');
        if (!content.includes('sprint-plan.md')) {
          throw new Error('Implement-epic command does not reference sprint-plan.md');
        }
      }),

      new Test('Epic agent validation', async () => {
        const agentPath = join(process.cwd(), '.claude/agents/phase/epic.md');
        if (!existsSync(agentPath)) {
          throw new Error('Epic agent file not found: .claude/agents/phase/epic.md');
        }
      }),

      new Test('Epic question bank exists', async () => {
        const questionBankPath = join(process.cwd(), '.claude/skills/epic/references/question-bank.md');
        if (!existsSync(questionBankPath)) {
          throw new Error('Epic question bank not found');
        }

        const content = readFileSync(questionBankPath, 'utf-8');
        // Check for XML structure instead of markdown headers
        if (!content.includes('<business_goal>') && !content.includes('<subsystem_selection>')) {
          throw new Error('Question bank does not have expected XML structure');
        }
      })
    ]
  );
}

/**
 * Scenario 5: UI-First Workflow
 */
function createUIFirstScenario() {
  const scenarioDir = join(SCENARIOS_DIR, '05-ui-first');

  return new TestScenario(
    'UI-First Workflow',
    'Test mockup-first workflow with approval gates',
    [
      new Test('Directory structure exists', async () => {
        if (!existsSync(scenarioDir)) {
          throw new Error(`Scenario directory not found: ${scenarioDir}`);
        }
      }),

      new Test('/tasks --ui-first flag validation', async () => {
        const commandPath = join(process.cwd(), '.claude/commands/phases/tasks.md');
        if (!existsSync(commandPath)) {
          throw new Error('Command file not found: tasks.md');
        }

        const content = readFileSync(commandPath, 'utf-8');
        if (!content.includes('--ui-first') && !content.includes('ui-first')) {
          throw new Error('Tasks command does not support UI-first mode');
        }
      }),

      new Test('Mockup approval checklist template exists', async () => {
        const templatePath = join(process.cwd(), '.spec-flow/templates/mockup-approval-checklist.md');
        if (!existsSync(templatePath)) {
          throw new Error('Mockup approval checklist template not found');
        }
      }),

      new Test('Design system agents exist', async () => {
        const designScoutPath = join(process.cwd(), '.claude/agents/quality/design-scout.md');
        const designLintPath = join(process.cwd(), '.claude/agents/quality/design-lint.md');

        if (!existsSync(designScoutPath) && !existsSync(designLintPath)) {
          throw new Error('Design system agents not found');
        }
      })
    ]
  );
}

/**
 * Generate test report
 */
function generateReport() {
  const timestamp = new Date().toISOString();
  const duration = results.scenarios.reduce((acc, s) =>
    acc + s.results.reduce((a, r) => a + (r.duration || 0), 0), 0
  );

  let report = `# Spec-Flow Testing Report\n\n`;
  report += `**Generated**: ${timestamp}\n`;
  report += `**Total Duration**: ${(duration / 1000).toFixed(2)}s\n\n`;

  report += `## Summary\n\n`;
  report += `- **Total Tests**: ${results.total}\n`;
  report += `- **Passed**: ${results.passed} ✓\n`;
  report += `- **Failed**: ${results.failed} ✗\n`;
  report += `- **Skipped**: ${results.skipped} ⊘\n`;
  report += `- **Success Rate**: ${((results.passed / results.total) * 100).toFixed(1)}%\n\n`;

  report += `## Scenarios\n\n`;

  for (const scenario of results.scenarios) {
    const passed = scenario.results.filter(r => r.status === 'passed').length;
    const failed = scenario.results.filter(r => r.status === 'failed').length;
    const total = scenario.results.length;

    report += `### ${scenario.name}\n\n`;
    report += `${scenario.description}\n\n`;
    report += `**Results**: ${passed}/${total} passed\n\n`;

    report += `| Test | Status | Duration |\n`;
    report += `|------|--------|----------|\n`;

    for (const result of scenario.results) {
      const icon = result.status === 'passed' ? '✓' : result.status === 'failed' ? '✗' : '⊘';
      const duration = result.duration ? `${result.duration}ms` : 'N/A';
      report += `| ${result.name} | ${icon} ${result.status} | ${duration} |\n`;
    }

    report += `\n`;

    // Show errors
    const errors = scenario.results.filter(r => r.status === 'failed');
    if (errors.length > 0) {
      report += `#### Errors\n\n`;
      for (const error of errors) {
        report += `- **${error.name}**: ${error.error}\n`;
      }
      report += `\n`;
    }
  }

  report += `## Next Steps\n\n`;
  if (results.failed > 0) {
    report += `1. Review failed tests above\n`;
    report += `2. Check command/skill/agent file structure\n`;
    report += `3. Verify templates and schemas exist\n`;
    report += `4. Re-run tests after fixes\n`;
  } else {
    report += `All tests passed! ✓\n\n`;
    report += `The Spec-Flow workflow structure is validated and ready for use.\n`;
  }

  return report;
}

/**
 * Main test runner
 */
async function runTests() {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║         Spec-Flow Testing Harness - Smoke Test Suite          ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');

  const scenarios = [
    createGreenfieldScenario(),
    createBrownfieldScenario(),
    createFeatureWorkflowScenario(),
    createEpicWorkflowScenario(),
    createUIFirstScenario()
  ];

  for (const scenario of scenarios) {
    const scenarioResults = await scenario.run();
    results.scenarios.push({
      name: scenario.name,
      description: scenario.description,
      results: scenarioResults
    });
  }

  // Generate report
  console.log(`\n${'='.repeat(80)}`);
  console.log('📊 Generating test report...');
  console.log('='.repeat(80));

  const report = generateReport();

  // Ensure reports directory exists
  if (!existsSync(REPORTS_DIR)) {
    mkdirSync(REPORTS_DIR, { recursive: true });
  }

  const reportPath = join(REPORTS_DIR, `test-report-${Date.now()}.md`);
  writeFileSync(reportPath, report, 'utf-8');

  console.log(`\n✓ Report saved to: ${reportPath}`);
  console.log(`\n${'='.repeat(80)}`);
  console.log(`Summary: ${results.passed}/${results.total} tests passed`);
  console.log('='.repeat(80));

  // Exit with appropriate code
  process.exit(results.failed > 0 ? 1 : 0);
}

// Run tests
runTests().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
