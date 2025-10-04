# Spec-Flow v1.0.0 🚀

**Release Date**: 2025-10-03

We're excited to announce the first public release of Spec-Flow, a comprehensive workflow toolkit for building high-quality features with Claude Code through Spec-Driven Development.

## 🎯 What is Spec-Flow?

Spec-Flow transforms how you build software with AI assistants. Instead of ad-hoc conversations that lose context, forget decisions, and skip quality gates, Spec-Flow provides a **repeatable, auditable workflow** from idea to production.

## 🌟 Key Features

### 📝 Spec-Driven Workflow
- **10 workflow phases**: spec → clarify → plan → tasks → analyze → implement → optimize → preview → staging → production
- **Automated progression**: Use `/flow` to orchestrate the entire journey with manual gates
- **Auditable artifacts**: Every phase produces documented outputs (specs, plans, reports, release notes)

### 🎯 Context Management
- **Phase-based token budgets**: 75k (planning), 100k (implementation), 125k (optimization)
- **Auto-compaction**: Automatically reduces context when approaching limits
- **Checkpoint tracking**: NOTES.md preserves decisions and progress for context restoration

### ✅ Quality Gates
- **Analysis phase**: Cross-artifact consistency checks, risk assessment
- **Optimization phase**: Code review, performance benchmarks, accessibility audits
- **Manual gates**: Preview (UI/UX validation), Staging validation (E2E tests, metrics)

### 🤖 Specialist Agents
- **6 pre-configured agents**: Backend, Frontend, QA, Code Reviewer, Debugger, CI/CD
- **Smart routing**: `/route-agent` delegates tasks to appropriate specialists
- **Extensible**: Add custom agents for your tech stack

### 📚 Comprehensive Documentation
- **Getting Started Tutorial**: 30-minute walkthrough for your first feature
- **Installation Guides**: Platform-specific (Windows, macOS, Linux)
- **Use Cases**: 8 project types (web apps, APIs, CLIs, mobile, design systems, infrastructure, ML)
- **Troubleshooting**: Solutions for common issues

### 🛠️ Automation Scripts
- **Dual-platform support**: PowerShell (Windows/cross-platform) and Bash (macOS/Linux)
- **Prerequisites checker**: Validates Git, PowerShell/Bash, Python, Claude Code
- **Token calculator**: Estimates context usage before hitting limits
- **Context compactor**: Phase-aware reduction (90%/60%/30% strategies)
- **Feature scaffolding**: Creates directory structure, templates, branch

## 📦 What's Included

### Directory Structure
```
Spec-Flow/
├── .claude/
│   ├── agents/          # 6 specialist agent briefs
│   ├── commands/        # 10+ slash command definitions
│   └── settings.example.json
├── .spec-flow/
│   ├── scripts/
│   │   ├── powershell/  # Windows/cross-platform automation
│   │   └── bash/        # macOS/Linux automation
│   ├── templates/       # Markdown scaffolds (15+ templates)
│   └── memory/          # Constitution, roadmap, design inspirations
├── specs/
│   └── 001-example-feature/  # Complete Dark Mode Toggle example
├── docs/                # 7 documentation pages
└── .github/
    ├── workflows/       # CI validation (scripts, docs, JSON, YAML)
    └── labels.yml       # 40+ standardized issue labels
```

### Example Feature
- **Dark Mode Toggle**: Complete workflow from spec to production
  - Specification with FR/NFR requirements
  - 28 tasks across 5 implementation phases
  - Performance benchmarks (145ms avg, 27% better than target)
  - WCAG 2.1 AA accessibility compliance
  - Cross-browser testing matrix
  - Release notes for v1.2.0

### Documentation
- [`docs/getting-started.md`](docs/getting-started.md) - Step-by-step tutorial
- [`docs/installation.md`](docs/installation.md) - Platform-specific setup
- [`docs/architecture.md`](docs/architecture.md) - Workflow state machine diagram
- [`docs/commands.md`](docs/commands.md) - Command reference
- [`docs/troubleshooting.md`](docs/troubleshooting.md) - Common issues
- [`docs/use-cases.md`](docs/use-cases.md) - 8 project type examples
- [`CLAUDE.md`](CLAUDE.md) - AI agent guidance

