# Python Dependency Conflict Patterns (pip/poetry)

## Common Conflict Scenarios

### 1. Incompatible Version Constraints

**Problem:**
```bash
pip install package-a package-b
# ERROR: Cannot install package-a and package-b because
# package-a requires numpy>=1.20.0
# package-b requires numpy<1.20.0
```

**Diagnosis:**
```bash
pip show numpy
pip list | grep numpy
pip check  # Verify dependency compatibility
```

**Resolution:**
```bash
# Option 1: Upgrade package-b if available
pip install --upgrade package-b
pip install package-a

# Option 2: Use version that satisfies both
pip install 'numpy==1.19.5' package-a package-b

# Option 3: Use constraints file
# Create constraints.txt:
numpy>=1.19.0,<1.21.0

pip install -c constraints.txt package-a package-b
```

### 2. Platform-Specific Wheel Issues

**Problem:**
```bash
pip install package-with-c-extension
# ERROR: Could not find a version that satisfies the requirement
# (Windows wheel not available for Python 3.11)
```

**Diagnosis:**
```bash
# Check available wheels
pip index versions package-name

# Check platform compatibility
python -c "import sysconfig; print(sysconfig.get_platform())"
```

**Resolution:**
```bash
# Option 1: Install compatible Python version
pyenv install 3.10
pyenv local 3.10

# Option 2: Install from source (requires build tools)
pip install --no-binary :all: package-name

# Option 3: Use conda (has prebuilt binaries)
conda install package-name

# Option 4: Wait for wheel release or use alternative package
```

### 3. Poetry Lock File Conflicts

**Problem:**
```bash
poetry add new-package
# ERROR: The current project's Python requirement (>=3.8,<3.11)
# is not compatible with new-package requires Python >=3.11
```

**Diagnosis:**
```bash
poetry show new-package
poetry show --tree
```

**Resolution:**
```bash
# Option 1: Update Python version constraint
# In pyproject.toml:
[tool.poetry.dependencies]
python = "^3.11"

poetry lock --no-update
poetry install

# Option 2: Find compatible version of new-package
poetry add "new-package<2.0"

# Option 3: Use different package
```

### 4. Conflicting Transitive Dependencies

**Problem:**
```bash
# package-a requires requests==2.28.0
# package-b requires requests>=2.29.0
```

**Diagnosis:**
```bash
# With pip
pip show requests
pipdeptree  # Visualize dependency tree

# With poetry
poetry show --tree
poetry show requests --tree
```

**Resolution:**
```bash
# With pip - use constraints
# constraints.txt:
requests>=2.29.0

pip install -c constraints.txt -r requirements.txt

# With poetry - update both packages
poetry update package-a package-b
poetry add "requests>=2.29.0"
```

## Security Vulnerability Patterns

### 1. Critical Vulnerability with pip-audit

**Scenario:**
```bash
pip-audit
# Found 1 known vulnerability in 1 package
# cryptography 38.0.0 -> GHSA-w7pp-m8wf-vj6r (HIGH)
# Fixed in: 38.0.4
```

**Resolution:**
```bash
# Option 1: Auto-fix with pip-audit
pip-audit --fix

# Option 2: Manual upgrade
pip install --upgrade cryptography

# Option 3: Pin fixed version
echo "cryptography>=38.0.4" >> requirements.txt
pip install -r requirements.txt

# With poetry
poetry add "cryptography>=38.0.4"
poetry update cryptography
```

### 2. Vulnerability in Transitive Dependency

**Scenario:**
```bash
pip-audit
# django 4.0.0 depends on sqlparse 0.4.2 (vulnerable)
```

**Resolution:**
```bash
# Check if Django update fixes it
pip index versions django

# Force sqlparse upgrade
pip install 'sqlparse>=0.4.4'

# With poetry - add explicit dependency
poetry add "sqlparse>=0.4.4"
```

### 3. No Patch Available

**Scenario:**
```bash
pip-audit
# Found vulnerability in unmaintained-package
# No fix available
```

**Resolution:**
```bash
# 1. Search for maintained fork or alternative
pip search "alternative to unmaintained-package"

# 2. Vendor the code (copy into your project)
# 3. Apply community patches manually
# 4. Use --ignore-vuln to suppress (document reason)
pip-audit --ignore-vuln GHSA-xxxx-xxxx-xxxx
```

## Version Management Best Practices

### Requirements File Strategies

**requirements.txt (pin exact versions for reproducibility):**
```txt
# Production dependencies - pinned
django==4.2.7
requests==2.31.0
psycopg2-binary==2.9.9

# Use pip-compile to generate from requirements.in
# requirements.in:
django>=4.2,<5.0
requests>=2.31.0
psycopg2-binary>=2.9

# Generate:
pip-compile requirements.in
```

**requirements-dev.txt (separate dev dependencies):**
```txt
-r requirements.txt
pytest>=7.4.0
black>=23.0.0
mypy>=1.7.0
```

**Using pip-tools for Dependency Management:**
```bash
# Install pip-tools
pip install pip-tools

# Create requirements.in with loose constraints
cat > requirements.in << EOF
django>=4.2
requests
EOF

# Compile to requirements.txt with exact pins
pip-compile requirements.in

# Upgrade dependencies
pip-compile --upgrade requirements.in

# Install compiled requirements
pip-sync requirements.txt
```

### Poetry Dependency Management

**pyproject.toml:**
```toml
[tool.poetry.dependencies]
python = "^3.11"
django = "^4.2"  # >=4.2.0, <5.0.0
requests = "^2.31.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.4"
black = "^23.0"

[tool.poetry.group.optional.dependencies]
redis = "^5.0"
```

