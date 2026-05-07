#!/usr/bin/env bash

# Claude aliases

# Claude Bedrock integration and MCP configuration

# Prevent accidental AWS Bedrock charges with Claude Code
# Documented in: https://docs.anthropic.com/en/docs/claude-code/amazon-bedrock
# and https://docs.anthropic.com/en/docs/claude-code/settings
unset CLAUDE_CODE_USE_BEDROCK  # Disables Bedrock when unset (official variable)
unset AWS_BEARER_TOKEN_BEDROCK # Removes Bedrock API key if set (official variable)

# Quick test command - validates knowledge integration
alias claude-test='claude -p "What is AI harness agnosticism and which two harnesses are currently configured?"'
