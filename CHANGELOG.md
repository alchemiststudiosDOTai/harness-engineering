# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Initial repository structure for Harness Engineering formalization
- Comprehensive HES v1 specification (`docs/harness-engineering.md`)
- RPEQ workflow documentation (`docs/workflows/RPEQ.md`)
- Agent definitions for analysis, development, documentation, research, performance, and security
- Slash commands for context engineering, integration, QA, and utilities
- Skill definitions for codebase research, planning, execution, and QA
- **ast-grep-setup skill** (`skills/ast-grep-setup/`) - TypeScript rules for common pain points
  - Rules: no-empty-catch, no-floating-promises, no-console-log, no-debugger, no-node-in-frontend
  - Templates for sgconfig.yml and rule tests
  - Documentation for ratchet mode and CI integration
- Prompt hooks framework with examples and utilities
- Model alias configurations
- Project README explaining the Harness Engineering approach

## [0.0.1] - 2026-03-02

### Added
- Initial commit: Project bootstrap with harness engineering workflow docs and skills
