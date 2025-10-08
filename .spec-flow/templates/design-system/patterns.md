# UX Patterns Library

**Reusable interaction patterns for common scenarios**

Use these established patterns before inventing new interactions. Consistency improves learnability.

---

## Form Patterns

### Inline Validation
**When to use**: Real-time feedback as user types

**Pattern**:
```tsx
<FormField
  control={form.control}
  name="email"
  render={({ field }) => (
    <FormItem>
      <FormLabel>Email</FormLabel>
      <FormControl>
        <Input
          type="email"
          placeholder="you@example.com"
          {...field}
        />
      </FormControl>
      <FormMessage /> {/* Shows error inline */}
    </FormItem>
  )}
/>
```

**Behavior**:
- Validate on blur (first interaction)
- Validate on change (after first error)
- Show success indicator (checkmark) when valid
- Clear error when user starts typing

---

### Multi-Step Forms (Wizard)
**When to use**: Long forms (>10 fields), complex workflows

**Pattern**:
```tsx
<Tabs value={currentStep} onValueChange={setCurrentStep}>
  <TabsList className="grid w-full grid-cols-3">
    <TabsTrigger value="step1">1. Basic Info</TabsTrigger>
    <TabsTrigger value="step2">2. Details</TabsTrigger>
    <TabsTrigger value="step3">3. Review</TabsTrigger>
  </TabsList>

  <TabsContent value="step1">
    {/* Step 1 fields */}
    <Button onClick={() => setCurrentStep("step2")}>Next</Button>
  </TabsContent>

  <TabsContent value="step2">
    {/* Step 2 fields */}
    <Button variant="outline" onClick={() => setCurrentStep("step1")}>Back</Button>
    <Button onClick={() => setCurrentStep("step3")}>Next</Button>
  </TabsContent>

  <TabsContent value="step3">
    {/* Review + submit */}
    <Button variant="outline" onClick={() => setCurrentStep("step2")}>Back</Button>
    <Button onClick={handleSubmit}>Submit</Button>
  </TabsContent>
</Tabs>
```