### Community Files
- **SECURITY.md**: Vulnerability reporting policy with response timelines
- **CODE_OF_CONDUCT.md**: Community standards and reporting process
- **CONTRIBUTING.md**: Contribution guidelines, branching strategy, release process
- **Issue Templates**: Bug reports and enhancement proposals
- **PR Template**: Checklist for pull requests

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/marcusgoll/Spec-Flow.git
cd Spec-Flow

# 2. Configure Claude Code permissions
cp .claude/settings.example.json .claude/settings.local.json
# Edit and add your project paths

# 3. Verify prerequisites
pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json

# 4. Start your first feature
# In Claude Code:
/spec-flow "Dark mode toggle"
/plan
/tasks
/implement
```

**Next**: Follow the [Getting Started Tutorial](docs/getting-started.md)

## 💡 Use Cases

Spec-Flow adapts to different project types:
- **Web Applications**: Full-stack features with frontend + backend coordination
- **API Services**: Contract-first development with automated testing
- **CLI Tools**: Command structure definition to distribution
- **Mobile Apps**: Offline-first architecture with platform-specific handling
- **Design Systems**: Component libraries with accessibility built-in
- **Infrastructure**: Terraform modules with security scanning
- **Documentation Sites**: Content management with versioning
- **ML Projects**: Experiment tracking with reproducible pipelines

See [Use Cases](docs/use-cases.md) for detailed examples.

## 🎓 Philosophy

Spec-Flow is built on four core principles:

1. **Specification first** - Every artifact traces back to explicit requirements
2. **Agents as teammates** - Commands encode expectations so assistants stay aligned
3. **Context discipline** - Token budgets are measured, compacted, and recycled
4. **Ship in stages** - Staging and production have dedicated rituals with human gates

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to set up your development environment
- Branching strategy and commit conventions
- Pull request checklist
- Release process

## 🐛 Known Issues

None reported yet! Please [open an issue](https://github.com/marcusgoll/Spec-Flow/issues) if you encounter any problems.

## 📝 Changelog

### Added
- Complete Spec-Flow workflow with 10 phases
- 6 specialist agent briefs (Backend, Frontend, QA, Code Reviewer, Debugger, CI/CD)
- 10+ slash command definitions
- Dual-platform automation scripts (PowerShell + Bash)
- 15+ Markdown templates for specs, plans, tasks, reports
- Context management with phase-based budgets and auto-compaction
- Complete working example (Dark Mode Toggle)
- 7 documentation pages (getting-started, installation, architecture, commands, troubleshooting, use-cases, CLAUDE.md)
- GitHub Actions CI workflow (validates scripts, docs, JSON, YAML)
- 40+ standardized issue labels
- Security policy (SECURITY.md)
- Code of conduct (CODE_OF_CONDUCT.md)
- Contribution guidelines (CONTRIBUTING.md)
- Issue and PR templates

## 🙏 Acknowledgments

Built with inspiration from:
- Anthropic's Claude Code for enabling AI-assisted workflows
- The open-source community for best practices and patterns
- Early adopters who tested and provided feedback

## 📄 License

Released under the [MIT License](LICENSE).

## 🔗 Links

- **Repository**: https://github.com/marcusgoll/Spec-Flow
- **Issues**: https://github.com/marcusgoll/Spec-Flow/issues
- **Discussions**: https://github.com/marcusgoll/Spec-Flow/discussions
- **Documentation**: [docs/](docs/)
- **Example**: [specs/001-example-feature/](specs/001-example-feature/)

---

**Built by [@marcusgoll](https://github.com/marcusgoll)**

🌟 **Star this repo** if you find Spec-Flow useful!

📢 **Share on X.com** with #SpecFlow to help others discover structured AI-assisted development!
