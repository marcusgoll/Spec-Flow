# Error Scenario Testing

**Purpose**: Test error handling and edge cases.

---

## Common Error Scenarios

### 1. Invalid Input
```
Test: Enter invalid email "notanemail"
Expected: Error message "Please enter valid email"
```

### 2. Network Failure
```
Test: Disconnect network, submit form
Expected: Error message "Network error, please try again"
```

### 3. Not Found
```
Test: Navigate to /student/99999 (non-existent)
Expected: 404 page or "Student not found" message
```

### 4. Unauthorized
```
Test: Access protected page without login
Expected: Redirect to login page
```

---

## Checklist

- [ ] Validation errors shown clearly
- [ ] Network errors handled gracefully
- [ ] 404/403 errors have user-friendly messages
- [ ] Error recovery possible (retry buttons)

**See [../reference.md](../reference.md#error-scenarios) for complete list**
