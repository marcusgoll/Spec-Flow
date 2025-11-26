#!/usr/bin/env node

/**
 * generate skills-index.yaml from every skill Markdown file.
 * Expected frontmatter format:
 * ---
 * name: My Skill
 * capability: planning
 * ---
 */

const fs = require('fs');
const path = require('path');

const skillsDir = __dirname;
const outputPath = path.join(skillsDir, 'skills-index.yaml');

function parseFrontmatter(content) {
  const match = content.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!match) {
    return null;
  }

  const body = match[1].trim();
  const data = {};

  body.split('\n').forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) {
      return;
    }

    const [key, ...rest] = trimmed.split(':');
    if (!key || rest.length === 0) {
      return;
    }

    data[key.trim()] = rest.join(':').trim();
  });

  return data;
}

function formatValue(value, indent = '    ') {
  if (value === undefined || value === null) {
    return 'null';
  }

  if (Array.isArray(value)) {
    if (value.length === 0) {
      return '[]';
    }
    const inner = value.map((item) => `\n${indent}- ${item}`).join('');
    return inner;
  }

  return JSON.stringify(value).replace(/^"|"$/g, '');
}

function toYaml(entries) {
  let output = 'skills:\n';
  entries.forEach((entry) => {
    output += '  - file: ' + entry.file + '\n';
    Object.entries(entry.frontmatter).forEach(([key, value]) => {
      output += `    ${key}: ${formatValue(value)}\n`;
    });
  });

  if (entries.length === 0) {
    output += '  []\n';
  }

  return output;
}

function walk(dir) {
  const entries = [];
  const children = fs.readdirSync(dir, { withFileTypes: true });

  children.forEach((child) => {
    const fileName = child.name;
    const fullPath = path.join(dir, fileName);

    if (child.isDirectory()) {
      entries.push(...walk(fullPath));
      return;
    }

    if (!child.isFile()) {
      return;
    }

    const lower = fileName.toLowerCase();
    if (!lower.endsWith('.md')) {
      return;
    }

    if (['readme.md', 'agents.md'].includes(lower)) {
      return;
    }

    entries.push(fullPath);
  });

  return entries;
}

function main() {
  const files = walk(skillsDir);

  const entries = files
    .map((filePath) => {
      const content = fs.readFileSync(filePath, 'utf8');
      const frontmatter = parseFrontmatter(content);
      return {
        file: path.relative(skillsDir, filePath).replace(/\\/g, '/'),
        frontmatter,
      };
    })
    .filter(({ frontmatter }) => Boolean(frontmatter));

  const yaml = toYaml(entries);
  fs.writeFileSync(outputPath, yaml);

  console.log(`Generated ${outputPath} (${entries.length} skill${entries.length === 1 ? '' : 's'})`);
}

if (require.main === module) {
  main();
}

module.exports = {
  parseFrontmatter,
  toYaml,
};
