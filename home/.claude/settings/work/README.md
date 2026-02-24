# Work profile

Settings for **work** (e.g. Gusto, AWS). This profile is applied on top of **common** when the work profile is selected in Claude Code.

## What this profile changes

### `basics.jsonc`

- **Model**: Uses AWS Bedrock Opus 4.5: `us.anthropic.claude-opus-4-5-20251101-v1:0` (overrides common’s `opus`).
- **AWS**: Sets `AWS_PROFILE=bedrock-users`, `AWS_REGION=us-west-2`, and enables Claude Code Bedrock via `CLAUDE_CODE_USE_BEDROCK=true`.
- **AWS auth refresh**: Command to re-auth when needed: `aws sso login --profile $AWS_PROFILE` (after a failed `aws sts get-caller-identity`).
- **Gusto**: `GUSTO_CLAUDE_SETUP=true` and model env vars for Bedrock Opus.
- **Statusline**: Overrides common with `npx -y @owloops/claude-powerline@latest --style=powerline`.

### `plugins.jsonc`

Enables Gusto Claude Code plugins:

- **gusto-setup-wizard** – Setup/onboarding for Claude Code at Gusto.
- **gusto-architecture** – Architecture skills (e.g. GraphQL, Packwerk, Sidekiq, Kafka, RSpec, security, frontend, etc.).

Hooks and permissions from **common** still apply; work only adds/overrides basics and plugins.

## When to use

Choose the **work** profile when:

- Working in work repos (e.g. Gusto codebases)
- You need Bedrock-backed Opus 4.5
- You want Gusto architecture and setup plugins and the work statusline

Ensure AWS SSO is logged in for the `bedrock-users` profile so Bedrock requests succeed.
