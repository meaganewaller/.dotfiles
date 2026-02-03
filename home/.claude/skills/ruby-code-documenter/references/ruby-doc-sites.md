## `references/ruby-doc-sites.md`

````markdown
# Documentation Sites for Ruby Projects

This project supports documentation delivery via:
- YARD HTML docs
- a static docs site (optional) for guides and API references

## Option A: YARD HTML Only (Simple)

Good for:
- internal gems
- code-reference browsing

Command:
- `bundle exec yard doc`

Output:
- `doc/` folder

## Option B: Guides + Reference Site

Use when you need:
- onboarding guides
- tutorials
- architecture docs
- operational playbooks

Recommended structure:
```text
docs/
  getting-started.md
  architecture/
  api/
  operations/
````

Static site options:

* MkDocs (simple, fast)
* Docusaurus (richer, heavier)
* VitePress (nice dev experience)

YARD can coexist:

* host YARD output at `/reference`
* host docs site at `/`

## Search

If docs are more than ~20 pages, add search:

* built-in (MkDocs Material)
* Algolia (Docusaurus)
* or a lightweight client-side index

## Don’t Overbuild

If you don’t have a docs owner, don’t build a cathedral.
Prefer:

* good README
* solid YARD
* a small docs/ folder
