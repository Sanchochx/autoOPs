# Skill: Refactor Code

## Purpose
Improve the quality of existing code without changing its behavior.
Applies to Python/Flask and Node.js/Express.

## How to trigger
```
Use the refactor skill on [file] focusing on [optional aspect]
```
Examples:
```
Use the refactor skill on src/api/invoices.py
Use the refactor skill on src/services/user_service.py focusing on error handling
```

## Process

1. **Analyze** the current code and identify problems
2. **List** the proposed changes before making them
3. **Confirm** that the tests still pass after the refactor
4. **Document** if any public interface was changed

---

## Signs that a refactor is needed

### Very long functions (30+ lines)
```python
# ❌ Before
def process_order(data):
    # 50 lines mixing validation, logic and DB

# ✅ After
def process_order(data):
    validated_data = _validate_order(data)
    totals = _calculate_totals(validated_data)
    return _save_order(totals)
```

### Duplicated logic
```python
# ❌ Before: same validation in 3 different routes
if not data.get('email') or '@' not in data['email']:
    return jsonify({'error': 'Invalid email'}), 400

# ✅ After: extract to a util
from src.utils.validators import validate_email
```

### Inconsistent error handling
```python
# ❌ Before
try:
    result = service.create(data)
except:          # catches everything, hides bugs
    pass

# ✅ After
try:
    result = service.create(data)
except ValueError as e:
    return jsonify({'error': str(e)}), 400
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    return jsonify({'error': 'Internal error'}), 500
```

### Magic numbers and strings
```python
# ❌ Before
if user.role == 3:
    ...
if len(password) < 8:
    ...

# ✅ After
ROLE_ADMIN = 3
MIN_PASSWORD_LENGTH = 8
```

### N+1 queries
```python
# ❌ Before
orders = Order.query.all()
for order in orders:
    print(order.customer.item)  # one query per order

# ✅ After
orders = Order.query.options(joinedload(Order.customer)).all()
```

---

## Post-refactor checklist

- [ ] Existing tests still pass
- [ ] Observable behavior is identical
- [ ] No unnecessary new dependencies were introduced
- [ ] Names are clearer than before
- [ ] The code is easier to read from top to bottom

## Response format

```
ANALYSIS: [description of the problems found]

PROPOSED CHANGES:
1. [change] — [reason]
2. [change] — [reason]

[refactored code]

VERIFICATION: [confirm that the logic is equivalent]
```
