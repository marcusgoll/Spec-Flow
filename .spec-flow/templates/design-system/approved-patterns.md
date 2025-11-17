# Approved Design Patterns

> **Living Document**: This file is automatically updated when mockups are approved during the workflow. Patterns documented here have been validated for consistency, accessibility, and alignment with the design system.

**Last Updated**: [Auto-generated timestamp]
**Total Patterns**: [Auto-generated count]

---

## Overview

This library contains reusable design patterns extracted from approved feature mockups. Each pattern includes:
- **Structure**: HTML/component composition
- **Token usage**: Design tokens applied
- **When to use**: Appropriate use cases
- **Source features**: Where this pattern originated
- **Accessibility notes**: WCAG compliance details

## Pattern Categories

### Layout Patterns
- [Dashboard Layout](#dashboard-layout)
- [Two-Column Form](#two-column-form)
- [Sidebar Navigation](#sidebar-navigation)
- [Content Grid](#content-grid)

### Form Patterns
- [Vertical Label Form](#vertical-label-form)
- [Inline Validation](#inline-validation)
- [Multi-Step Wizard](#multi-step-wizard)

### Data Display Patterns
- [Data Table with Pagination](#data-table-with-pagination)
- [Card Grid](#card-grid)
- [List with Actions](#list-with-actions)

### Navigation Patterns
- [Breadcrumb Navigation](#breadcrumb-navigation)
- [Tab Navigation](#tab-navigation)
- [Modal Navigation](#modal-navigation)

### State Patterns
- [Loading States](#loading-states)
- [Empty States](#empty-states)
- [Error States](#error-states)

---

## Layout Patterns

### Dashboard Layout

**Description**: Sidebar navigation with main content area, commonly used for admin panels and settings pages.

**Usage Count**: [Auto-generated]
**First Appeared**: [Feature ID]
**Used In**: [List of feature IDs]

**Structure**:
```html
<div class="flex min-h-screen">
  <!-- Sidebar -->
  <aside class="w-64 border-r border-neutral-200 bg-neutral-50">
    <nav class="p-4 space-y-2">
      <!-- Navigation links -->
    </nav>
  </aside>

  <!-- Main content -->
  <main class="flex-1 p-8">
    <div class="max-w-7xl mx-auto">
      <!-- Page content -->
    </div>
  </main>
</div>
```

**Token Usage**:
- Width: `w-64` (256px sidebar)
- Spacing: `p-4` (16px), `p-8` (32px), `space-y-2` (8px gap)
- Colors: `border-neutral-200`, `bg-neutral-50`
- Layout: `max-w-7xl` (1280px max content width)

**When to Use**:
- Admin dashboards
- Settings pages
- Content management interfaces
- Any interface with persistent navigation

**Accessibility**:
- Sidebar uses `<aside>` semantic element
- Navigation uses `<nav>` landmark
- Main content uses `<main>` landmark
- Keyboard navigable (tab order: sidebar → main)

**Responsive Considerations**:
- Mobile: Sidebar collapses to hamburger menu
- Tablet: Sidebar may overlay main content
- Desktop: Full sidebar visible

**Source Files**:
- `specs/002-dashboard/mockups/overview.html`
- `specs/004-settings/mockups/profile.html`

---

### Two-Column Form

**Description**: Form layout with fields split into two columns, used for wide forms with many fields.

**Usage Count**: [Auto-generated]
**First Appeared**: [Feature ID]
**Used In**: [List of feature IDs]

**Structure**:
```html
<form class="max-w-4xl mx-auto">
  <div class="grid grid-cols-2 gap-4">
    <!-- Left column -->
    <div class="space-y-4">
      <div>
        <label class="block text-sm font-medium mb-1">First Name</label>
        <input type="text" class="w-full px-3 py-2 border rounded" />
      </div>
      <!-- More fields -->
    </div>

    <!-- Right column -->
    <div class="space-y-4">
      <div>
        <label class="block text-sm font-medium mb-1">Last Name</label>
        <input type="text" class="w-full px-3 py-2 border rounded" />
      </div>
      <!-- More fields -->
    </div>
  </div>

  <!-- Full-width actions -->
  <div class="mt-6 flex justify-end gap-3">
    <button type="button" class="px-4 py-2 border rounded">Cancel</button>
    <button type="submit" class="px-4 py-2 bg-brand-primary text-white rounded">Save</button>
  </div>
</form>
```

**Token Usage**:
- Grid: `grid-cols-2`, `gap-4` (16px)
- Spacing: `space-y-4` (16px), `mb-1` (4px), `mt-6` (24px), `gap-3` (12px)
- Sizing: `max-w-4xl` (896px), `w-full`
- Padding: `px-3 py-2` (12px/8px), `px-4 py-2` (16px/8px)
- Colors: `bg-brand-primary`, `text-white`

**When to Use**:
- Forms with 6+ fields
- User profile editing
- Settings forms
- Registration forms with many fields

**When NOT to Use**:
- Mobile layouts (use single column)
- Forms with <6 fields (use vertical single column)
- Forms with varying field widths (breaks visual rhythm)

**Accessibility**:
- Labels properly associated (`for`/`id` attributes)
- Logical tab order (left column top→bottom, then right column)
- Focus indicators visible
- Error messages announced to screen readers

**Responsive Considerations**:
- Mobile: `grid-cols-1` (stacks to single column)
- Tablet: `md:grid-cols-2` (two columns on medium+)
- Desktop: Full two-column layout

**Source Files**:
- `specs/001-auth/mockups/signup.html`
- `specs/005-profile/mockups/edit.html`

---

### Sidebar Navigation

**Description**: Persistent navigation sidebar with collapsible sections.

**Usage Count**: [Auto-generated]
**First Appeared**: [Feature ID]
**Used In**: [List of feature IDs]

**Structure**:
```html
<aside class="w-64 h-screen sticky top-0 border-r bg-white">
  <div class="p-4">
    <!-- Logo/branding -->
    <div class="mb-8">
      <h1 class="text-xl font-bold">App Name</h1>
    </div>

    <!-- Navigation sections -->
    <nav class="space-y-6">
      <!-- Section 1 -->
      <div>
        <h2 class="text-xs font-semibold uppercase text-neutral-500 mb-2">Section 1</h2>
        <ul class="space-y-1">
          <li>
            <a href="#" class="flex items-center gap-3 px-3 py-2 rounded hover:bg-neutral-100">
              <span>Link 1</span>
            </a>
          </li>
          <!-- More links -->
        </ul>
      </div>

      <!-- Section 2 -->
      <div>
        <h2 class="text-xs font-semibold uppercase text-neutral-500 mb-2">Section 2</h2>
        <ul class="space-y-1">
          <!-- Links -->
        </ul>
      </div>
    </nav>
  </div>
</aside>
```

**Token Usage**:
- Width: `w-64` (256px)
- Spacing: `p-4` (16px), `mb-8` (32px), `space-y-6` (24px), `space-y-1` (4px)
- Padding: `px-3 py-2` (12px/8px)
- Typography: `text-xl` (1.25rem), `text-xs` (0.75rem), `font-bold`, `font-semibold`, `uppercase`
- Colors: `bg-white`, `text-neutral-500`, `hover:bg-neutral-100`

**When to Use**:
- Multi-section applications
- Admin panels
- Settings with categories
- Content management systems

**Accessibility**:
- `<nav>` landmark for navigation
- Section headings use `<h2>` (proper hierarchy)
- Active link indicated visually and with `aria-current="page"`
- Keyboard navigable (arrow keys for links)

**Active State**:
```html
<a href="#"
   class="flex items-center gap-3 px-3 py-2 rounded bg-brand-primary/10 text-brand-primary font-medium"
   aria-current="page">
  <span>Active Link</span>
</a>
```

**Source Files**:
- `specs/002-dashboard/mockups/overview.html`
- `specs/006-admin/mockups/users.html`

---

## Form Patterns

### Vertical Label Form

**Description**: Standard form layout with labels above inputs, the most common pattern for web forms.

**Usage Count**: [Auto-generated]
**First Appeared**: [Feature ID]
**Used In**: [List of feature IDs]

**Structure**:
```html
<form class="max-w-md mx-auto space-y-4">
  <!-- Text input -->
  <div>
    <label for="email" class="block text-sm font-medium mb-1">Email</label>
    <input
      type="email"
      id="email"
      class="w-full px-3 py-2 border border-neutral-300 rounded focus:outline-none focus:ring-2 focus:ring-brand-primary"
      aria-describedby="email-error"
    />
    <!-- Error message (hidden by default) -->
    <p id="email-error" class="text-sm text-semantic-error mt-1 hidden">Please enter a valid email</p>
  </div>

  <!-- Select input -->
  <div>
    <label for="role" class="block text-sm font-medium mb-1">Role</label>
    <select
      id="role"
      class="w-full px-3 py-2 border border-neutral-300 rounded focus:outline-none focus:ring-2 focus:ring-brand-primary"
    >
      <option value="">Select a role</option>
      <option value="admin">Admin</option>
      <option value="user">User</option>
    </select>
  </div>

  <!-- Checkbox -->
  <div class="flex items-start gap-2">
    <input
      type="checkbox"
      id="terms"
      class="mt-1 w-4 h-4"
    />
    <label for="terms" class="text-sm">I agree to the terms and conditions</label>
  </div>

  <!-- Actions -->
  <div class="flex gap-3">
    <button type="button" class="flex-1 px-4 py-2 border border-neutral-300 rounded hover:bg-neutral-50">
      Cancel
    </button>
    <button type="submit" class="flex-1 px-4 py-2 bg-brand-primary text-white rounded hover:bg-brand-primary/90">
      Submit
    </button>
  </div>
</form>
```

**Token Usage**:
- Container: `max-w-md` (448px), `mx-auto`, `space-y-4` (16px)
- Labels: `text-sm`, `font-medium`, `mb-1` (4px)
- Inputs: `px-3 py-2` (12px/8px), `border-neutral-300`, `rounded`, `focus:ring-2`, `focus:ring-brand-primary`
- Errors: `text-sm`, `text-semantic-error`, `mt-1` (4px)
- Buttons: `px-4 py-2` (16px/8px), `bg-brand-primary`, `hover:bg-brand-primary/90`

**When to Use**:
- Login/signup forms
- Settings forms
- Data entry forms
- Any form with <6 fields

**Accessibility**:
- Labels associated with `for`/`id`
- Error messages linked with `aria-describedby`
- Focus indicators visible (2px ring)
- Error messages announced to screen readers
- Touch targets ≥24x24px (checkbox w-4 h-4 = 16px, needs adjustment to w-6 h-6)

**Validation States**:

**Error State**:
```html
<div>
  <label for="email" class="block text-sm font-medium mb-1">Email</label>
  <input
    type="email"
    id="email"
    class="w-full px-3 py-2 border border-semantic-error rounded focus:ring-2 focus:ring-semantic-error"
    aria-invalid="true"
    aria-describedby="email-error"
  />
  <p id="email-error" class="text-sm text-semantic-error mt-1">Please enter a valid email</p>
</div>
```

**Success State**:
```html
<div>
  <label for="email" class="block text-sm font-medium mb-1">Email</label>
  <input
    type="email"
    id="email"
    class="w-full px-3 py-2 border border-semantic-success rounded"
    aria-invalid="false"
  />
  <p class="text-sm text-semantic-success mt-1">✓ Email is valid</p>
</div>
```

**Source Files**:
- `specs/001-auth/mockups/login.html`
- `specs/002-settings/mockups/profile.html`
- `specs/005-contact/mockups/form.html`

---

### Inline Validation

**Description**: Real-time validation feedback as users fill out forms.

**Usage Count**: [Auto-generated]
**First Appeared**: [Feature ID]
**Used In**: [List of feature IDs]

**Structure**:
```html
<form id="signup-form" class="max-w-md mx-auto space-y-4">
  <!-- Password field with strength indicator -->
  <div>
    <label for="password" class="block text-sm font-medium mb-1">Password</label>
    <input
      type="password"
      id="password"
      class="w-full px-3 py-2 border rounded"
      aria-describedby="password-hint password-strength"
    />
    <p id="password-hint" class="text-xs text-neutral-600 mt-1">
      Must be at least 8 characters with 1 number and 1 special character
    </p>

    <!-- Strength indicator -->
    <div id="password-strength" class="mt-2">
      <div class="flex gap-1">
        <div class="h-1 flex-1 rounded bg-neutral-200"></div>
        <div class="h-1 flex-1 rounded bg-neutral-200"></div>
        <div class="h-1 flex-1 rounded bg-neutral-200"></div>
        <div class="h-1 flex-1 rounded bg-neutral-200"></div>
      </div>
      <p class="text-xs text-neutral-600 mt-1">Strength: <span id="strength-label">Weak</span></p>
    </div>
  </div>

  <!-- Email with validation -->
  <div>
    <label for="email" class="block text-sm font-medium mb-1">Email</label>
    <div class="relative">
      <input
        type="email"
        id="email"
        class="w-full px-3 py-2 pr-10 border rounded"
        aria-describedby="email-error"
      />
      <!-- Validation icon -->
      <span class="absolute right-3 top-1/2 -translate-y-1/2 hidden" id="email-valid-icon">
        ✓
      </span>
    </div>
    <p id="email-error" class="text-sm text-semantic-error mt-1 hidden"></p>
  </div>
</form>

<script>
  // Inline validation logic (state switcher)
  const states = {
    initial: { /* ... */ },
    validating: { /* ... */ },
    valid: { /* ... */ },
    invalid: { /* ... */ }
  };
</script>
```

**Token Usage**:
- Spacing: `space-y-4` (16px), `mt-1` (4px), `mt-2` (8px), `gap-1` (4px)
- Typography: `text-sm`, `text-xs`, `font-medium`
- Colors: `text-neutral-600`, `text-semantic-error`, `text-semantic-success`, `bg-neutral-200`
- Sizing: `h-1` (4px for strength bars), `pr-10` (40px padding for icon)

**When to Use**:
- Signup forms (password strength)
- Email validation
- Username availability checks
- Credit card entry
- Any form where immediate feedback improves UX

**Accessibility**:
- Hint text linked with `aria-describedby`
- Validation messages announced with `role="alert"` (live region)
- Icons supplemented with text (not icon-only)
- Error messages appear in tab order after input

**JavaScript States**:
```javascript
const validationStates = {
  initial: {
    borderClass: 'border-neutral-300',
    message: '',
    iconVisible: false
  },
  validating: {
    borderClass: 'border-neutral-300',
    message: 'Checking...',
    iconVisible: false
  },
  valid: {
    borderClass: 'border-semantic-success',
    message: '✓ Email is available',
    messageClass: 'text-semantic-success',
    iconVisible: true
  },
  invalid: {
    borderClass: 'border-semantic-error',
    message: 'Email is already taken',
    messageClass: 'text-semantic-error',
    iconVisible: false
  }
};
```

**Source Files**:
- `specs/001-auth/mockups/signup.html`
- `specs/007-account/mockups/change-password.html`

---

## Data Display Patterns

### Data Table with Pagination

**Description**: Sortable data table with pagination controls, used for displaying large datasets.

**Usage Count**: [Auto-generated]
**First Appeared**: [Feature ID]
**Used In**: [List of feature IDs]

**Structure**:
```html
<div class="bg-white rounded-lg shadow">
  <!-- Table header -->
  <div class="p-4 border-b">
    <div class="flex items-center justify-between">
      <h2 class="text-lg font-semibold">Users</h2>
      <button class="px-4 py-2 bg-brand-primary text-white rounded">Add User</button>
    </div>
  </div>

  <!-- Table -->
  <div class="overflow-x-auto">
    <table class="w-full">
      <thead class="bg-neutral-50 border-b">
        <tr>
          <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-neutral-600">
            <button class="flex items-center gap-1">
              Name
              <span class="text-neutral-400">↓</span>
            </button>
          </th>
          <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-neutral-600">Email</th>
          <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-neutral-600">Role</th>
          <th class="px-4 py-3 text-right text-xs font-semibold uppercase text-neutral-600">Actions</th>
        </tr>
      </thead>
      <tbody class="divide-y">
        <tr class="hover:bg-neutral-50">
          <td class="px-4 py-3">John Doe</td>
          <td class="px-4 py-3 text-neutral-600">john@example.com</td>
          <td class="px-4 py-3">
            <span class="px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded">Admin</span>
          </td>
          <td class="px-4 py-3 text-right">
            <button class="text-blue-600 hover:underline text-sm">Edit</button>
          </td>
        </tr>
        <!-- More rows -->
      </tbody>
    </table>
  </div>

  <!-- Pagination -->
  <div class="p-4 border-t flex items-center justify-between">
    <p class="text-sm text-neutral-600">Showing 1-10 of 47 results</p>
    <div class="flex gap-2">
      <button class="px-3 py-1 border rounded hover:bg-neutral-50" disabled>Previous</button>
      <button class="px-3 py-1 bg-brand-primary text-white rounded">1</button>
      <button class="px-3 py-1 border rounded hover:bg-neutral-50">2</button>
      <button class="px-3 py-1 border rounded hover:bg-neutral-50">3</button>
      <button class="px-3 py-1 border rounded hover:bg-neutral-50">Next</button>
    </div>
  </div>
</div>
```

**Token Usage**:
- Container: `bg-white`, `rounded-lg`, `shadow`
- Padding: `p-4` (16px), `px-4 py-3` (16px/12px)
- Typography: `text-lg`, `text-xs`, `text-sm`, `font-semibold`, `font-medium`, `uppercase`
- Colors: `bg-neutral-50`, `text-neutral-600`, `border-neutral-200`, `bg-blue-100`, `text-blue-800`
- Spacing: `gap-1` (4px), `gap-2` (8px)

**When to Use**:
- User lists
- Product catalogs
- Transaction histories
- Any dataset with >20 items

**Accessibility**:
- Proper `<table>` semantics (`<thead>`, `<tbody>`, `<th>`, `<td>`)
- Sortable headers use `<button>` elements
- Sort direction indicated visually (arrow) and with `aria-sort="ascending"`
- Pagination controls keyboard accessible
- Row hover states visible

**Sortable Column Markup**:
```html
<th class="px-4 py-3 text-left" scope="col" aria-sort="ascending">
  <button class="flex items-center gap-1">
    Name
    <span class="text-neutral-400" aria-hidden="true">↑</span>
  </button>
</th>
```

**Source Files**:
- `specs/003-users/mockups/user-list.html`
- `specs/006-analytics/mockups/reports.html`

---

## State Patterns

### Loading States

**Description**: Visual feedback while data is being fetched or processed.

**Usage Count**: [Auto-generated]
**First Appeared**: [Feature ID]
**Used In**: [List of feature IDs]

**Skeleton Loader**:
```html
<div class="animate-pulse">
  <!-- Header skeleton -->
  <div class="h-8 w-48 bg-neutral-200 rounded mb-4"></div>

  <!-- Content skeletons -->
  <div class="space-y-3">
    <div class="h-4 bg-neutral-200 rounded"></div>
    <div class="h-4 bg-neutral-200 rounded w-5/6"></div>
    <div class="h-4 bg-neutral-200 rounded w-4/6"></div>
  </div>
</div>
```

**Spinner + Message**:
```html
<div class="flex items-center justify-center min-h-[400px]">
  <div class="text-center">
    <!-- Spinner -->
    <div class="inline-block w-8 h-8 border-4 border-neutral-200 border-t-brand-primary rounded-full animate-spin"></div>
    <p class="mt-4 text-neutral-600">Loading users...</p>
  </div>
</div>
```

**Token Usage**:
- Colors: `bg-neutral-200`, `border-neutral-200`, `border-t-brand-primary`, `text-neutral-600`
- Sizing: `h-4` (16px), `h-8` (32px), `w-8` (32px), `border-4` (4px)
- Animation: `animate-pulse`, `animate-spin`
- Spacing: `space-y-3` (12px), `mt-4` (16px)

**When to Use**:
- Initial page load
- Data fetching
- Form submission
- File upload progress

**Accessibility**:
- Loading message announced with `role="status"` or `aria-live="polite"`
- Spinner has `aria-label="Loading"`
- Focus managed (loading overlay prevents interaction)

**Source Files**:
- `specs/003-users/mockups/user-list.html` (state=loading)
- `specs/006-analytics/mockups/dashboard.html` (state=loading)

---

### Empty States

**Description**: Helpful messaging when no data exists, guiding users to take action.

**Usage Count**: [Auto-generated]
**First Appeared**: [Feature ID]
**Used In**: [List of feature IDs]

**Structure**:
```html
<div class="flex items-center justify-center min-h-[400px]">
  <div class="text-center max-w-md">
    <!-- Icon/illustration -->
    <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-neutral-100 flex items-center justify-center">
      <svg class="w-8 h-8 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <!-- Icon SVG -->
      </svg>
    </div>

    <!-- Heading -->
    <h3 class="text-lg font-semibold mb-2">No users found</h3>

    <!-- Description -->
    <p class="text-neutral-600 mb-6">
      Get started by adding your first user to the system.
    </p>

    <!-- Action -->
    <button class="px-4 py-2 bg-brand-primary text-white rounded">
      Add First User
    </button>
  </div>
</div>
```

**Token Usage**:
- Container: `min-h-[400px]`, `max-w-md`
- Icon: `w-16 h-16` (64px), `w-8 h-8` (32px), `bg-neutral-100`, `text-neutral-400`, `rounded-full`
- Typography: `text-lg`, `font-semibold`
- Colors: `text-neutral-600`, `bg-brand-primary`, `text-white`
- Spacing: `mb-2` (8px), `mb-4` (16px), `mb-6` (24px)

**When to Use**:
- Empty lists/tables
- No search results
- New user onboarding
- Deleted all items

**Accessibility**:
- Uses semantic heading structure
- Action button has clear label
- Icon is decorative (`aria-hidden="true"` on SVG)

**Source Files**:
- `specs/003-users/mockups/user-list.html` (state=empty)
- `specs/008-projects/mockups/project-list.html` (state=empty)

---

### Error States

**Description**: Clear error messaging with recovery actions.

**Usage Count**: [Auto-generated]
**First Appeared**: [Feature ID]
**Used In**: [List of feature IDs]

**Structure**:
```html
<div class="flex items-center justify-center min-h-[400px]">
  <div class="text-center max-w-md">
    <!-- Error icon -->
    <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-semantic-error/10 flex items-center justify-center">
      <svg class="w-8 h-8 text-semantic-error" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <!-- Error icon SVG -->
      </svg>
    </div>

    <!-- Heading -->
    <h3 class="text-lg font-semibold mb-2">Failed to load users</h3>

    <!-- Error details -->
    <p class="text-neutral-600 mb-2">
      We couldn't fetch the user list. Please check your connection and try again.
    </p>

    <!-- Technical details (collapsible) -->
    <details class="mb-6">
      <summary class="text-sm text-neutral-500 cursor-pointer">Technical details</summary>
      <p class="text-xs text-neutral-500 mt-2 font-mono bg-neutral-50 p-2 rounded">
        Error: Network request failed (ECONNREFUSED)
      </p>
    </details>

    <!-- Actions -->
    <div class="flex gap-3 justify-center">
      <button class="px-4 py-2 border rounded">Contact Support</button>
      <button class="px-4 py-2 bg-brand-primary text-white rounded">Try Again</button>
    </div>
  </div>
</div>
```

**Token Usage**:
- Icon: `bg-semantic-error/10`, `text-semantic-error`
- Typography: `text-lg`, `text-sm`, `text-xs`, `font-semibold`, `font-mono`
- Colors: `text-neutral-600`, `text-neutral-500`, `bg-neutral-50`
- Spacing: `mb-2` (8px), `mb-4` (16px), `mb-6` (24px), `gap-3` (12px), `p-2` (8px)

**When to Use**:
- Network errors
- API failures
- Permission errors
- Data validation errors

**Accessibility**:
- Error announced with `role="alert"` (live region)
- Primary action ("Try Again") visually prominent
- Technical details expandable (progressive disclosure)

**Source Files**:
- `specs/003-users/mockups/user-list.html` (state=error)
- `specs/006-analytics/mockups/dashboard.html` (state=error)

---

## Usage Guidelines

### Pattern Selection
1. **Check this library first** before creating custom layouts
2. **Use exact code** when requirements match
3. **Adapt minimally** if slight modifications needed
4. **Document new patterns** when none apply

### Pattern Evolution
- **Update patterns** when improvements discovered
- **Deprecate patterns** when better alternatives emerge
- **Version patterns** if breaking changes needed

### Contributing New Patterns
**Criteria for approval:**
- Used in 3+ features (proven utility)
- Follows Core 9 Rules (style-guide.md)
- Accessible (WCAG 2.1 AA)
- Uses design tokens (no hardcoded values)
- Includes source file references

---

## Auto-Update Process

**This file is automatically updated when:**
1. Mockups are approved (after `/tasks --ui-first` approval gate)
2. Patterns extracted from `specs/*/mockups/*.html`
3. Usage counts incremented when pattern reused
4. New patterns added when 3+ feature uses detected

**Manual updates needed for:**
- Pattern deprecation notices
- Breaking change documentation
- Usage guideline clarifications

---

**Template Version**: 1.0.0
**Last Updated**: [Auto-generated timestamp]
