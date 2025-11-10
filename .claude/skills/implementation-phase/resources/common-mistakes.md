# Common Mistakes

## 🚫 Implementation Without Tests (Skipping RED Phase)

**Bad**:
```python
# Write implementation first
class StudentProgressService:
    def calculate_progress(self, completed, total):
        return (completed / total) * 100

# Then write test
def test_calculate_progress():  # Test after code!
    assert service.calculate_progress(7, 10) == 70
```

**Good**:
```python
# Write test first (RED)
def test_calculate_progress():
    assert service.calculate_progress(7, 10) == 70  # Fails initially

# Then implement (GREEN)
class StudentProgressService:
    def calculate_progress(self, completed, total):
        return (completed / total) * 100  # Test now passes
```

---

## 🚫 Duplicate Code Written

**Problem**: Not searching before writing

**Solution**: Always grep for similar code first
```bash
grep -r "similar_function_name" src/
```

---

## 🚫 Large Commits Without Context

**Bad**:
```bash
git commit -m "changes"  # 50 files changed
```

**Good**:
```bash
git commit -m "feat: add student progress calculation (T008-T010)"  # 3 files
```

**See [../reference.md](../reference.md#common-mistakes) for complete list**
