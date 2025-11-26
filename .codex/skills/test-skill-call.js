#!/usr/bin/env node

/**
 * Quick harness to prove skills can be located via skills-index.yaml
 * and loaded from .codex/skills on demand.
 */

const fs = require('fs');
const path = require('path');
const { parseFrontmatter } = require('./export-skills');

const skillsDir = __dirname;
const indexPath = path.join(skillsDir, 'skills-index.yaml');

function parseSkillsIndex(raw) {
  const entries = [];
  const lines = raw.split(/\r?\n/);
  let current = null;

  lines.forEach((line) => {
    const fileMatch = line.match(/^\s*-\s+file:\s+(.+)\s*$/);
    if (fileMatch) {
      if (current) entries.push(current);
      current = { file: fileMatch[1].trim(), meta: {} };
      return;
    }

    if (!current) {
      return;
    }

    const metaMatch = line.match(/^\s{2,}([A-Za-z0-9_-]+):\s*(.*)$/);
    if (metaMatch) {
      const [, key, value] = metaMatch;
      current.meta[key] = value.trim();
    }
  });

  if (current) {
    entries.push(current);
  }

  return entries;
}

function stripFrontmatter(content) {
  return content.replace(/^---[\s\S]*?---\s*/, '').trim();
}

function loadSkillEntry(entries, target) {
  const lowerTarget = target.toLowerCase();
  return entries.find((entry) => {
    const metaName = (entry.meta.name || '').toLowerCase();
    const fileBase = path.basename(entry.file, path.extname(entry.file)).toLowerCase();
    return metaName === lowerTarget || fileBase === lowerTarget;
  });
}

function list(entries) {
  console.log('Available skills (from skills-index.yaml):');
  entries.forEach((entry) => {
    const name = entry.meta.name || path.basename(entry.file, path.extname(entry.file));
    const desc = entry.meta.description || '';
    console.log(`- ${name}${desc ? ` — ${desc}` : ''}`);
  });
}

function main() {
  const arg = process.argv[2];

  if (!fs.existsSync(indexPath)) {
    console.error(`Missing skills index at ${indexPath}. Run "node .codex/skills/export-skills.js" first.`);
    process.exit(1);
  }

  const entries = parseSkillsIndex(fs.readFileSync(indexPath, 'utf8'));

  if (!arg || arg === '--help' || arg === '-h') {
    console.log('Usage: node .codex/skills/test-skill-call.js <skill-name>|--list');
    return;
  }

  if (arg === '--list') {
    list(entries);
    return;
  }

  const entry = loadSkillEntry(entries, arg);
  if (!entry) {
    console.error(`Skill "${arg}" not found in skills-index.yaml. Use --list to see available skills.`);
    process.exit(1);
  }

  const skillPath = path.join(skillsDir, entry.file);
  if (!fs.existsSync(skillPath)) {
    console.error(`Skill file missing: ${skillPath}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(skillPath, 'utf8');
  const frontmatter = parseFrontmatter(raw) || {};
  const body = stripFrontmatter(raw);
  const preview = body.split(/\r?\n/).filter(Boolean).slice(0, 20).join('\n');

  console.log(`Loaded skill "${frontmatter.name || arg}" from ${skillPath}`);
  if (frontmatter.description) {
    console.log(`Description: ${frontmatter.description}`);
  }
  console.log('Preview (first 20 non-empty lines):');
  console.log('---');
  console.log(preview);
  console.log('---');
}

main();
