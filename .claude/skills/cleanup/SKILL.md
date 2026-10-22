# Skill: Cleanup

## Purpose
Clean the project at the file and dependency level. It complements the
dead-code skill, which cleans inside files. This skill removes entire
unnecessary files and unused dependencies.

## Prerequisite
Run the audit skill first. Do not use this skill without having reviewed
the previous report.

## How to trigger
```
Use the cleanup skill on the whole project
Use the cleanup skill focusing on dependencies
Use the cleanup skill focusing on files
```

## What it cleans

### Files (always with confirmation)
- Files named `*_old.*`, `*_backup.*`, `*_copy.*`, `*.bak`, `*.tmp`
- Duplicate configuration files (e.g. two `.env.example` in different paths)
- Auto-generated files that should be in `.gitignore`
  (`__pycache__/`, `node_modules/`, `*.pyc`, `dist/`, `build/`)
- Completely empty folders
- Logs and temporary files committed by mistake

### Dependencies — Python
```bash
# Detect unused dependencies
pip install pipreqs
pipreqs . --print   # shows only the ones actually used

# Compare with the current requirements.txt
# Those in requirements.txt but not in pipreqs → candidates for removal
```

### Dependencies — Node.js
```bash
# Detect unused dependencies
npx depcheck

# The result shows:
# Unused dependencies: [list]
# Unused devDependencies: [list]
# Missing dependencies: [list]
```

### .gitignore
- Verify that generated files/folders are in `.gitignore`
- Add common missing entries according to the detected stack

## Process

1. List everything that will be removed or modified
2. Confirm with the user before any file removal
3. For dependencies: show the command to run, run it, show the result
4. Update `.gitignore` if necessary
5. Verify the project still runs after the cleanup

## Response format

```
## Cleanup — Full plan

### Files to remove (require confirmation):
- [ ] `src/utils_old.py` — old version of utils.py (127 lines)
- [ ] `config/database_backup.js` — manual backup from 2024-11-03
- [ ] `notes.txt` — personal notes in the project root

### Unused dependencies detected:

Python (pipreqs):
- [ ] `moment` in requirements.txt — not imported in any .py
- [ ] `xlrd` in requirements.txt — not imported in any .py

Node.js (depcheck):
- [ ] `underscore` in dependencies — not required in any .js
- [ ] `mocha` in devDependencies — project uses Jest

### .gitignore — suggested missing entries:
- `.env.local`
- `*.log`
- `coverage/`

---
[after confirmation]

### Executed:
- ✓ Files removed: [N]
- ✓ Dependencies removed: pip uninstall moment xlrd / npm uninstall underscore
- ✓ .gitignore updated

### Final state:
- Files removed: [N]
- Dependencies removed: [N]
- Project size before: [X MB] → after: [Y MB]
```

## Critical rules
- Never remove `node_modules/` or `venv/` if they are not in `.gitignore` — add them there first
- Never uninstall production dependencies without confirming the project runs afterwards
- If in doubt about a file, do NOT remove it — mark it as "review manually"
- Always make a clean commit before running cleanup so it is easy to revert
- Real `.env` files are never removed — only duplicate `.env.example` files
