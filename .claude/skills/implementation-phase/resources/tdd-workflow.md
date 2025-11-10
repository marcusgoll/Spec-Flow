# TDD Workflow

## RED → GREEN → REFACTOR Cycle

### Phase 1: RED (Write Failing Test)

1. **Write test first** (before any implementation code)
2. **Test should fail** (if it passes, test is wrong)
3. **Test should be specific** (one behavior per test)

**Example**:
```python
def test_calculate_student_progress_returns_percentage():
    # Arrange
    service = StudentProgressService()

    # Act
    progress = service.calculate_progress(completed=7, total=10)

    # Assert
    assert progress == 70.0
```

### Phase 2: GREEN (Make Test Pass)

1. **Write minimal code** to make test pass
2. **Don't optimize yet** (that's refactor phase)
3. **Verify test passes**

**Example**:
```python
class StudentProgressService:
    def calculate_progress(self, completed: int, total: int) -> float:
        return (completed / total) * 100.0  # Minimal implementation
```

### Phase 3: REFACTOR (Clean Up Code)

1. **Remove duplication**
2. **Improve readability**
3. **Optimize performance** (if needed)
4. **Tests must still pass**

**Example**:
```python
class StudentProgressService:
    def calculate_progress(self, completed: int, total: int) -> float:
        if total == 0:
            raise ValueError("Total cannot be zero")
        return round((completed / total) * 100.0, 2)  # Improved with validation + rounding
```

---

## Task Triplets

Tasks should be grouped in triplets for TDD:
- **Task N**: Write test (RED)
- **Task N+1**: Implement (GREEN)
- **Task N+2**: Refactor (REFACTOR)

**See [../reference.md](../reference.md#tdd-workflow) for complete examples**
