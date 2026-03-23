# ============================================================
# Layer: dev
#
# Policy: Add dev CLIs via mise when possible; keep Brewfile entries for
# casks, language servers only packaged as brew, or host deps mise does not cover.
#
# Purpose:
# - Development tooling that supports active software projects.
# - Host-level tools that are required even in a container-first setup.
#
# Scope:
# - Language-specific linters or formatters that run locally.
# - Local developer workflow helpers (watchers, task runners, etc.).
# - CLI tools tightly coupled to current development stacks.
#
# Explicitly Excludes:
# - Databases
# - Background services (no brew services).
# - Cloud / Kubernetes tooling (belongs in infra layer).
# - Creative or media tools (belongs in creative layer).
# - Experimental tools (belongs in experimental layer).
#
# Philosophy:
# The host machine remains thin.
# If a tool can live inside a container, prefer that.
# This layer exists only for tools that genuinely improve
# host-side developer ergonomics.
#
# Promotion Rule:
# Anything added here must support an active project.
# If unused for 30 days, it should be removed or moved to experimental.
# ============================================================

cask "postico"

brew "colima"
brew "qemu"

brew "bash-language-server"
brew "lua-language-server"
brew "fish-lsp"
brew "libpq"

cask "claude"
cask "claude-code"
