#!/usr/bin/env python3
"""
Scan cues for provenance metadata and generate a manifest.

Usage:
    provenance-scan.py [-o OUTPUT] [--cue-dirs DIR...]

Scans all cue.md files for YAML frontmatter containing provenance blocks.
Generates a JSON manifest with per-cue data and inverted indices.
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path


def parse_yaml_frontmatter(content: str) -> tuple[dict, str]:
    """Extract YAML frontmatter from markdown content.

    Returns (frontmatter_dict, body_content).
    """
    if not content.startswith('---'):
        return {}, content

    # Find the closing ---
    end_match = re.search(r'\n---\s*\n', content[3:])
    if not end_match:
        return {}, content

    yaml_str = content[3:3 + end_match.start()]
    body = content[3 + end_match.end():]

    # Simple YAML parser for our specific format
    return parse_simple_yaml(yaml_str), body


def parse_simple_yaml(yaml_str: str) -> dict:
    """Parse simple YAML without external dependencies.

    Handles our specific frontmatter format:
    - Simple key: value pairs
    - Nested objects
    - Lists with - items
    - Multi-line strings with >
    """
    result = {}
    lines = yaml_str.split('\n')
    i = 0

    while i < len(lines):
        line = lines[i]

        # Skip empty lines and comments
        if not line.strip() or line.strip().startswith('#'):
            i += 1
            continue

        # Determine indentation
        indent = len(line) - len(line.lstrip())
        content = line.strip()

        # Only process top-level keys (indent == 0)
        if indent == 0 and ':' in content:
            key, _, value = content.partition(':')
            key = key.strip()
            value = value.strip()

            if value:
                result[key] = value
            else:
                # Collect nested content
                nested_lines = []
                i += 1
                while i < len(lines):
                    next_line = lines[i]
                    if not next_line.strip():
                        nested_lines.append(next_line)
                        i += 1
                        continue
                    next_indent = len(next_line) - len(next_line.lstrip())
                    if next_indent <= 0 and next_line.strip():
                        break
                    nested_lines.append(next_line)
                    i += 1

                nested_content = '\n'.join(nested_lines)
                result[key] = parse_nested_yaml(nested_content, 2)
                continue

        i += 1

    return result


def parse_nested_yaml(content: str, base_indent: int) -> any:
    """Parse nested YAML content."""
    lines = content.split('\n')

    # Check if it's a list
    first_content_line = next((l for l in lines if l.strip()), '')
    if first_content_line.strip().startswith('- '):
        return parse_yaml_list(lines, base_indent)

    # Otherwise it's an object
    result = {}
    i = 0

    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue

        indent = len(line) - len(line.lstrip())
        if indent < base_indent:
            break

        content = line.strip()
        if ':' in content and not content.startswith('- '):
            key, _, value = content.partition(':')
            key = key.strip()
            value = value.strip()

            if value.startswith('>'):
                # Multi-line string
                multi_lines = []
                i += 1
                while i < len(lines):
                    next_line = lines[i]
                    if not next_line.strip():
                        i += 1
                        continue
                    next_indent = len(next_line) - len(next_line.lstrip())
                    if next_indent <= indent:
                        break
                    multi_lines.append(next_line.strip())
                    i += 1
                result[key] = ' '.join(multi_lines)
                continue
            elif value:
                result[key] = value
            else:
                # Nested content
                nested_lines = []
                i += 1
                while i < len(lines):
                    next_line = lines[i]
                    if not next_line.strip():
                        nested_lines.append(next_line)
                        i += 1
                        continue
                    next_indent = len(next_line) - len(next_line.lstrip())
                    if next_indent <= indent:
                        break
                    nested_lines.append(next_line)
                    i += 1

                nested_content = '\n'.join(nested_lines)
                result[key] = parse_nested_yaml(nested_content, indent + 2)
                continue

        i += 1

    return result


def parse_yaml_list(lines: list, base_indent: int) -> list:
    """Parse a YAML list."""
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue

        indent = len(line) - len(line.lstrip())
        if indent < base_indent:
            break

        content = line.strip()
        if content.startswith('- '):
            item_content = content[2:]

            # Check if it's a simple value or object
            if ':' in item_content:
                # Object item
                key, _, value = item_content.partition(':')
                item = {key.strip(): value.strip() if value.strip() else None}

                # Collect rest of object
                i += 1
                while i < len(lines):
                    next_line = lines[i]
                    if not next_line.strip():
                        i += 1
                        continue
                    next_indent = len(next_line) - len(next_line.lstrip())
                    next_content = next_line.strip()

                    # Check if we're still in this object
                    if next_content.startswith('- ') and next_indent <= indent:
                        break
                    if next_indent <= indent and not next_content.startswith('- '):
                        break

                    if ':' in next_content:
                        k, _, v = next_content.partition(':')
                        k = k.strip()
                        v = v.strip()

                        if v.startswith('>'):
                            # Multi-line string
                            multi_lines = []
                            i += 1
                            while i < len(lines):
                                ml = lines[i]
                                if not ml.strip():
                                    i += 1
                                    continue
                                ml_indent = len(ml) - len(ml.lstrip())
                                if ml_indent <= next_indent:
                                    break
                                multi_lines.append(ml.strip())
                                i += 1
                            item[k] = ' '.join(multi_lines)
                            continue
                        elif v:
                            item[k] = v
                        else:
                            # Nested list
                            nested_lines = []
                            i += 1
                            while i < len(lines):
                                nl = lines[i]
                                if not nl.strip():
                                    nested_lines.append(nl)
                                    i += 1
                                    continue
                                nl_indent = len(nl) - len(nl.lstrip())
                                if nl_indent <= next_indent:
                                    break
                                nested_lines.append(nl)
                                i += 1
                            item[k] = parse_yaml_list(nested_lines, next_indent + 2)
                            continue
                    i += 1

                result.append(item)
                continue
            else:
                # Simple value
                result.append(item_content)

        i += 1

    return result


def scan_cue_file(cue_path: Path, repo_root: Path) -> dict:
    """Scan a single cue file for provenance metadata."""
    try:
        content = cue_path.read_text()
    except Exception as e:
        return {'error': str(e)}

    frontmatter, _ = parse_yaml_frontmatter(content)

    # Extract basic cue metadata
    cue_data = {
        'path': str(cue_path.relative_to(repo_root)),
        'cue_name': cue_path.parent.name,
        'pattern': frontmatter.get('pattern'),
        'commands': frontmatter.get('commands'),
        'files': frontmatter.get('files'),
        'scope': frontmatter.get('scope'),
        'description': frontmatter.get('description'),
    }

    # Extract provenance
    provenance = frontmatter.get('provenance', {})
    if provenance:
        cue_data['provenance'] = {
            'policies': provenance.get('policy', []),
            'controls': provenance.get('controls', []),
            'verified': provenance.get('verified'),
            'rationale': provenance.get('rationale'),
        }
    else:
        cue_data['provenance'] = None

    return cue_data


def find_cue_files(cue_dirs: list[Path]) -> list[Path]:
    """Find all cue.md files in the given directories."""
    cue_files = []
    for cue_dir in cue_dirs:
        if cue_dir.exists():
            cue_files.extend(cue_dir.rglob('cue.md'))
    return sorted(cue_files)


def build_manifest(cues: list[dict], repo_root: Path) -> dict:
    """Build the complete manifest with inverted indices."""
    # Build inverted indices
    policy_to_cues = defaultdict(list)
    control_to_cues = defaultdict(list)

    cues_with_provenance = 0
    cues_without_provenance = 0
    stale_cues = []

    today = datetime.now().date()

    for cue in cues:
        if cue.get('error'):
            continue

        prov = cue.get('provenance')
        if prov:
            cues_with_provenance += 1

            # Build policy index
            for policy in prov.get('policies') or []:
                if isinstance(policy, dict):
                    uri = policy.get('uri', '')
                else:
                    uri = str(policy)
                if uri:
                    policy_to_cues[uri].append(cue['cue_name'])

            # Build control index
            for control in prov.get('controls') or []:
                if isinstance(control, dict):
                    control_id = control.get('id', '')
                else:
                    control_id = str(control)
                if control_id:
                    control_to_cues[control_id].append({
                        'cue': cue['cue_name'],
                        'name': control.get('name', '') if isinstance(control, dict) else '',
                        'justifications': control.get('justifications', []) if isinstance(control, dict) else [],
                    })

            # Check staleness
            verified = prov.get('verified')
            if verified:
                try:
                    verified_date = datetime.strptime(str(verified), '%Y-%m-%d').date()
                    days_old = (today - verified_date).days
                    if days_old > 90:
                        stale_cues.append({
                            'cue': cue['cue_name'],
                            'verified': str(verified),
                            'days_old': days_old,
                        })
                except ValueError:
                    pass
        else:
            cues_without_provenance += 1

    total_cues = cues_with_provenance + cues_without_provenance
    coverage = (cues_with_provenance / total_cues * 100) if total_cues > 0 else 0

    return {
        'generated_at': datetime.now().isoformat(),
        'repo_root': str(repo_root),
        'statistics': {
            'total_cues': total_cues,
            'cues_with_provenance': cues_with_provenance,
            'cues_without_provenance': cues_without_provenance,
            'coverage_percent': round(coverage, 1),
            'unique_policies': len(policy_to_cues),
            'unique_controls': len(control_to_cues),
            'stale_cues': len(stale_cues),
        },
        'cues': cues,
        'policy_index': dict(policy_to_cues),
        'control_index': dict(control_to_cues),
        'stale_cues': stale_cues,
    }


def main():
    parser = argparse.ArgumentParser(description='Scan cues for provenance metadata')
    parser.add_argument('-o', '--output', help='Output file (default: stdout)')
    parser.add_argument('--cue-dirs', nargs='*', help='Cue directories to scan')
    parser.add_argument('--repo-root', help='Repository root (default: auto-detect)')
    args = parser.parse_args()

    # Determine repo root
    if args.repo_root:
        repo_root = Path(args.repo_root)
    else:
        # Try to find repo root from current directory
        repo_root = Path.cwd()
        while repo_root != repo_root.parent:
            if (repo_root / '.git').exists():
                break
            repo_root = repo_root.parent

    # Determine cue directories
    if args.cue_dirs:
        cue_dirs = [Path(d) for d in args.cue_dirs]
    else:
        # Default locations
        home = Path.home()
        cue_dirs = [
            home / '.claude' / 'cues',
            repo_root / 'home' / '.claude' / 'cues',
        ]

    # Find and scan cues
    cue_files = find_cue_files(cue_dirs)
    cues = [scan_cue_file(f, repo_root) for f in cue_files]

    # Build manifest
    manifest = build_manifest(cues, repo_root)

    # Output
    output = json.dumps(manifest, indent=2)
    if args.output:
        Path(args.output).write_text(output)
        print(f"Wrote manifest to {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == '__main__':
    main()