**Behavior**:
- Save progress on each step (don't lose data)
- Validate current step before allowing "Next"
- Show progress indicator (steps completed)
- Allow going back to previous steps
- Persist in localStorage (resume if user leaves)

---

### Autosave
**When to use**: Long-form content (essays, notes, complex forms)

**Pattern**:
```tsx
const [content, setContent] = useState('');
const [lastSaved, setLastSaved] = useState<Date | null>(null);

// Debounced autosave
useEffect(() => {
  const timer = setTimeout(() => {
    saveToServer(content).then(() => {
      setLastSaved(new Date());
    });
  }, 2000); // Wait 2s after user stops typing

  return () => clearTimeout(timer);
}, [content]);

return (
  <div>
    <Textarea value={content} onChange={(e) => setContent(e.target.value)} />
    {lastSaved && (
      <p className="text-sm text-neutral-500">
        Last saved {formatDistanceToNow(lastSaved)} ago
      </p>
    )}
  </div>
);
```

**Behavior**:
- Debounce 2s (don't save on every keystroke)
- Show "Saving..." indicator
- Show "Saved" confirmation
- Show timestamp of last save
- Handle save errors gracefully (retry, offline queue)

---

## Data Display Patterns

### Empty States
**When to use**: No data yet, filters return no results

**Pattern**:
```tsx
{data.length === 0 ? (
  <EmptyState
    title="No results found"
    message="Try adjusting your search or filters"
    icon={<SearchIcon />}
    action={
      <Button onClick={clearFilters}>Clear filters</Button>
    }
  />
) : (
  <DataList items={data} />
)}
```

**Variants**:
- **First use**: "Get started by creating your first item" (CTA)
- **No results**: "No results found" (suggest clearing filters)
- **Error state**: "Something went wrong" (retry button)

---

### Loading States
**When to use**: Async operations (API calls, file uploads)

**Pattern**:
```tsx
<StateManager
  loading={isLoading}
  error={error}
  empty={data?.length === 0}
  loadingFallback={<LoadingState message="Loading data..." />}
  errorFallback={<ErrorState onRetry={refetch} />}
  emptyFallback={<EmptyState />}
>
  {data?.map(item => <Item key={item.id} {...item} />)}
</StateManager>
```

**Behavior**:
- Show skeleton (not spinner) for content loading
- Show spinner for actions (buttons)
- Show progress bar for uploads (0-100%)
- Minimum 300ms display time (avoid flash)

---

### Pagination vs Infinite Scroll
**Pagination** (when to use):
- User needs to return to specific page
- Data is searchable/filterable
- Known total count
- Example: Search results, data tables

**Pattern**:
```tsx
<Pagination
  currentPage={page}
  totalPages={totalPages}
  onPageChange={setPage}
/>
```

**Infinite scroll** (when to use):
- Browsing/discovery mode
- Continuous feed
- Unknown total count
- Example: Social feeds, image galleries

**Pattern**:
```tsx
<div ref={loadMoreRef}>
  {items.map(item => <Item key={item.id} {...item} />)}
  {hasMore && <LoadingState />}
</div>

// Intersection Observer triggers loadMore()
```

---

## Feedback Patterns

### Success Confirmation
**When to use**: User completes action (save, submit, delete)

**Pattern**:
```tsx
const { toast } = useToast();

const handleSave = async () => {
  await saveData();

  toast({
    title: "Success",
    description: "Your changes have been saved.",
    duration: 3000, // Auto-dismiss after 3s
  });
};
```

**Variants**:
- **Transient** (toast): Auto-dismiss, non-blocking
- **Persistent** (alert): Requires user acknowledgment
- **Inline** (checkmark next to field): Minimal, contextual

---

### Error Handling
**When to use**: Operation fails

**Pattern**:
```tsx
const { toast } = useToast();

const handleSubmit = async () => {
  try {
    await submitData();
    toast({ title: "Success" });
  } catch (error) {
    toast({
      variant: "destructive",
      title: "Error",
      description: error.message,
      action: <Button onClick={handleSubmit}>Retry</Button>,
    });
  }
};
```

**Best practices**:
- Always provide retry action
- Explain what went wrong (not generic "Error occurred")
- Suggest next steps ("Try again" or "Contact support")
- Log to Sentry (automatic error tracking)

---

### Destructive Actions (Confirmation)
**When to use**: Delete, archive, irreversible actions

**Pattern**:
```tsx
const [open, setOpen] = useState(false);

<Dialog open={open} onOpenChange={setOpen}>
  <DialogTrigger asChild>
    <Button variant="destructive">Delete</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Are you sure?</DialogTitle>
      <DialogDescription>
        This action cannot be undone. This will permanently delete the item.
      </DialogDescription>
    </DialogHeader>
    <DialogFooter>
      <Button variant="outline" onClick={() => setOpen(false)}>
        Cancel
      </Button>
      <Button variant="destructive" onClick={handleDelete}>
        Delete permanently
      </Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

**Behavior**:
- Require explicit confirmation (don't auto-confirm on Enter)
- Make cancel button prominent (not destructive action)
- Explain consequences clearly
- Provide undo option if possible (soft delete)

---

## Navigation Patterns

### Breadcrumbs
**When to use**: Deep hierarchy (>2 levels)

**Pattern**:
```tsx
<nav aria-label="Breadcrumb">
  <ol className="flex items-center space-x-2">
    <li><Link href="/">Home</Link></li>
    <li>/</li>
    <li><Link href="/courses">Courses</Link></li>
    <li>/</li>
    <li aria-current="page">CFI Written Test Prep</li>
  </ol>
</nav>
```

**Behavior**:
- Show current location
- Allow jumping to any parent level
- Last item is current page (not clickable)

---

### Tabs (Content Organization)
**When to use**: Related views of same entity (Profile → Settings → Activity)

**Pattern**:
```tsx
<Tabs defaultValue="overview">
  <TabsList>
    <TabsTrigger value="overview">Overview</TabsTrigger>
    <TabsTrigger value="analytics">Analytics</TabsTrigger>
    <TabsTrigger value="settings">Settings</TabsTrigger>
  </TabsList>

  <TabsContent value="overview">
    {/* Overview content */}
  </TabsContent>

  <TabsContent value="analytics">
    {/* Analytics content */}
  </TabsContent>

  <TabsContent value="settings">
    {/* Settings content */}
  </TabsContent>
</Tabs>
```

**Behavior**:
- Persist selected tab in URL (?tab=analytics)
- Keyboard navigation (Arrow keys)
- Lazy load tab content (don't render all upfront)

---

### Side Navigation (Drawer)
**When to use**: Mobile menu, contextual actions

**Pattern**:
```tsx
<Sheet>
  <SheetTrigger asChild>
    <Button variant="ghost" size="icon">
      <MenuIcon />
    </Button>
  </SheetTrigger>
  <SheetContent side="left">
    <nav>
      <Link href="/dashboard">Dashboard</Link>
      <Link href="/courses">Courses</Link>
      <Link href="/settings">Settings</Link>
    </nav>
  </SheetContent>
</Sheet>
```

**Behavior**:
- Slide in from edge (left/right/top/bottom)
- Overlay backdrop (dim background)
- Close on ESC or backdrop click
- Trap focus inside drawer
- Return focus to trigger when closed

---

## Upload Patterns

### Drag & Drop
**When to use**: File uploads

**Pattern**:
```tsx
const [isDragging, setIsDragging] = useState(false);

<div
  onDragOver={(e) => {
    e.preventDefault();
    setIsDragging(true);
  }}
  onDragLeave={() => setIsDragging(false)}
  onDrop={(e) => {
    e.preventDefault();
    setIsDragging(false);
    handleFiles(e.dataTransfer.files);
  }}
  className={cn(
    "border-2 border-dashed rounded-lg p-12",
    isDragging ? "border-brand-primary bg-brand-primary-50" : "border-neutral-300"
  )}
>
  <input
    type="file"
    id="file-upload"
    className="sr-only"
    onChange={(e) => handleFiles(e.target.files)}
  />
  <label htmlFor="file-upload" className="cursor-pointer">
    <p>Drop files here or click to browse</p>
  </label>
</div>
```

**Behavior**:
- Visual feedback on drag (change border color)
- Allow click to browse (fallback for non-drag)
- Show preview after upload (thumbnail + filename)
- Show progress bar during upload

---

### Multi-File Upload
**When to use**: Batch uploads (multiple documents)

**Pattern**:
```tsx
<input
  type="file"
  multiple
  onChange={(e) => {
    const files = Array.from(e.target.files);
    files.forEach(file => uploadFile(file));
  }}
/>

{uploads.map(upload => (
  <div key={upload.id}>
    <p>{upload.name}</p>
    <Progress value={upload.progress} />
    {upload.error && <Alert variant="destructive">{upload.error}</Alert>}
  </div>
))}
```

**Behavior**:
- Show individual progress per file
- Allow canceling individual uploads
- Show errors per file (don't fail entire batch)
- Queue uploads (max 3 concurrent)

---

## Search Patterns

### Instant Search (As-You-Type)
**When to use**: Small datasets (<1000 items), client-side filtering

**Pattern**:
```tsx
const [query, setQuery] = useState('');

// Debounced search
const debouncedQuery = useDebounce(query, 300);

const results = useMemo(() => {
  return items.filter(item =>
    item.name.toLowerCase().includes(debouncedQuery.toLowerCase())
  );
}, [items, debouncedQuery]);

<Input
  type="search"
  placeholder="Search..."
  value={query}
  onChange={(e) => setQuery(e.target.value)}
/>
```

**Behavior**:
- Debounce 300ms (don't search on every keystroke)
- Highlight matching text
- Show result count
- Clear search button

---

### Search with Filters
**When to use**: Large datasets, multiple criteria

**Pattern**:
```tsx
<div className="flex gap-4">
  <Input
    type="search"
    placeholder="Search..."
    value={query}
    onChange={(e) => setQuery(e.target.value)}
  />

  <Select value={category} onValueChange={setCategory}>
    <SelectTrigger>
      <SelectValue placeholder="Category" />
    </SelectTrigger>
    <SelectContent>
      <SelectItem value="all">All</SelectItem>
      <SelectItem value="courses">Courses</SelectItem>
      <SelectItem value="lessons">Lessons</SelectItem>
    </SelectContent>
  </Select>

  <Button variant="outline" onClick={clearFilters}>
    Clear filters
  </Button>
</div>
```

**Behavior**:
- Persist filters in URL (?q=test&category=courses)
- Show active filter count (badge on filter button)
- Clear all filters with one click

---

## References

- Nielsen Norman Group: https://www.nngroup.com/articles/
- Material Design Patterns: https://m3.material.io/
- Apple HIG: https://developer.apple.com/design/human-interface-guidelines/

**Last updated**: 2025-10-06
