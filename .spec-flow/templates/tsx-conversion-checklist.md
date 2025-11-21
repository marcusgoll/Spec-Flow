# TSX Conversion Checklist

Use this checklist to track HTML blueprint → TSX component conversion progress.

## Phase 1: Basic Conversion

- [ ] HTML structure converted to JSX syntax
- [ ] `class=` changed to `className=`
- [ ] Self-closing tags use JSX format (`<img />`, not `<img>`)
- [ ] Inline styles converted to objects or Tailwind classes
- [ ] Comments use `{/* */}` syntax
- [ ] All components compile without TypeScript errors

## Phase 2: Make Functional

- [ ] TypeScript interfaces defined for props
- [ ] State management added (useState, useContext, etc.)
- [ ] API clients connected (useQuery, useMutation, etc.)
- [ ] Event handlers implemented (onClick, onChange, onSubmit)
- [ ] Form validation logic added (client-side)
- [ ] Routing configured (Next.js Link components)
- [ ] Server vs client component decisions made

## Phase 3: Production Polish

- [ ] Reusable components extracted and documented
- [ ] Performance optimized (React.memo, useMemo, lazy loading)
- [ ] Error boundaries added for graceful failures
- [ ] Loading states refined (skeletons, spinners)
- [ ] Mobile responsive tested (375px+ viewports)
- [ ] Accessibility enhanced (keyboard nav, ARIA, focus management)
- [ ] Design tokens imported and used consistently

## Validation (Optional)

- [ ] Run `bash .spec-flow/scripts/bash/validate-tsx-conversion.sh`
- [ ] Run `bash .spec-flow/scripts/bash/check-conversion-edge-cases.sh`
- [ ] All validation checks pass or warnings addressed

## Quality Gates

- [ ] ESLint passes with no errors
- [ ] TypeScript strict mode enabled and passing
- [ ] All tests passing (unit + integration)
- [ ] Lighthouse score ≥85 for performance and accessibility
- [ ] Manual testing completed (happy path + edge cases)

---

**Status:** Track your progress by checking off items as you complete them.

**Iteration Tips:**
- Convert one screen at a time, don't try to do everything at once
- Test each phase before moving to the next
- Use the edge cases checklist for detailed guidance
- Validate frequently to catch issues early

**Skip Options:**
- Use `--skip-validation` to skip validation scripts
- Use `--no-guidance` to skip edge case prompts
- Use `--auto` to skip all iteration gates
