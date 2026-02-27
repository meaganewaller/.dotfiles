#!/usr/bin/env python3
"""
provenance-scan.py - Scan cues and generate provenance manifest.

Scans all cues from CLAUDE_HOME/cues and CLAUDE_PROJECT_DIR/.claude/cues,
extracts provenance blocks from frontmatter, generates JSON manifest.

Usage:
    provenance-scan.py [-o FILE] [--cue-roots DIRS]

Options:
    -o, --output FILE     Output file (default: stdout)
    --cue-roots DIRS      Colon-separated cue directories
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any


def parse_frontmatter(content: str) -> tuple[dict[str, Any], str]:
    """Extract YAML frontmatter and body from markdown content."""
    if not content.startswith('---'):
        return {}, content

    parts = content.split('---', 2)
    if len(parts) < 3:
        return {}, content

    frontmatter_text = parts[1].strip()
    body = parts[2].strip()

    # Simple YAML parser for our specific format (no external deps)
    frontmatter = parse_yaml_simple(frontmatter_text)
    return frontmatter, body


def parse_yaml_simple(text: str) -> dict[str, Any]:
    """
    Parse simple YAML without external dependencies.
    Handles our specific frontmatter format with provenance blocks.
    Uses a recursive descent approach with proper indentation tracking.
    """
    lines = text.split('\n')
    # Add line numbers for debugging, filter empty and comment-only lines
    indexed_lines = []
    for i, line in enumerate(lines):
        # Keep track of original line but skip pure comments and empty lines
        stripped = line.strip()
        if stripped and not stripped.startswith('#'):
            indexed_lines.append((i, line))

    return _parse_mapping(indexed_lines, 0)[0]


def _get_indent(line: str) -> int:
    """Get indentation level of a line."""
    return len(line) - len(line.lstrip())


def _parse_mapping(lines: list[tuple[int, str]], base_indent: int) -> tuple[dict[str, Any], int]:
    """Parse a YAML mapping (dict) at the given indentation level."""
    result: dict[str, Any] = {}
    i = 0

    while i < len(lines):
        _, line = lines[i]
        indent = _get_indent(line)
        stripped = line.strip()

        # Stop if we've dedented
        if indent < base_indent:
            break

        # Skip if more indented (handled by recursion)
        if indent > base_indent:
            i += 1
            continue

        # Remove inline comments
        if '#' in stripped:
            comment_pos = stripped.find('#')
            # Make sure it's not inside a string
            if comment_pos > 0:
                stripped = stripped[:comment_pos].strip()

        # Parse key: value
        if ':' in stripped:
            colon_pos = stripped.find(':')
            key = stripped[:colon_pos].strip()
            rest = stripped[colon_pos + 1:].strip()

            if rest:
                # Handle folded scalar (>)
                if rest == '>':
                    value, consumed = _parse_folded_scalar(lines[i + 1:], indent)
                    result[key] = value
                    i += 1 + consumed
                    continue
                else:
                    # Simple inline value
                    result[key] = rest
            else:
                # Value is on next line(s) - could be list or nested mapping
                child_lines = []
                j = i + 1
                while j < len(lines):
                    _, child_line = lines[j]
                    child_indent = _get_indent(child_line)
                    if child_indent > indent:
                        child_lines.append(lines[j])
                        j += 1
                    else:
                        break

                if child_lines:
                    first_child = child_lines[0][1].strip()
                    if first_child.startswith('- '):
                        # It's a list
                        result[key], _ = _parse_sequence(child_lines, _get_indent(child_lines[0][1]))
                    else:
                        # It's a nested mapping
                        result[key], _ = _parse_mapping(child_lines, _get_indent(child_lines[0][1]))
                    i = j
                    continue

        i += 1

    return result, i


def _parse_sequence(lines: list[tuple[int, str]], base_indent: int) -> tuple[list[Any], int]:
    """Parse a YAML sequence (list) at the given indentation level."""
    result: list[Any] = []
    i = 0

    while i < len(lines):
        _, line = lines[i]
        indent = _get_indent(line)
        stripped = line.strip()

        # Stop if we've dedented
        if indent < base_indent:
            break

        if stripped.startswith('- '):
            # List item
            rest = stripped[2:].strip()

            if rest and ':' in rest:
                # It's a mapping starting on this line (e.g., "- key: value")
                # The content indent is the dash position + 2
                content_indent = indent + 2

                # Collect all lines for this list item (same or greater indent)
                item_lines = []
                # Add first key:value with proper indentation
                first_key, _, first_val = rest.partition(':')
                first_val = first_val.strip()

                j = i + 1
                while j < len(lines):
                    _, next_line = lines[j]
                    next_indent = _get_indent(next_line)
                    next_stripped = next_line.strip()

                    # Stop at another list item at same level
                    if next_indent == indent and next_stripped.startswith('- '):
                        break
                    # Stop if we've fully dedented past the list
                    if next_indent < indent:
                        break
                    # Continue if it's content of this list item
                    if next_indent >= content_indent:
                        item_lines.append(lines[j])
                        j += 1
                    else:
                        break

                # Build the mapping manually to handle the first key:value
                item: dict[str, Any] = {}
                first_key = first_key.strip()

                if first_val:
                    item[first_key] = first_val
                elif item_lines:
                    # First key has a nested value
                    # Find lines that belong to the first key's value
                    first_key_content = []
                    remaining_lines = []
                    in_first_key = True
                    first_key_indent = None

                    for il in item_lines:
                        _, il_line = il
                        il_indent = _get_indent(il_line)
                        il_stripped = il_line.strip()

                        if first_key_indent is None:
                            first_key_indent = il_indent

                        # Check if this is a new key at the same level as first_key would be
                        if ':' in il_stripped and il_indent == content_indent:
                            in_first_key = False

                        if in_first_key:
                            first_key_content.append(il)
                        else:
                            remaining_lines.append(il)

                    if first_key_content:
                        first_child = first_key_content[0][1].strip()
                        if first_child.startswith('- '):
                            item[first_key], _ = _parse_sequence(
                                first_key_content, _get_indent(first_key_content[0][1])
                            )
                        else:
                            item[first_key], _ = _parse_mapping(
                                first_key_content, _get_indent(first_key_content[0][1])
                            )

                    item_lines = remaining_lines

                # Parse remaining lines as more key:value pairs
                if item_lines:
                    more_props, _ = _parse_mapping(item_lines, content_indent)
                    item.update(more_props)

                result.append(item)
                i = j
                continue

            elif rest and ':' not in rest:
                # Simple scalar value
                result.append(rest)
                i += 1
                continue

            else:
                # Empty dash or complex nested structure
                child_lines = []
                j = i + 1
                while j < len(lines):
                    _, next_line = lines[j]
                    next_indent = _get_indent(next_line)
                    next_stripped = next_line.strip()
                    if next_indent <= indent:
                        if next_stripped.startswith('- '):
                            break
                        break
                    child_lines.append(lines[j])
                    j += 1

                if child_lines:
                    first_child = child_lines[0][1].strip()
                    if first_child.startswith('- '):
                        item, _ = _parse_sequence(child_lines, _get_indent(child_lines[0][1]))
                    else:
                        item, _ = _parse_mapping(child_lines, _get_indent(child_lines[0][1]))
                    result.append(item)
                i = j
                continue

        i += 1

    return result, i


def _parse_folded_scalar(lines: list[tuple[int, str]], parent_indent: int) -> tuple[str, int]:
    """Parse a folded scalar (lines following >)."""
    parts = []
    consumed = 0
    base_indent = None

    for _, line in lines:
        indent = _get_indent(line)
        if indent <= parent_indent:
            break
        if base_indent is None:
            base_indent = indent
        parts.append(line.strip())
        consumed += 1

    return ' '.join(parts), consumed


def scan_cue(cue_dir: Path) -> dict[str, Any] | None:
    """Scan a single cue directory and extract provenance info."""
    cue_file = cue_dir / 'cue.md'
    if not cue_file.exists():
        return None

    content = cue_file.read_text()
    frontmatter, body = parse_frontmatter(content)

    result = {
        'path': str(cue_dir),
        'name': cue_dir.name,
        'cue_file': str(cue_file),
        'has_provenance': 'provenance' in frontmatter,
        'frontmatter': {
            k: v for k, v in frontmatter.items()
            if k not in ('provenance',)
        },
    }

    if 'provenance' in frontmatter:
        result['provenance'] = frontmatter['provenance']

    return result


def build_inverted_indices(cues: list[dict]) -> dict[str, Any]:
    """Build policy->cues and control->cues indices."""
    policy_to_cues: dict[str, list[str]] = {}
    control_to_cues: dict[str, list[str]] = {}

    for cue in cues:
        if not cue.get('has_provenance'):
            continue

        prov = cue.get('provenance', {})
        cue_name = cue['name']

        # Index by policy
        policies = prov.get('policy', [])
        if isinstance(policies, list):
            for policy in policies:
                if isinstance(policy, dict):
                    uri = policy.get('uri', '')
                else:
                    uri = str(policy)
                if uri:
                    policy_to_cues.setdefault(uri, []).append(cue_name)

        # Index by control
        controls = prov.get('controls', [])
        if isinstance(controls, list):
            for control in controls:
                if isinstance(control, dict):
                    ctrl_id = control.get('id', '')
                else:
                    ctrl_id = str(control)
                if ctrl_id:
                    control_to_cues.setdefault(ctrl_id, []).append(cue_name)

    return {
        'by_policy': policy_to_cues,
        'by_control': control_to_cues,
    }


def compute_stats(cues: list[dict]) -> dict[str, Any]:
    """Compute coverage statistics."""
    total = len(cues)
    with_provenance = sum(1 for c in cues if c.get('has_provenance'))
    without_provenance = total - with_provenance

    # Collect all controls and policies
    all_controls: set[str] = set()
    all_policies: set[str] = set()

    for cue in cues:
        if not cue.get('has_provenance'):
            continue
        prov = cue.get('provenance', {})

        for policy in prov.get('policy', []):
            if isinstance(policy, dict):
                all_policies.add(policy.get('uri', ''))
            else:
                all_policies.add(str(policy))

        for control in prov.get('controls', []):
            if isinstance(control, dict):
                all_controls.add(control.get('id', ''))
            else:
                all_controls.add(str(control))

    all_policies.discard('')
    all_controls.discard('')

    return {
        'total_cues': total,
        'with_provenance': with_provenance,
        'without_provenance': without_provenance,
        'coverage_percent': round(with_provenance / total * 100, 1) if total else 0,
        'unique_policies': len(all_policies),
        'unique_controls': len(all_controls),
    }


def get_cue_roots() -> list[Path]:
    """Get cue directories from environment."""
    roots = []

    # CLAUDE_HOME/cues
    claude_home = os.environ.get('CLAUDE_HOME', os.path.expanduser('~/.claude'))
    roots.append(Path(claude_home) / 'cues')

    # CLAUDE_PROJECT_DIR/.claude/cues
    project_dir = os.environ.get('CLAUDE_PROJECT_DIR', '')
    if project_dir:
        roots.append(Path(project_dir) / '.claude' / 'cues')

    return roots


def main() -> int:
    parser = argparse.ArgumentParser(description='Scan cues and generate provenance manifest')
    parser.add_argument('-o', '--output', help='Output file (default: stdout)')
    parser.add_argument('--cue-roots', help='Colon-separated cue directories')
    parser.add_argument('--dotfiles-root', help='Dotfiles root for relative paths')
    args = parser.parse_args()

    # Determine cue roots
    if args.cue_roots:
        cue_roots = [Path(p) for p in args.cue_roots.split(':')]
    else:
        cue_roots = get_cue_roots()

    # Also check dotfiles if provided
    if args.dotfiles_root:
        dotfiles_cues = Path(args.dotfiles_root) / 'home' / '.claude' / 'cues'
        if dotfiles_cues.exists() and dotfiles_cues not in cue_roots:
            cue_roots.append(dotfiles_cues)

    # Scan all cues
    cues = []
    seen_names: set[str] = set()

    for root in cue_roots:
        if not root.exists():
            continue

        for cue_dir in sorted(root.iterdir()):
            if not cue_dir.is_dir():
                continue
            if cue_dir.name in seen_names:
                continue  # Dedupe (project overrides global)

            cue_data = scan_cue(cue_dir)
            if cue_data:
                cues.append(cue_data)
                seen_names.add(cue_dir.name)

    # Build manifest
    manifest = {
        'generated_at': datetime.now().isoformat(),
        'cue_roots': [str(r) for r in cue_roots if r.exists()],
        'cues': cues,
        'indices': build_inverted_indices(cues),
        'stats': compute_stats(cues),
    }

    # Output
    output_json = json.dumps(manifest, indent=2)

    if args.output:
        Path(args.output).write_text(output_json)
    else:
        print(output_json)

    return 0


if __name__ == '__main__':
    sys.exit(main())