**Version Constraint Syntax:**
```toml
# Caret (compatible updates)
package = "^1.2.3"  # >=1.2.3 <2.0.0

# Tilde (patch updates only)
package = "~1.2.3"  # >=1.2.3 <1.3.0

# Exact version
package = "1.2.3"

# Comparison operators
package = ">=1.2.3"
package = ">=1.2.3,<2.0.0"

# Wildcard
package = "1.2.*"  # Any patch version

# Git dependency
package = { git = "https://github.com/user/repo.git", branch = "main" }

# Local path
package = { path = "../local-package" }
```

## Diagnostic Commands Reference

### pip Commands

```bash
# Show package details
pip show package-name

# List installed packages
pip list
pip list --outdated

# Check for conflicts
pip check

# Verify installation without installing
pip install --dry-run package-name

# Download without installing (for inspection)
pip download package-name

# Show dependency tree (requires pipdeptree)
pip install pipdeptree
pipdeptree
pipdeptree -p package-name

# Security audit
pip install pip-audit
pip-audit
pip-audit --fix
pip-audit -r requirements.txt
```

### Poetry Commands

```bash
# Show package info
poetry show package-name
poetry show --tree
poetry show --latest

# Check for updates
poetry show --outdated

# Update dependencies
poetry update
poetry update package-name

# Add with specific version
poetry add "package-name>=1.2.3"

# Dry-run install
poetry install --dry-run

# Lock dependencies without updating
poetry lock --no-update

# Check lock file validity
poetry check

# Security audit (requires plugin)
poetry self add poetry-audit-plugin
poetry audit
```

## Troubleshooting Flowchart

```
Python dependency conflict?
│
├─ Version constraint conflict?
│  ├─ Check both packages for updates → Update to compatible versions
│  ├─ Use constraints file → Force specific version range
│  └─ Find alternative package → Replace incompatible dependency
│
├─ Python version incompatibility?
│  ├─ Upgrade Python → Use pyenv or conda
│  ├─ Downgrade package → Find version compatible with current Python
│  └─ Use different package → Find Python-version-compatible alternative
│
├─ Platform/wheel issue?
│  ├─ Install from source → Requires compiler and headers
│  ├─ Use conda → Has prebuilt binaries
│  └─ Wait for wheel release → Use alternative temporarily
│
└─ Security vulnerability?
   ├─ Patch available? → pip-audit --fix or manual upgrade
   ├─ Transitive dependency? → Add explicit constraint
   └─ No fix? → Find alternative or vendor code
```

## Real-World Examples

### Example 1: Django Upgrade with Dependency Conflicts

**Before:**
```toml
[tool.poetry.dependencies]
django = "3.2"
djangorestframework = "3.13"
celery = "5.2"
```

**Problem:**
```bash
poetry add "django>=4.2"
# ERROR: djangorestframework 3.13 requires django<4.0
```

**Resolution:**
```bash
# Check DRF compatibility
poetry show djangorestframework --latest

# Upgrade both together
poetry add "django>=4.2" "djangorestframework>=3.14"

# Update celery if needed
poetry update celery

# Test compatibility
poetry install
python manage.py check
```

### Example 2: NumPy Version Lock with Data Science Stack

**Problem:**
```bash
# pandas requires numpy>=1.20.0
# old-ml-library requires numpy<1.20.0
```

**Resolution:**
```bash
# Check if old-ml-library has updates
pip index versions old-ml-library

# Option 1: Update old-ml-library
pip install --upgrade old-ml-library pandas

# Option 2: Find numpy version that works for both
pip install 'numpy==1.19.5' pandas==1.3.5 old-ml-library

# Option 3: Replace old-ml-library with maintained alternative
pip uninstall old-ml-library
pip install modern-ml-library pandas
```

### Example 3: Poetry Lock Issues After Merge

**Problem:**
```bash
git merge feature-branch
poetry install
# ERROR: The lock file is not compatible with the current Python version
```

**Resolution:**
```bash
# Remove old lock file
rm poetry.lock

# Regenerate with current environment
poetry lock

# Install dependencies
poetry install

# Commit new lock file
git add poetry.lock
git commit -m "chore: regenerate poetry lock file"
```

### Example 4: Virtual Environment Conflicts

**Problem:**
Multiple projects with conflicting global dependencies

**Resolution:**
```bash
# Use separate virtual environments per project
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Or use poetry (creates venv automatically)
poetry install

# Or use pyenv + virtualenv
pyenv install 3.11.5
pyenv virtualenv 3.11.5 project-name
pyenv local project-name

# Or use conda
conda create -n project-name python=3.11
conda activate project-name
```

## Advanced Patterns

### Using Constraints for Monorepos

**constraints.txt (shared across services):**
```txt
# Shared constraints for monorepo
django>=4.2,<5.0
requests>=2.31.0
celery>=5.3.0
redis>=5.0.0
```

**Each service's requirements.in:**
```txt
-c ../constraints.txt
django
djangorestframework
celery
```

### Using pipenv for Dependency Locking

```bash
# Install pipenv
pip install pipenv

# Initialize project
pipenv install django requests

# Install dev dependencies
pipenv install --dev pytest black

# Generates Pipfile and Pipfile.lock

# Install from lock file (CI/CD)
pipenv install --deploy

# Update dependencies
pipenv update
```

### Using conda for Complex Dependencies

```bash
# Create environment from YAML
cat > environment.yml << EOF
name: myproject
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.11
  - numpy>=1.24
  - pandas>=2.0
  - scikit-learn
  - pip:
    - django>=4.2
    - requests
EOF

# Create environment
conda env create -f environment.yml

# Activate
conda activate myproject

# Export (with exact versions)
conda env export > environment-lock.yml
```
