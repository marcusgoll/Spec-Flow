# UI Component Inventory

**Single source of truth for available UI components**

All components are from shadcn/ui. Before creating custom components, check if existing primitives can be composed.

---

## Layout Components

### Card
**Path**: `@/components/ui/card`

Container for related content with optional header, footer, and actions.

**Variants**:
- Card (container)
- CardHeader (top section)
- CardTitle (heading)
- CardDescription (subtitle)
- CardContent (main content)
- CardFooter (bottom actions)

**Usage**:
```tsx
<Card>
  <CardHeader>
    <CardTitle>Card Title</CardTitle>
    <CardDescription>Optional description</CardDescription>
  </CardHeader>
  <CardContent>
    Main content here
  </CardContent>
  <CardFooter>
    <Button>Action</Button>
  </CardFooter>
</Card>
```

---

### Sheet
**Path**: `@/components/ui/sheet`

Slide-in panel from edge of screen (drawer/sidebar).

**Variants**:
- Sheet (container)
- SheetTrigger (opens sheet)
- SheetContent (panel content)
- SheetHeader (panel header)
- SheetTitle (panel heading)
- SheetDescription (panel subtitle)
- SheetFooter (panel footer)

**Props**:
- `side`: "top" | "right" | "bottom" | "left"

---

### Dialog
**Path**: `@/components/ui/dialog`

Modal overlay that captures focus.

**Variants**:
- Dialog (container)
- DialogTrigger (opens dialog)
- DialogContent (modal content)
- DialogHeader (modal header)
- DialogTitle (modal heading)
- DialogDescription (modal subtitle)
- DialogFooter (modal footer)

---

### Tabs
**Path**: `@/components/ui/tabs`

Organize content into multiple views with tab navigation.

**Variants**:
- Tabs (container)
- TabsList (tab buttons container)
- TabsTrigger (individual tab button)
- TabsContent (panel for each tab)

---

## Form Components

### Button
**Path**: `@/components/ui/button`

Primary interaction component.

**Variants**:
- `default` - Primary action (brand color)
- `destructive` - Dangerous action (red)
- `outline` - Secondary action (border only)
- `secondary` - Less prominent action (gray)
- `ghost` - Minimal styling (hover only)
- `link` - Text-only (underline on hover)

**Sizes**:
- `default` - Standard size
- `sm` - Small (compact forms)
- `lg` - Large (hero CTAs)
- `icon` - Square (icon-only)

**Usage**:
```tsx
<Button variant="default" size="default">
  Primary Action
</Button>
```

---

### Input
**Path**: `@/components/ui/input`

Single-line text input.

**Types**: text, email, password, number, search, tel, url

**Usage**:
```tsx
<div>
  <Label htmlFor="email">Email</Label>
  <Input id="email" type="email" placeholder="you@example.com" />
</div>
```

---

### Textarea
**Path**: `@/components/ui/textarea`

Multi-line text input.

---

### Select
**Path**: `@/components/ui/select`

Dropdown selection.

**Variants**:
- Select (container)
- SelectTrigger (opens dropdown)
- SelectContent (dropdown panel)
- SelectItem (individual option)
- SelectGroup (grouped options)
- SelectLabel (group label)

---

### Checkbox
**Path**: `@/components/ui/checkbox`

Toggle true/false state.

**Usage**:
```tsx
<div className="flex items-center space-x-2">
  <Checkbox id="terms" />
  <Label htmlFor="terms">Accept terms</Label>
</div>
```

---

### Switch
**Path**: `@/components/ui/switch`

Toggle switch (on/off).

---

### Label
**Path**: `@/components/ui/label`

Form field label (associates with input via `htmlFor`).

---

### Form
**Path**: `@/components/ui/form`

Form wrapper with validation (react-hook-form integration).

**Variants**:
- Form (container)
- FormField (field wrapper)
- FormItem (field + label + error)
- FormLabel (field label)
- FormControl (input wrapper)
- FormDescription (help text)
- FormMessage (error message)

---

## Feedback Components

### Alert
**Path**: `@/components/ui/alert`

Display important messages.

**Variants**:
- `default` - Informational (neutral)
- `destructive` - Error/danger (red)

**Components**:
- Alert (container)
- AlertTitle (heading)
- AlertDescription (message)

**Usage**:
```tsx
<Alert variant="destructive">
  <AlertTitle>Error</AlertTitle>
  <AlertDescription>
    Something went wrong. Please try again.
  </AlertDescription>
</Alert>
```

---

### Toast
**Path**: `@/components/ui/toast`

Temporary notification (auto-dismiss).

**Variants**:
- `default` - Neutral
- `destructive` - Error

