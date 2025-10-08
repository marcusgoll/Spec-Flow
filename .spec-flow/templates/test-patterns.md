# Test Patterns for CFIPros

**Purpose**: Copy-paste templates for TDD workflow (RED → GREEN → REFACTOR)

**Guardrails:**
- Unit tests: <2s each
- Integration tests: <10s each
- Suite: <6 min total
- One behavior per test
- No snapshots, no prop-mirror tests

---

## Backend Tests (Python + pytest)

### Unit Test Template (Given-When-Then)

```python
import pytest
from app.models.message import Message, ValidationError

class TestMessageValidation:
    """Test suite for Message content validation"""

    def test_content_exceeding_max_length_raises_validation_error(self):
        # GIVEN: Content exceeding 4000 chars
        long_content = "x" * 4001

        # WHEN: Validating content
        with pytest.raises(ValidationError) as exc:
            Message.validate_content(long_content)

        # THEN: Validation error raised with specific message
        assert "exceeds maximum length" in str(exc.value)

    def test_empty_content_raises_validation_error(self):
        # GIVEN: Empty content
        # WHEN: Validating content
        # THEN: Validation error raised
        with pytest.raises(ValidationError) as exc:
            Message.validate_content("")

        assert "cannot be empty" in str(exc.value)

    def test_valid_content_passes_validation(self):
        # GIVEN: Valid content (within limits)
        valid_content = "Valid message content"

        # WHEN: Validating content
        # THEN: No exception raised
        Message.validate_content(valid_content)  # Should not raise
```

### Integration Test Template (API Endpoint)

```python
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
class TestMessageAPI:
    """Integration tests for /api/messages endpoint"""

    async def test_create_message_with_valid_content_returns_201(self):
        # GIVEN: Valid message payload
        payload = {
            "channel_id": "550e8400-e29b-41d4-a716-446655440000",
            "content": "Hello, world!"
        }

        async with AsyncClient(app=app, base_url="http://test") as client:
            # WHEN: Posting to messages endpoint
            response = await client.post("/api/messages", json=payload)

        # THEN: Message created successfully
        assert response.status_code == 201
        data = response.json()
        assert data["content"] == "Hello, world!"
        assert "id" in data
        assert "created_at" in data

    async def test_create_message_with_invalid_content_returns_422(self):
        # GIVEN: Invalid payload (content too long)
        payload = {
            "channel_id": "550e8400-e29b-41d4-a716-446655440000",
            "content": "x" * 4001
        }

        async with AsyncClient(app=app, base_url="http://test") as client:
            # WHEN: Posting to messages endpoint
            response = await client.post("/api/messages", json=payload)

        # THEN: Validation error returned
        assert response.status_code == 422
        assert "exceeds maximum length" in response.json()["detail"]
```

### Database Test Template (with Fixtures)

```python
import pytest
from sqlalchemy.orm import Session
from app.models.message import Message
from app.models.channel import Channel

@pytest.fixture
def db_session():
    """Create test database session"""
    # Setup
    session = TestSession()
    yield session
    # Teardown
    session.rollback()
    session.close()

@pytest.fixture
def test_channel(db_session: Session):
    """Create test channel"""
    channel = Channel(name="Test Channel")
    db_session.add(channel)
    db_session.commit()
    return channel

class TestMessagePersistence:
    """Database integration tests for Message model"""

    def test_message_saved_to_database(self, db_session: Session, test_channel: Channel):
        # GIVEN: Valid message
        message = Message(
            channel_id=test_channel.id,
            content="Test message",
            user_id="user-123"
        )

        # WHEN: Saving to database
        db_session.add(message)
        db_session.commit()

        # THEN: Message persisted with ID
        assert message.id is not None

        # AND: Can be retrieved
        retrieved = db_session.query(Message).filter_by(id=message.id).first()
        assert retrieved.content == "Test message"
```

---

## Frontend Tests (TypeScript + Jest + Testing Library)

### Component Test Template (Accessible Queries)

```typescript
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MessageForm } from './MessageForm'

describe('MessageForm', () => {
  it('prevents submission when content exceeds 4000 characters', async () => {
    // GIVEN: Form rendered with submit handler
    const handleSubmit = jest.fn()
    render(<MessageForm onSubmit={handleSubmit} />)

    // WHEN: User types content exceeding limit
    const textarea = screen.getByRole('textbox', { name: /message/i })
    await userEvent.type(textarea, 'x'.repeat(4001))

    // THEN: Submit button disabled
    const submitButton = screen.getByRole('button', { name: /send/i })
    expect(submitButton).toBeDisabled()

    // AND: Error message shown
    expect(screen.getByText(/exceeds maximum length/i)).toBeVisible()

    // AND: Submit handler not called
    await userEvent.click(submitButton)
    expect(handleSubmit).not.toHaveBeenCalled()
  })

  it('shows character count as user types', async () => {
    // GIVEN: Form rendered
    render(<MessageForm onSubmit={jest.fn()} />)

    // WHEN: User types 100 characters
    const textarea = screen.getByRole('textbox', { name: /message/i })
    await userEvent.type(textarea, 'x'.repeat(100))

    // THEN: Counter shows 100/4000
    expect(screen.getByText('100 / 4000')).toBeInTheDocument()
  })

  it('submits form with valid content', async () => {
    // GIVEN: Form rendered with submit handler
    const handleSubmit = jest.fn()
    render(<MessageForm onSubmit={handleSubmit} />)

    // WHEN: User enters valid content and submits
    await userEvent.type(
      screen.getByRole('textbox', { name: /message/i }),
      'Valid message'
    )
    await userEvent.click(screen.getByRole('button', { name: /send/i }))

    // THEN: Submit handler called with content
    expect(handleSubmit).toHaveBeenCalledWith({
      content: 'Valid message'
    })
  })
})
```

