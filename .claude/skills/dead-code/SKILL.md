# Skill: Dead Code

## Purpose
Remove code that is definitely unused, based on the previous report from
the audit skill. It operates only on code inside files — it does not remove
entire files or dependencies (that is the job of cleanup).

## Prerequisite
Run the audit skill first and review its report before using this skill.

## How to trigger
```
Use the dead-code skill on [file or folder]
Use the dead-code skill on src/services/users.py
Use the dead-code skill on src/
```

## What it removes (LOW risk by default)

### Always safe to remove
- Imports / requires declared but not used in that file
- Local variables assigned but never read
- Unused parameters of private functions
- Commented-out code blocks longer than 3 lines without explanation
- Debug `console.log()`, `console.debug()`, `print()`, `debugger`

### Remove with prior confirmation
- Private functions (`_` prefix in Python, not exported in JS) with no detected calls
- Constants defined but unused
- Classes with no detected instances or inheritance

### Never remove without explicit approval
- Exported / public functions (they may be used from outside the project)
- Anything related to auth, security or payments
- Code with comments explaining why it is there
- Functions with generic names that could be called dynamically
- Anything marked as HIGH or MEDIUM risk in the audit

## Process

1. Read the audit report (or do a quick analysis if none exists)
2. List exactly what will be removed before doing it
3. Ask for confirmation for MEDIUM risk items
4. Remove only the LOW risk items without asking
5. Verify the project still works after each removal

## Response format

```
## Dead Code — Removal plan
Based on: audit from [date] / new analysis

### Will remove automatically (LOW risk):
- [ ] `src/utils.py:45` — function `formatear_fecha_old()` with no calls
- [ ] `src/api/users.js:3` — unused `lodash` import
- [ ] `src/models/invoice.py:78` — forgotten `console.log('debug invoice')`

### Need confirmation (MEDIUM risk):
- [ ] `src/services/auth.py:102` — function `_legacy_hash()` with no detected calls
      Do you confirm removal? It may be called dynamically.

---
[after confirmation]

### Removed:
- ✓ `src/utils.py:45` — `formatear_fecha_old()` removed
- ✓ `src/api/users.js:3` — `lodash` import removed

### Tests after cleanup:
[run tests to confirm nothing broke]

### Result: [N] items removed, [N] fewer lines
```

## Rules
- Always show the plan before executing
- Never remove more than what is in the confirmed plan
- If tests fail after removing something, revert that specific change
- Document in a git comment what was removed and why
