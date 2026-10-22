# Skill: Write Tests

## Purpose
Generate complete and useful tests for existing code.
Applies to pytest (Python/Flask) and Jest (Node.js/Express).

## How to trigger
```
Use the write-tests skill for [file or function]
```
Example:
```
Use the write-tests skill for src/services/invoice_service.py
```

## What to always cover

For each function or endpoint, generate tests for:
1. **Happy path** — works with valid data
2. **Invalid data** — what happens with incorrect inputs
3. **Empty / null case** — what happens without data
4. **Edge case** — extreme values (0, negatives, empty strings)
5. **Server error** — simulate a DB or other service failure

---

## pytest pattern (Flask)

```python
# tests/test_item_service.py
import pytest
from unittest.mock import patch, MagicMock
from src.services.item_service import create_item, get_item

class TestCrearItem:
    def test_creates_successfully_with_valid_data(self, app):
        """Happy path: creates the resource and returns a dictionary"""
        data = {'field': 'value'}
        result = create_item(data)
        assert result['field'] == 'value'
        assert 'id' in result

    def test_fails_with_missing_data(self, app):
        """Checks that it raises an exception if required fields are missing"""
        with pytest.raises(Exception):
            create_item({})

    def test_falla_si_db_no_disponible(self, app):
        """Simulates a database failure"""
        with patch('src.services.item_service.db.session.commit') as mock:
            mock.side_effect = Exception('DB error')
            with pytest.raises(Exception, match='DB error'):
                create_item({'field': 'value'})


class TestObtenerItem:
    def test_returns_existing_item(self, app):
        result = get_item(1)
        assert result is not None
        assert result['id'] == 1

    def test_returns_none_if_not_found(self, app):
        result = get_item(99999)
        assert result is None


# Base fixture (in conftest.py if it does not exist)
# @pytest.fixture
# def app():
#     from app import create_app
#     app = create_app({'TESTING': True, 'SQLALCHEMY_DATABASE_URI': 'sqlite:///:memory:'})
#     with app.app_context():
#         db.create_all()
#         yield app
#         db.drop_all()
```

### For endpoints (with test client)
```python
# tests/test_item_routes.py
def test_post_crea_recurso(client):
    response = client.post('/api/item/', json={'field': 'value'})
    assert response.status_code == 201
    assert response.json['field'] == 'value'

def test_post_fails_without_data(client):
    response = client.post('/api/item/', json={})
    assert response.status_code == 400

def test_get_returns_404_if_not_found(client):
    response = client.get('/api/item/99999')
    assert response.status_code == 404
```

---

## Jest pattern (Express)

```javascript
// tests/item.service.test.js
const itemService = require('../src/services/item.service');
const Item = require('../src/models/item.model');

jest.mock('../src/models/item.model');

describe('ItemService', () => {
  afterEach(() => jest.clearAllMocks());

  describe('create', () => {
    test('creates correctly with valid data', async () => {
      const mockData = { field: 'value' };
      Item.create.mockResolvedValue({ id: 1, ...mockData });

      const result = await itemService.create(mockData);

      expect(result.id).toBe(1);
      expect(result.field).toBe('value');
    });

    test('throws an error if the DB fails', async () => {
      Item.create.mockRejectedValue(new Error('DB error'));
      await expect(itemService.create({})).rejects.toThrow('DB error');
    });
  });

  describe('getById', () => {
    test('returns null if it does not exist', async () => {
      Item.findByPk.mockResolvedValue(null);
      const result = await itemService.getById(99999);
      expect(result).toBeNull();
    });
  });
});
```

### For endpoints with supertest
```javascript
// tests/item.routes.test.js
const request = require('supertest');
const app = require('../src/app');

describe('POST /api/item', () => {
  test('201 with valid data', async () => {
    const res = await request(app).post('/api/item').send({ field: 'value' });
    expect(res.status).toBe(201);
    expect(res.body.field).toBe('value');
  });

  test('400 without data', async () => {
    const res = await request(app).post('/api/item').send({});
    expect(res.status).toBe(400);
  });
});
```

---

## Rules when generating tests
- Each test has a single main assertion
- Names describe what is being tested: `test_retorna_404_si_no_existe`
- Use mocks to isolate external services (DB, APIs)
- Do not depend on test execution order
- Clean up state after each test (`afterEach`, fixtures)
