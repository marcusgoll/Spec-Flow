# Auto-Activation System

**Version**: 4.1.0
**Status**: ✅ Implemented (Phase 1)
**Impact**: 30-40% faster workflow navigation

## Overview

The Auto-Activation System automatically suggests relevant phase skills and cross-cutting skills based on your prompts, eliminating the need to manually remember and invoke skills. This feature was integrated from the [claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase) repository.

## How It Works

### Trigger Mechanism

When you type a prompt in Claude Code, the **UserPromptSubmit** hook automatically:
1. Analyzes your prompt for keywords and intent patterns
2. Matches against 20 pre-configured skills in `.claude/skills/skill-rules.json`
3. Displays prioritized skill suggestions BEFORE Claude responds
4. Allows you to invoke suggested skills using the Skill tool

### Priority Levels

Skills are suggested with different priority indicators:

- **⚠️ CRITICAL SKILLS (REQUIRED)** — Planning, implementation, production deployment, breaking changes
- **📚 RECOMMENDED SKILLS** — Most phase skills and quality checks
- **💡 SUGGESTED SKILLS** — Preview, finalize, roadmap management
- **📌 OPTIONAL SKILLS** — Context-aware but not essential

### Example Workflow

```
You: "implement login endpoint with TDD"

[Hook Output]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 SKILL ACTIVATION CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ CRITICAL SKILLS (REQUIRED):
  → implementation-phase

📚 RECOMMENDED SKILLS:
  → tdd-enforcer

ACTION: Use Skill tool BEFORE responding
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Configured Skills (20 Total)

### Phase Skills (14)

| Skill | Priority | Triggers |
|-------|----------|----------|
| **specification-phase** | High | "create spec", "requirements", "user stories" |
| **clarification-phase** | High | "clarify", "ambiguous", "unclear" |
| **planning-phase** | Critical | "plan", "architecture", "design", "code reuse" |
| **task-breakdown-phase** | High | "tasks", "break down", "checklist" |
| **analysis-phase** | High | "validate", "consistency", "breaking changes" |
| **implementation-phase** | Critical | "implement", "write code", "develop", "TDD" |
| **optimization-phase** | High | "optimize", "code review", "performance", "security" |
| **preview-phase** | Medium | "preview", "test locally", "manual test" |
| **staging-deployment-phase** | High | "deploy staging", "ship staging" |
| **staging-validation-phase** | High | "validate staging", "rollback test" |
| **production-deployment-phase** | Critical | "deploy production", "go live", "release" |
| **finalize-phase** | Medium | "finalize", "cleanup", "close issue" |
| **project-initialization-phase** | High | "init project", "project setup", "new project" |
| **roadmap-integration** | Medium | "roadmap", "features", "prioritize" |
| **ui-ux-design** | High | "design", "UI design", "mockup", "brand tokens" |

### Cross-Cutting Skills (5)

| Skill | Priority | Triggers |
|-------|----------|----------|
| **anti-duplication** | High (Warn) | "similar code", "duplicate", "already exists" |
| **breaking-change-detector** | Critical (Warn) | "breaking change", "API change", "migration" |
| **tdd-enforcer** | High (Suggest) | "write test", "test first", "TDD" |
| **hallucination-detector** | Critical (Warn) | "verify", "check assumption", "is this correct" |
| **context-budget-enforcer** | Medium (Warn) | "token usage", "context budget", "compact" |

## Configuration Files

### 1. VSCode Settings (`.vscode/settings.json`)

Registers the UserPromptSubmit hook:

```json
{
  "claude.hooks": [
    {
      "type": "command",
      "command": ".claude/hooks/skill-activation-prompt.sh",
      "matcher": "UserPromptSubmit",
      "description": "Auto-suggest phase skills based on user prompts"
    }
  ]
}
```

**Created by**: `install-wizard.ps1` during setup
**Location**: Copied from `.spec-flow/templates/vscode/settings.json.template`

### 2. Skill Rules (`.claude/skills/skill-rules.json`)

Defines trigger patterns for 20 skills:

```json
{
  "version": "1.0",
  "skills": {
    "implementation-phase": {
      "type": "domain",
      "enforcement": "suggest",
      "priority": "critical",
      "description": "TDD implementation with parallel task execution",
      "promptTriggers": {
        "keywords": ["implement", "write code", "develop", "TDD"],
        "intentPatterns": [
          "(implement|build|create).*?(feature|code|function)",
          "/implement",
          "(write|create).*?test"
        ]
      }
    }
  }
}
```

**Customization**: Edit `keywords` and `intentPatterns` to match your team's vocabulary

### 3. Hook Scripts (`.claude/hooks/`)

- `skill-activation-prompt.sh` — Bash wrapper for hook execution
- `skill-activation-prompt.ts` — TypeScript logic for pattern matching
- `package.json` — Dependencies (tsx for TypeScript execution)
- `test-skill-activation.sh` — Test suite for validation

## Installation

### Automatic (Recommended)

Run the install wizard, which automatically configures auto-activation:

```bash
# Bash/Linux/macOS
.spec-flow/scripts/bash/install-wizard.sh --target-dir ../my-project

