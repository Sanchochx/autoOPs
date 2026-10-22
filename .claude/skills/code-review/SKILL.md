# Skill: Code Review

## Purpose
Review code before merging or releasing to production. Applies to Python/Flask and Node.js/Express.

## How to trigger
```
Use the code-review skill on [file or folder]
```

## General checklist

### Security
- [ ] No hardcoded credentials
- [ ] User inputs are validated before use
- [ ] Queries use parameters (no string concatenation)
- [ ] Protected endpoints verify authentication/authorization

### Code quality
- [ ] Functions do a single thing
- [ ] Names are descriptive and in English
- [ ] No commented-out code without explanation
- [ ] No forgotten debug `print()` or `console.log()`
- [ ] Error handling is explicit (no `except: pass`)

### Database
- [ ] Queries are optimized (avoid N+1)
- [ ] Transactions are used where consistency is needed
- [ ] Necessary indexes are defined in the model

### Tests
- [ ] There is at least one test for the new functionality
- [ ] Edge cases are covered (empty, null, limits)
- [ ] Tests are independent of each other

### API / Endpoints
- [ ] HTTP codes are correct (200, 201, 400, 401, 404, 500)
- [ ] Responses have a consistent structure
- [ ] Errors return useful messages (no stack traces)

## Response format

```
RESULT: APPROVED / REJECTED / APPROVED WITH COMMENTS

CRITICAL ISSUES (block the merge):
- [description + line + fix suggestion]

WARNINGS (review soon):
- [description + line + suggestion]

SUGGESTIONS (optional improvements):
- [description + line]

SUMMARY: [2-3 lines with the most important points]
```

## Notes
- A single CRITICAL issue is enough to reject the PR
- Always include the line number when possible
- If the file has more than 300 lines, review it in sections
