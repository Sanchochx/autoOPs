# Skill: Audit

## Purpose
Generate a complete report on the state of the project before doing any
cleanup. It modifies nothing — it only analyzes and reports. Always run this
skill before using dead-code or cleanup.

## How to trigger
```
Use the audit skill on the whole project
Use the audit skill on src/
```

## What it analyzes

### Code
- Functions and methods declared but never called
- Variables declared but never used
- Imports / requires that are not used in the file
- Function parameters that are never read
- Commented-out blocks longer than 3 lines (possible dead code)
- Forgotten debug `console.log`, `print`, `debugger`

### Files
- Files with no reference from the rest of the project
- Files with names like `_old`, `_backup`, `_copy`, `bak`, `tmp`
- Duplicate files with identical or nearly identical content
- Empty folders or folders containing only a `.gitkeep`

### Dependencies
- Packages in `package.json` (dependencies / devDependencies) not imported in any file
- Libraries in `requirements.txt` not imported in any `.py` file
- Dependencies installed but not listed in the manifest

### General quality
- Files longer than 300 lines (candidates to split)
- Functions longer than 40 lines (candidates to refactor)
- Files with unresolved TODO / FIXME
- API routes without associated tests

## Response format

```
# Audit Report — [Project name]
Date: [date]
Files analyzed: [N]

---

## DEAD CODE
| Type | File | Line | Description | Risk when removing |
|------|------|------|-------------|--------------------|
| Function | src/utils.py | 45 | `formatear_fecha()` with no calls | LOW |
| Import | src/api/users.js | 3 | `lodash` imported, unused | LOW |
| Variable | src/models/invoice.py | 12 | `TAX_OLD = 0.16` unused | LOW |

## SUSPICIOUS FILES
| File | Reason | Suggested action |
|------|--------|------------------|
| src/utils_old.py | Name suggests an old version | Verify and remove |
| src/temp.js | No references | Verify and remove |

## UNUSED DEPENDENCIES
| Package | File | Suggested action |
|---------|------|------------------|
| moment | package.json | Uninstall if unused |
| requests | requirements.txt | Verify before removing |

## LARGE FILES (candidates to split)
| File | Lines | Suggestion |
|------|-------|------------|
| src/api/routes.js | 450 | Split by module |

## UNRESOLVED TODOs
| File | Line | Comment |
|------|------|---------|
| src/services/auth.py | 78 | TODO: implement refresh token |

---

## SUMMARY
- Dead code found: [N items]
- Suspicious files: [N]
- Unused dependencies: [N]
- Pending TODOs: [N]

## SUGGESTED NEXT STEPS
1. Review the dead code table and confirm which items to remove
2. Run: `Use the dead-code skill on src/` to remove the confirmed items
3. Run: `Use the cleanup skill on the project` to clean up files and deps
```

## Important rules
- Do NOT modify any file during the audit
- If a function looks unused but has a generic name (e.g. `handle`, `process`),
  mark it as MEDIUM risk — it may be called dynamically
- Mark as HIGH risk anything related to auth, payments or security
- Always include the line number to ease manual verification