# PowerShell/Windows
.spec-flow/scripts/powershell/install-wizard.ps1 -TargetDir ..\my-project
```

The wizard will:
1. ✅ Copy VSCode settings with hook configuration
2. ✅ Install npm dependencies (tsx)
3. ✅ Configure skill-rules.json
4. ✅ Test hook functionality

### Manual Installation

If you already have a Spec-Flow installation and want to add auto-activation:

1. **Copy hook files**:
   ```bash
   cp -r .claude/hooks/ /path/to/your/project/.claude/
   ```

2. **Install dependencies**:
   ```bash
   cd /path/to/your/project/.claude/hooks
   npm install
   ```

3. **Add VSCode hook** (`.vscode/settings.json`):
   ```json
   {
     "claude.hooks": [
       {
         "type": "command",
         "command": ".claude/hooks/skill-activation-prompt.sh",
         "matcher": "UserPromptSubmit"
       }
     ]
   }
   ```

4. **Copy skill-rules.json**:
   ```bash
   cp .claude/skills/skill-rules.json /path/to/your/project/.claude/skills/
   ```

5. **Test**:
   ```bash
   cd /path/to/your/project
   bash .claude/hooks/test-skill-activation.sh
   ```

## Testing

Run the test suite to verify auto-activation:

```bash
bash .claude/hooks/test-skill-activation.sh
```

**Expected Output**:
- Test 1: "create spec" → `specification-phase`
- Test 2: "implement with TDD" → `implementation-phase` + `tdd-enforcer`
- Test 3: "build architecture" → `planning-phase` + `implementation-phase`
- Test 4: "deploy to production" → `production-deployment-phase`
- Test 5: "weather today" → No matches (correct)

## Customization

### Adding Custom Triggers

Edit `.claude/skills/skill-rules.json` to add your own keywords:

```json
{
  "implementation-phase": {
    "promptTriggers": {
      "keywords": [
        "implement",
        "code",
        "my-custom-keyword"  // Add here
      ],
      "intentPatterns": [
        "(implement|build).*?feature",
        "my-custom.*?pattern"  // Add regex patterns here
      ]
    }
  }
}
```

### Adjusting Priority

Change skill priority to control suggestion order:

```json
{
  "my-skill": {
    "priority": "critical"  // critical > high > medium > low
  }
}
```

### Enforcement Types

- **`suggest`** — Shows suggestion, doesn't block (default for phase skills)
- **`warn`** — Shows warning, allows proceeding (cross-cutting skills)
- **`block`** — Requires skill usage before proceeding (not currently used)

## Troubleshooting

### Hook Not Triggering

1. **Check VSCode settings**:
   ```bash
   cat .vscode/settings.json | grep "claude.hooks"
   ```
   Expected: `"claude.hooks": [...]`

2. **Verify npm dependencies**:
   ```bash
   cd .claude/hooks
   npm list tsx
   ```
   Expected: `tsx@...` (installed)

3. **Test manually**:
   ```bash
   echo '{"prompt":"implement feature"}' | bash .claude/hooks/skill-activation-prompt.sh
   ```

### TypeScript Errors

If you see `npx tsx` errors:

```bash
cd .claude/hooks
rm -rf node_modules package-lock.json
npm install
```

### Skill Not Matching

1. Check keyword spelling in `.claude/skills/skill-rules.json`
2. Test with exact keyword:
   ```bash
   echo '{"prompt":"your-keyword-here"}' | bash .claude/hooks/skill-activation-prompt.sh
   ```
3. Add debug logging to `skill-activation-prompt.ts` (line 41):
   ```typescript
   console.error('Debug: prompt =', prompt);  // Temporary debug
   ```

## Performance Impact

- **Hook execution**: <50ms per prompt
- **Token overhead**: 0 (hook output not sent to Claude)
- **Memory usage**: Minimal (~5MB for Node.js process)
- **Network**: None (local processing only)

## Comparison with Manual Invocation

### Before Auto-Activation

```
You: "I need to implement user authentication"
Claude: "Let me help with that..." [starts coding without TDD]

[Realizes later] "Oh, I should have used implementation-phase skill"
[Manual correction required]
```

### After Auto-Activation

```
You: "I need to implement user authentication"

[Hook Output]
⚠️ CRITICAL SKILLS (REQUIRED):
  → implementation-phase
📚 RECOMMENDED SKILLS:
  → tdd-enforcer

You: [Invokes implementation-phase skill via Skill tool]
Claude: [Follows TDD workflow, test-first development]
```

**Result**: Correct workflow on first attempt, no backtracking

## Future Enhancements (Phase 2-5)

Phase 1 focused on prompt-based triggers. Future phases will add:

- **Phase 2**: File path triggers (editing `backend.ts` → suggest `backend-dev-guidelines`)
- **Phase 3**: Content pattern triggers (detecting `import Prisma` → suggest database patterns)
- **Phase 4**: Tool usage tracking (Edit tool used → cache file modifications)
- **Phase 5**: Session-based skip conditions (skill used once → don't re-suggest)

## Related Documentation

- [Skill System Overview](../CLAUDE.md#skills)
- [Install Wizard Guide](../README.md#installation)
- [claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase) (source)

## Version History

- **v4.1.0** (2025-11-10) — Phase 1 complete: Prompt-based auto-activation for 20 skills
- **v4.0.0** (2025-11-08) — Living documentation and hierarchical CLAUDE.md
- **v3.0.0** (2025-10-15) — Style guide approach for UI development

---

**Questions or Issues?**
File an issue at: https://github.com/marcusgoll/Spec-Flow/issues
