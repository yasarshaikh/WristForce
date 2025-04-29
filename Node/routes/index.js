const express = require('express');
const router = express.Router();
const viewController = require('../controllers/viewController');

// Frontend routes
router.get('/', viewController.renderHome);
router.get('/chat', viewController.renderChat);

module.exports = router;