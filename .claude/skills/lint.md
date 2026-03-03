---
description: Run linting checks on the dotfiles repository
user_invocable: true
---

# Lint Dotfiles

Run the linting suite for this repository. This checks:

1. **ShellCheck** - Static analysis for shell scripts
2. **Trailing whitespace** - No trailing spaces
3. **End of file** - Files end with newline
4. **JSON validity** - Valid JSON syntax
5. **YAML validity** - Valid YAML syntax
6. **Theme validation** - Theme JSON schema

## Instructions

Run pre-commit on all files:

```bash
pre-commit run --all-files
```

If pre-commit isn't installed, run checks individually:

```bash
# ShellCheck all shell scripts
find . -name "*.sh" -o -name "*.bash" | xargs shellcheck --severity=warning

# Or just changed files
git diff --name-only --diff-filter=d | grep -E '\.(sh|bash)$' | xargs -r shellcheck --severity=warning
```

## Fixing Common Issues

**Trailing whitespace:**
```bash
sed -i '' 's/[[:space:]]*$//' <file>
```

**Missing newline:**
```bash
echo >> <file>
```

**ShellCheck issues:**
- SC2086: Quote variables - use `"$var"` not `$var`
- SC2155: Declare and assign separately - `local var; var=$(cmd)`
- SC2046: Quote command substitution - `"$(cmd)"`

After fixing, run `./test/run-tests.sh` to verify.
