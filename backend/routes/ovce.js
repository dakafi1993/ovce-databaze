const express = require('express');
const { body, param, validationResult } = require('express-validator');
const Ovce = require('../models/Ovce');
const { Op } = require('sequelize');

const router = express.Router();

// Validation middleware
const validateOvce = [
  body('usi_cislo')
    .notEmpty()
    .withMessage('Ušní číslo je povinné')
    .isLength({ min: 1, max: 50 })
    .withMessage('Ušní číslo musí mít 1-50 znaků'),
  body('datum_narozeni')
    .isISO8601()
    .withMessage('Neplatné datum narození')
    .isBefore()
    .withMessage('Datum narození nemůže být v budoucnosti'),
  body('plemeno')
    .notEmpty()
    .withMessage('Plemeno je povinné')
    .isLength({ min: 1, max: 100 })
    .withMessage('Plemeno musí mít 1-100 znaků'),
  body('kategorie')
    .optional()
    .isIn(['BER', 'BAH', 'JEH', 'OTHER'])
    .withMessage('Neplatná kategorie'),
  body('pohlavi')
    .optional()
    .isIn(['Samec', 'Samice', 'Nezn'])
    .withMessage('Neplatné pohlaví'),
  body('recognition_accuracy')
    .optional()
    .isFloat({ min: 0.0, max: 1.0 })
    .withMessage('Recognition accuracy musí být mezi 0.0 a 1.0')
];

const validateUuid = [
  param('id').isUUID().withMessage('Neplatné ID')
];

// Helper function to handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array(),
      timestamp: new Date().toISOString()
    });
  }
  next();
};

// GET /api/ovce - Get all sheep
router.get('/', async (req, res) => {
  try {
    const {
      page = 1,
      limit = 50,
      search,
      plemeno,
      kategorie,
      pohlavi,
      sortBy = 'created_at',
      sortOrder = 'DESC'
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    // Search filters
    if (search) {
      where[Op.or] = [
        { usi_cislo: { [Op.iLike]: `%${search}%` } },
        { poznamka: { [Op.iLike]: `%${search}%` } }
      ];
    }

    if (plemeno) where.plemeno = plemeno;
    if (kategorie) where.kategorie = kategorie;
    if (pohlavi) where.pohlavi = pohlavi;

    const { count, rows } = await Ovce.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
      distinct: true
    });

    res.json({
      data: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(count / limit)
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching ovce:', error);
    res.status(500).json({
      error: 'Failed to fetch sheep data',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/ovce/:id - Get specific sheep
router.get('/:id', validateUuid, handleValidationErrors, async (req, res) => {
  try {
    const ovce = await Ovce.findByPk(req.params.id);

    if (!ovce) {
      return res.status(404).json({
        error: 'Sheep not found',
        id: req.params.id,
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      data: ovce,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching ovce:', error);
    res.status(500).json({
      error: 'Failed to fetch sheep',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// POST /api/ovce - Create new sheep
router.post('/', validateOvce, handleValidationErrors, async (req, res) => {
  try {
    // Check if usi_cislo already exists
    const existingOvce = await Ovce.findByUsiCislo(req.body.usi_cislo);
    if (existingOvce) {
      return res.status(409).json({
        error: 'Sheep with this ear number already exists',
        usi_cislo: req.body.usi_cislo,
        timestamp: new Date().toISOString()
      });
    }

    const ovce = await Ovce.create(req.body);

    res.status(201).json({
      data: ovce,
      message: 'Sheep created successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error creating ovce:', error);
    
    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({
        error: 'Validation error',
        details: error.errors.map(e => e.message),
        timestamp: new Date().toISOString()
      });
    }

    res.status(500).json({
      error: 'Failed to create sheep',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// PUT /api/ovce/:id - Update sheep
router.put('/:id', validateUuid, validateOvce, handleValidationErrors, async (req, res) => {
  try {
    const ovce = await Ovce.findByPk(req.params.id);

    if (!ovce) {
      return res.status(404).json({
        error: 'Sheep not found',
        id: req.params.id,
        timestamp: new Date().toISOString()
      });
    }

    // Check if new usi_cislo conflicts with existing ones
    if (req.body.usi_cislo && req.body.usi_cislo !== ovce.usi_cislo) {
      const existingOvce = await Ovce.findByUsiCislo(req.body.usi_cislo);
      if (existingOvce) {
        return res.status(409).json({
          error: 'Sheep with this ear number already exists',
          usi_cislo: req.body.usi_cislo,
          timestamp: new Date().toISOString()
        });
      }
    }

    await ovce.update(req.body);

    res.json({
      data: ovce,
      message: 'Sheep updated successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error updating ovce:', error);

    if (error.name === 'SequelizeValidationError') {
      return res.status(400).json({
        error: 'Validation error',
        details: error.errors.map(e => e.message),
        timestamp: new Date().toISOString()
      });
    }

    res.status(500).json({
      error: 'Failed to update sheep',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// DELETE /api/ovce/:id - Delete sheep
router.delete('/:id', validateUuid, handleValidationErrors, async (req, res) => {
  try {
    const ovce = await Ovce.findByPk(req.params.id);

    if (!ovce) {
      return res.status(404).json({
        error: 'Sheep not found',
        id: req.params.id,
        timestamp: new Date().toISOString()
      });
    }

    await ovce.destroy();

    res.json({
      message: 'Sheep deleted successfully',
      id: req.params.id,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error deleting ovce:', error);
    res.status(500).json({
      error: 'Failed to delete sheep',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/ovce/stats/summary - Get statistics
router.get('/stats/summary', async (req, res) => {
  try {
    const total = await Ovce.count();
    const byKategorie = await Ovce.findAll({
      attributes: ['kategorie', [Ovce.sequelize.fn('COUNT', '*'), 'count']],
      group: ['kategorie']
    });
    const byPlemeno = await Ovce.findAll({
      attributes: ['plemeno', [Ovce.sequelize.fn('COUNT', '*'), 'count']],
      group: ['plemeno'],
      order: [[Ovce.sequelize.fn('COUNT', '*'), 'DESC']],
      limit: 10
    });

    res.json({
      total,
      by_kategorie: byKategorie,
      by_plemeno: byPlemeno,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({
      error: 'Failed to fetch statistics',
      details: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;