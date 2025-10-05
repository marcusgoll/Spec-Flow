#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = process.cwd();
const owner = (process.env.GITHUB_REPOSITORY_OWNER || '').trim();
if (!owner) {
  throw new Error('GITHUB_REPOSITORY_OWNER environment variable is required to scope the package name.');
}

const pkgPath = path.join(root, 'package.json');
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));

const scopedName = `@${owner}/${pkg.name}`;
const distDir = path.join(root, 'dist', 'github-package');
fs.rmSync(distDir, { recursive: true, force: true });
fs.mkdirSync(distDir, { recursive: true });

const githubPkg = { ...pkg, name: scopedName };
fs.writeFileSync(path.join(distDir, 'package.json'), JSON.stringify(githubPkg, null, 2));

const copyEntry = (entry) => {
  const src = path.join(root, entry);
  const dest = path.join(distDir, entry);
  if (!fs.existsSync(src)) {
    console.warn(`[prepare-github-package] Skipping missing entry: ${entry}`);
    return;
  }
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.cpSync(src, dest, { recursive: true });
};

const files = Array.isArray(pkg.files) ? pkg.files : [];
files.forEach(copyEntry);

// Always include README and LICENSE to maximise metadata, even if not listed.
['README.md', 'LICENSE'].forEach((entry) => {
  if (!files.includes(entry)) {
    copyEntry(entry);
  }
});

console.log(`[prepare-github-package] Prepared GitHub package in ${distDir} with name ${scopedName}`);
