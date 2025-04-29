const express = require('express');
const router = express.Router();
const apiController = require('../controllers/apiController');
const { apiAuth } = require('../middleware/auth');

// API endpoints
router.post('/send-data', apiAuth, apiController.sendData);

// Einstein AI Agent conversation endpoints
router.post('/conversation/start', apiAuth, apiController.startConversation);
router.post('/conversation/message', apiAuth, apiController.sendMessage);
router.post('/conversation/end', apiAuth, apiController.endConversation);

module.exports = router;