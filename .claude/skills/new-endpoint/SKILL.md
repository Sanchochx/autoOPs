# Skill: New Endpoint

## Purpose
Create a complete endpoint following the project conventions.
Applies to Flask (Python) and Express (Node.js).

## How to trigger
```
Use the new-endpoint skill to create [method] /[route] that [description]
```
Example:
```
Use the new-endpoint skill to create POST /api/invoices that registers a new invoice
```

## Creation flow

Always in this order:
1. Model (if it is a new entity)
2. Service (business logic)
3. Route / Controller
4. Test
5. Update documentation

---

## Flask pattern

### Model (SQLAlchemy)
```python
# src/models/item.py
from app import db
from datetime import datetime

class ItemModel(db.Model):
    __tablename__ = 'item_tabla'

    id = db.Column(db.Integer, primary_key=True)
    # fields...
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            # fields...
        }
```

### Service
```python
# src/services/item_service.py
from src.models.item import ItemModel
from app import db

def create_item(data: dict) -> dict:
    try:
        item = ItemModel(**data)
        db.session.add(item)
        db.session.commit()
        return item.to_dict()
    except Exception as e:
        db.session.rollback()
        raise e

def get_item(id: int) -> dict | None:
    item = db.session.get(ItemModel, id)
    return item.to_dict() if item else None
```

### Route
```python
# src/api/item_routes.py
from flask import Blueprint, request, jsonify
from src.services import item_service

item_bp = Blueprint('item', __name__, url_prefix='/api/item')

@item_bp.route('/', methods=['POST'])
def create():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Data required'}), 400
    try:
        result = item_service.create_item(data)
        return jsonify(result), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@item_bp.route('/<int:id>', methods=['GET'])
def get(id):
    item = item_service.get_item(id)
    if not item:
        return jsonify({'error': 'Not found'}), 404
    return jsonify(item), 200
```

---

## Express pattern

### Model (if you use Sequelize)
```javascript
// src/models/item.model.js
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Item = sequelize.define('Item', {
  // fields...
}, { timestamps: true });

module.exports = Item;
```

### Service
```javascript
// src/services/item.service.js
const Item = require('../models/item.model');

const create = async (data) => {
  return await Item.create(data);
};

const getById = async (id) => {
  return await Item.findByPk(id);
};

module.exports = { create, getById };
```

### Route
```javascript
// src/api/item.routes.js
const express = require('express');
const router = express.Router();
const itemService = require('../services/item.service');

router.post('/', async (req, res) => {
  try {
    const item = await itemService.create(req.body);
    res.status(201).json(item);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/:id', async (req, res) => {
  const item = await itemService.getById(req.params.id);
  if (!item) return res.status(404).json({ error: 'Not found' });
  res.json(item);
});

module.exports = router;
```

---

## Standard response structure

### Success
```json
{
  "data": { ... },
  "message": "Operation successful"
}
```

### Error
```json
{
  "error": "Error description",
  "details": "Additional information (development only)"
}
```

## HTTP codes to use
| Situation | Code |
|---|---|
| Successful GET | 200 |
| Successful POST (created resource) | 201 |
| Invalid / missing data | 400 |
| Not authenticated | 401 |
| No permission | 403 |
| Not found | 404 |
| Server error | 500 |
