const assert = require('assert/strict');
const fs = require('fs');
const path = require('path');
const { execFileSync, spawnSync } = require('child_process');

const root = path.resolve(__dirname, '..');
const scratchParent = path.join(root, 'node_modules');
const scratch = fs.mkdtempSync(path.join(scratchParent, '.spec-flow-package-'));

function run(file, args, options = {}) {
  const result = spawnSync(file, args, {
    cwd: root, encoding: 'utf8', timeout: 60000, ...options,
  });
  assert.equal(result.status, 0, result.error?.message || result.stderr || result.stdout);
  return result.stdout;
}

try {
  run(process.execPath, ['scripts/build-dist.js']);
  assert(process.env.npm_execpath, 'Run this check with npm run test:package');
  const [packed] = JSON.parse(run(process.execPath, [process.env.npm_execpath,
    'pack', '--ignore-scripts', '--json', '--pack-destination', scratch]));
  assert(packed.files.some(file => file.path === 'dist/.codex/commands/core/feature.md'),
    'The npm package must include the Codex feature command');
  execFileSync('tar', ['-xzf', path.join(scratch, packed.filename), '-C', scratch]);

  const packageDir = path.join(scratch, 'package');
  const cli = path.join(packageDir, 'bin', 'cli.js');
  const consumer = path.join(scratch, 'consumer with spaces');
  const codexHome = path.join(scratch, 'isolated-codex');
  const prompts = path.join(codexHome, 'prompts');
  fs.mkdirSync(consumer);
  const options = { cwd: consumer, env: { ...process.env, CODEX_HOME: codexHome, CI: 'true' } };

  const dryRun = run(process.execPath, [cli, 'install-codex-prompts', '--dry-run'], options);
  assert(dryRun.includes('feature.md') && dryRun.includes('plan.md'));
  assert(!fs.existsSync(codexHome), 'Dry run must not create the Codex directory');

  run(process.execPath, [cli, 'install-codex-prompts'], options);
  for (const [name, source] of [['feature', 'core/feature'], ['plan', 'phases/plan'],
    ['validate', 'phases/validate']]) {
    assert.equal(fs.readFileSync(path.join(prompts, `${name}.md`), 'utf8'),
      fs.readFileSync(path.join(root, '.codex/commands', `${source}.md`), 'utf8'));
  }
  assert(!fs.existsSync(path.join(prompts, 'README.md')), 'Reference docs are not commands');
  assert(!fs.existsSync(path.join(prompts, 'CODEX_COMPATIBILITY.md')));

  const feature = path.join(prompts, 'feature.md');
  fs.writeFileSync(feature, 'user-owned prompt');
  run(process.execPath, [cli, 'install-codex-prompts', '--dry-run', '--force'], options);
  assert.equal(fs.readFileSync(feature, 'utf8'), 'user-owned prompt');
  const declineHome = path.join(scratch, 'decline-codex');
  fs.mkdirSync(path.join(declineHome, 'prompts'), { recursive: true });
  const declinedFeature = path.join(declineHome, 'prompts/feature.md');
  fs.writeFileSync(declinedFeature, 'user-owned prompt');
  const declined = run(process.execPath, [cli, 'install-codex-prompts'], {
    ...options, input: 'n\n', env: { ...options.env, CODEX_HOME: declineHome },
  });
  assert(declined.includes('skipped'));
  assert.equal(fs.readFileSync(declinedFeature, 'utf8'), 'user-owned prompt');
  run(process.execPath, [cli, 'install-codex-prompts', '--force'], options);
  assert.equal(fs.readFileSync(feature, 'utf8'),
    fs.readFileSync(path.join(root, '.codex/commands/core/feature.md'), 'utf8'));

  const projectGuidance = path.join(consumer, '.codex/Agents.md');
  fs.mkdirSync(path.dirname(projectGuidance), { recursive: true });
  fs.writeFileSync(projectGuidance, 'user-owned project guidance');
  run(process.execPath, [cli, 'init', '--target', consumer, '--non-interactive'], options);
  assert.equal(fs.readFileSync(projectGuidance, 'utf8'), 'user-owned project guidance');
  assert(fs.existsSync(path.join(consumer, '.codex/skills/test-skill-call.js')));
  assert(fs.existsSync(path.join(consumer, '.codex/commands/CODEX_COMPATIBILITY.md')));
  assert(fs.existsSync(path.join(consumer, '.spec-flow/scripts/spec-cli.py')));

  const projectFeature = path.join(consumer, '.codex/commands/core/feature.md');
  fs.writeFileSync(projectFeature, 'customized project command');
  fs.unlinkSync(path.join(consumer, '.codex/commands/phases/plan.md'));
  run(process.execPath, [cli, 'update', '--target', consumer, '--skip-hooks'], options);
  assert.equal(fs.readFileSync(projectGuidance, 'utf8'), 'user-owned project guidance');
  assert.equal(fs.readFileSync(projectFeature, 'utf8'), 'customized project command');
  assert(fs.existsSync(path.join(consumer, '.codex/commands/phases/plan.md')),
    'Update must still install missing Codex files');

  const duplicate = path.join(packageDir, 'dist/.codex/commands/phases/feature.md');
  fs.writeFileSync(duplicate, 'conflicting command');
  const conflictHome = path.join(scratch, 'conflict-codex');
  const conflict = spawnSync(process.execPath, [cli, 'install-codex-prompts', '--force'], {
    ...options, encoding: 'utf8', timeout: 10000,
    env: { ...options.env, CODEX_HOME: conflictHome },
  });
  assert.equal(conflict.status, 1);
  assert.match(conflict.stdout + conflict.stderr, /Duplicate prompt/);
  assert(!fs.existsSync(conflictHome), 'A naming conflict must fail before any writes');
  console.log('PASS: packed Codex commands, project support files, dry run, conflicts, and overwrite choices');
} finally {
  assert.equal(path.dirname(path.resolve(scratch)), scratchParent);
  assert(path.basename(scratch).startsWith('.spec-flow-package-'));
  fs.rmSync(scratch, { recursive: true, force: true });
}
