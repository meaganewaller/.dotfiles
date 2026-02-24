#!/usr/bin/env node
/**
 * Claude Code PreToolUse hook that blocks destructive rm commands
 * and suggests using `trash` instead for recoverable deletions.
 *
 * Based on https://github.com/zcaceres/claude-rm-rf
 */

/**
 * Strip quoted strings to avoid false positives (e.g., echo "rm test")
 */
function stripQuotes(str) {
    // Remove double-quoted strings (handling escaped quotes)
    let result = str.replace(/"(?:[^"\\]|\\.)*"/g, '""');
    // Remove single-quoted strings (no escapes in bash single quotes)
    result = result.replace(/'[^']*'/g, "''");
    return result;
  }

  /**
   * Check if command contains destructive file deletion patterns
   */
  function containsDestructiveCommand(command) {
    const sanitized = stripQuotes(command);

    // Allow git rm (version-controlled, recoverable)
    if (/\bgit\s+rm\b/.test(sanitized)) {
      return false;
    }

    // Check for sh -c / bash -c / zsh -c with destructive commands inside
    const subshellMatch = sanitized.match(/\b(?:sh|bash|zsh|dash)\s+-c\s+["']([^"']+)["']/);
    if (subshellMatch && containsDestructiveCommand(subshellMatch[1])) {
      return true;
    }

    // Patterns that indicate actual destructive command usage
    const destructivePatterns = [
      // Commands at start of line or after operators
      /(?:^|&&|\|\||;|\||`|\$\()\s*rm\b/,
      /(?:^|&&|\|\||;|\||`|\$\()\s*shred\b/,
      /(?:^|&&|\|\||;|\||`|\$\()\s*unlink\b/,

      // Absolute/relative paths
      /(?:^|&&|\|\||;|\||`|\$\()\s*\/bin\/rm\b/,
      /(?:^|&&|\|\||;|\||`|\$\()\s*\.\/rm\b/,

      // Privilege escalation and wrappers
      /\bsudo\s+rm\b/,
      /\bsudo\s+\/bin\/rm\b/,
      /\bxargs\s+rm\b/,
      /\bxargs\s+.*\brm\b/,
      /\bcommand\s+rm\b/,
      /\benv\s+rm\b/,

      // Backslash to bypass aliases
      /(?:^|&&|\|\||;|\||`|\$\()\s*\\rm\b/,

      // find with -delete or -exec rm
      /\bfind\b[^|;]*\s+-delete\b/,
      /\bfind\b[^|;]*-exec\s+rm\b/,
    ];

    return destructivePatterns.some(pattern => pattern.test(sanitized));
  }

  async function main() {
    // Read JSON input from stdin
    let input = '';
    for await (const chunk of process.stdin) {
      input += chunk;
    }

    try {
      const data = JSON.parse(input);
      const command = data?.tool_input?.command;

      if (!command || typeof command !== 'string') {
        // No command to check, allow through
        process.exit(0);
      }

      if (containsDestructiveCommand(command)) {
        // Block the command
        const message = `
  Blocked: Destructive file deletion detected.

  Use \`trash\` instead of \`rm\` for recoverable deletions:
    trash <file-or-directory>

  The \`trash\` command moves files to system trash instead of permanently deleting them.
  `.trim();

        console.error(message);
        process.exit(2); // Exit code 2 blocks the tool use
      }

      // Allow the command
      process.exit(0);

    } catch (err) {
      // JSON parse error - allow through (don't block on hook errors)
      process.exit(0);
    }
  }

  main();
