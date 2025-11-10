# Anti-Duplication Checks

## Search Before Writing

**Always search for existing code before writing new code:**

```bash
# Search for similar function names
grep -r "functionName" src/

# Search for similar logic patterns
grep -r "specificLogicPattern" src/

# Search for similar imports
grep -r "import.*PackageName" src/
```

---

## DRY Checklist

Before writing any function/class/component:

- [ ] Search codebase for similar names
- [ ] Search for similar logic patterns
- [ ] Check if utility already exists
- [ ] Review plan.md for reuse opportunities
- [ ] Grep for similar imports

---

## Common Duplication Patterns

### Pattern 1: Duplicate Utility Functions

**Bad** (duplication):
```python
# services/user.py
def format_phone(phone):
    return phone.replace("-", "")

# services/order.py
def format_phone(phone):  # DUPLICATE!
    return phone.replace("-", "")
```

**Good** (reuse):
```python
# utils/formatters.py
def format_phone(phone):
    return phone.replace("-", "")

# services/user.py
from utils.formatters import format_phone

# services/order.py
from utils.formatters import format_phone  # REUSE!
```

### Pattern 2: Duplicate Validation Logic

**Search first**:
```bash
grep -r "email.*validation" src/
# Found: utils/validators.py already has email validation!
```

**Reuse**:
```python
from utils.validators import validate_email  # Don't recreate!
```

---

**See [../reference.md](../reference.md#anti-duplication) for complete patterns**