**Usage**:
```tsx
import { useToast } from '@/components/ui/use-toast';

const { toast } = useToast();

toast({
  title: "Success",
  description: "Your changes have been saved.",
});
```

---

### Badge
**Path**: `@/components/ui/badge`

Small label/tag.

**Variants**:
- `default` - Primary (brand color)
- `secondary` - Neutral (gray)
- `destructive` - Danger (red)
- `outline` - Border only

---

### Progress
**Path**: `@/components/ui/progress`

Progress bar (determinate).

**Usage**:
```tsx
<Progress value={65} />
```

---

### Skeleton
**Path**: `@/components/ui/skeleton`

Loading placeholder (shimmer effect).

**Usage**:
```tsx
<Skeleton className="h-4 w-48" />
<Skeleton className="h-12 w-full" />
```

---

## Navigation Components

### DropdownMenu
**Path**: `@/components/ui/dropdown-menu`

Menu triggered by button click.

**Variants**:
- DropdownMenu (container)
- DropdownMenuTrigger (button)
- DropdownMenuContent (menu panel)
- DropdownMenuItem (menu item)
- DropdownMenuCheckboxItem (checkbox item)
- DropdownMenuRadioItem (radio item)
- DropdownMenuLabel (section label)
- DropdownMenuSeparator (divider)
- DropdownMenuShortcut (keyboard hint)
- DropdownMenuGroup (grouped items)
- DropdownMenuSub (nested menu)

---

### Avatar
**Path**: `@/components/ui/avatar`

User profile picture with fallback.

**Variants**:
- Avatar (container)
- AvatarImage (img element)
- AvatarFallback (initials/icon)

**Usage**:
```tsx
<Avatar>
  <AvatarImage src="/avatars/user.jpg" alt="User" />
  <AvatarFallback>JD</AvatarFallback>
</Avatar>
```

---

## Data Display Components

### Table
**Path**: `@/components/ui/table`

Tabular data display.

**Variants**:
- Table (table element)
- TableHeader (thead)
- TableBody (tbody)
- TableFooter (tfoot)
- TableRow (tr)
- TableHead (th)
- TableCell (td)
- TableCaption (caption)

---

### Separator
**Path**: `@/components/ui/separator`

Visual divider (horizontal or vertical line).

**Props**:
- `orientation`: "horizontal" | "vertical"

---

## Custom Components (CFIPros-specific)

### LoadingState
**Path**: `@/components/ui/loading-state`

Centralized loading UI with spinner and message.

**Usage**:
```tsx
<LoadingState message="Loading data..." />
```

---

### ErrorState
**Path**: `@/components/ui/error-state`

Centralized error UI with retry action.

**Usage**:
```tsx
<ErrorState
  title="Something went wrong"
  message="Failed to load data"
  onRetry={() => refetch()}
/>
```

---

### EmptyState
**Path**: `@/components/ui/empty-state`

Centralized empty UI with call-to-action.

**Usage**:
```tsx
<EmptyState
  title="No results found"
  message="Try adjusting your search"
  action={<Button>Clear filters</Button>}
/>
```

---

### StateManager
**Path**: `@/components/ui/state-manager`

Wrapper that handles loading, error, empty, and success states.

**Usage**:
```tsx
<StateManager
  loading={isLoading}
  error={error}
  empty={data?.length === 0}
  loadingFallback={<LoadingState />}
  errorFallback={<ErrorState onRetry={refetch} />}
  emptyFallback={<EmptyState />}
>
  {data?.map(item => <Item key={item.id} {...item} />)}
</StateManager>
```

---

## Component Composition Guidelines

**Before creating custom components:**

1. **Check inventory** - Does a primitive exist?
2. **Try composition** - Can you combine primitives?
3. **Propose first** - Create `design/systems/proposals/component-name.md`
4. **Get approval** - Discuss before implementation
5. **Add to inventory** - Update this file after approval

**Example composition** (instead of custom component):

```tsx
// ❌ Don't create <CustomUploadZone>
// ✅ Do compose primitives:

<Card className="border-dashed border-2 hover:border-primary">
  <CardContent className="pt-6">
    <Label htmlFor="file-upload" className="cursor-pointer">
      <div className="text-center space-y-2">
        <UploadIcon className="mx-auto" />
        <p>Drop files here or click to browse</p>
      </div>
    </Label>
    <Input id="file-upload" type="file" className="sr-only" />
  </CardContent>
</Card>
```

---

## Notes

- All components use design tokens from `design/systems/tokens.json`
- Components are accessible by default (WCAG 2.1 AA)
- Mobile-responsive using Tailwind breakpoints
- Dark mode support (not currently enabled)

**Last updated**: 2025-10-06