### Hook Test Template (Custom React Hook)

```typescript
import { renderHook, act } from '@testing-library/react'
import { useMessageValidation } from './useMessageValidation'

describe('useMessageValidation', () => {
  it('returns error when content exceeds max length', () => {
    // GIVEN: Hook initialized
    const { result } = renderHook(() => useMessageValidation())

    // WHEN: Validating content >4000 chars
    act(() => {
      result.current.validate('x'.repeat(4001))
    })

    // THEN: Error returned
    expect(result.current.error).toBe('Content exceeds maximum length of 4000 characters')
    expect(result.current.isValid).toBe(false)
  })

  it('clears error when valid content provided', () => {
    // GIVEN: Hook with existing error
    const { result } = renderHook(() => useMessageValidation())
    act(() => {
      result.current.validate('x'.repeat(4001))
    })

    // WHEN: Validating valid content
    act(() => {
      result.current.validate('Valid message')
    })

    // THEN: Error cleared
    expect(result.current.error).toBeNull()
    expect(result.current.isValid).toBe(true)
  })
})
```

### Integration Test Template (API + UI)

```typescript
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { rest } from 'msw'
import { setupServer } from 'msw/node'
import { MessageList } from './MessageList'

// Mock API server
const server = setupServer(
  rest.post('/api/messages', (req, res, ctx) => {
    return res(
      ctx.status(201),
      ctx.json({
        id: 'msg-123',
        content: req.body.content,
        created_at: new Date().toISOString()
      })
    )
  })
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

describe('MessageList Integration', () => {
  it('creates message and updates list when user submits form', async () => {
    // GIVEN: Component rendered
    render(<MessageList channelId="ch-123" />)

    // WHEN: User submits new message
    await userEvent.type(
      screen.getByRole('textbox', { name: /message/i }),
      'New message'
    )
    await userEvent.click(screen.getByRole('button', { name: /send/i }))

    // THEN: Message appears in list
    await waitFor(() => {
      expect(screen.getByText('New message')).toBeInTheDocument()
    })

    // AND: Form is cleared
    expect(screen.getByRole('textbox', { name: /message/i })).toHaveValue('')
  })

  it('shows error when API returns validation error', async () => {
    // GIVEN: API configured to return error
    server.use(
      rest.post('/api/messages', (req, res, ctx) => {
        return res(
          ctx.status(422),
          ctx.json({ detail: 'Content exceeds maximum length' })
        )
      })
    )

    render(<MessageList channelId="ch-123" />)

    // WHEN: User submits invalid message
    await userEvent.type(
      screen.getByRole('textbox', { name: /message/i }),
      'x'.repeat(4001)
    )
    await userEvent.click(screen.getByRole('button', { name: /send/i }))

    // THEN: Error shown to user
    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent(/exceeds maximum length/i)
    })
  })
})
```

---

## Anti-Patterns to Avoid

### ❌ Prop-Mirror Test (Tests Implementation)

```typescript
// DON'T: Tests component props (implementation detail)
it('sets isOpen to true', () => {
  const wrapper = shallow(<Modal isOpen={true} />)
  expect(wrapper.prop('isOpen')).toBe(true)
})
```

### ✅ Behavior Test (Tests User Outcome)

```typescript
// DO: Tests visible behavior
it('shows modal dialog when opened', () => {
  render(<Modal isOpen={true} />)
  expect(screen.getByRole('dialog')).toBeVisible()
})
```

### ❌ Snapshot Test (Fragile)

```typescript
// DON'T: Breaks on any CSS/markup change
it('renders correctly', () => {
  const tree = renderer.create(<Button />).toJSON()
  expect(tree).toMatchSnapshot()
})
```

### ✅ Semantic Test (Resilient)

```typescript
// DO: Tests actual content and behavior
it('renders primary button with correct text', () => {
  render(<Button variant="primary">Click me</Button>)
  const button = screen.getByRole('button', { name: /click me/i })
  expect(button).toHaveClass('btn-primary')
})
```

### ❌ Testing Implementation (White Box)

```typescript
// DON'T: Tests internal state
it('updates internal counter', () => {
  const wrapper = shallow(<Counter />)
  wrapper.find('button').simulate('click')
  expect(wrapper.state('count')).toBe(1)
})
```

### ✅ Testing Behavior (Black Box)

```typescript
// DO: Tests user-visible outcome
it('increments displayed count when button clicked', async () => {
  render(<Counter />)
  await userEvent.click(screen.getByRole('button', { name: /increment/i }))
  expect(screen.getByText('Count: 1')).toBeInTheDocument()
})
```

---

## Speed Optimization Tips

### Slow Tests (>2s) - Fix With Mocks

❌ **Before** (slow: 3.2s):
```python
def test_message_creation():
    # Real DB connection
    message = Message.create(content="Test")
    assert message.id is not None
```

✅ **After** (fast: 0.3s):
```python
@patch('app.models.message.db.session')
def test_message_creation(mock_session):
    # Mock DB
    message = Message(content="Test")
    message.id = "msg-123"
    mock_session.add.return_value = None
    assert message.id == "msg-123"
```

### Slow Suites (>6min) - Parallelize

```bash
# Run tests in parallel (faster)
pytest -n auto  # Uses all CPU cores

# Or for Jest
npm test -- --maxWorkers=4
```

---

## Test Coverage Targets

**By Risk Level:**
- Critical paths (auth, payments, extraction): 95% line, 90% branch
- Core features (upload, results): 90% line, 85% branch
- UI components: 85% line, 80% branch
- Utils/helpers: 80% line, 75% branch

**Quality over Quantity:**
- 80% coverage with behavior tests > 100% with prop-mirror tests
- Test what users do, not how code works
