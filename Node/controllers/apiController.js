const salesforceService = require('../services/salesforceService');
const agentforceService = require('../services/agentforceService');
const { logger } = require('../utils/logger');

/**
 * Handle data submission to Salesforce
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
exports.sendData = async (req, res, next) => {
  try {
    const { data } = req.body;
    
    if (!data) {
      return res.status(400).json({ error: 'data object is required' });
    }
    
    const salesforceResponse = await salesforceService.sendData(data);
    
    const response = {
      success: true,
      data: salesforceResponse,
      timestamp: new Date().toISOString()
    };
    
    logger.info('Successfully processed Salesforce request');
    return res.status(200).json(response);
  } catch (error) {
    logger.error(`Error in sendData: ${error.message}`);
    next(error);
  }
};

/**
 * Start a new conversation session
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
exports.startConversation = async (req, res, next) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    
    const sessionData = await agentforceService.startSession(userId);
    
    logger.info(`Started conversation for user ${userId}`);
    return res.status(200).json(sessionData);
  } catch (error) {
    logger.error(`Error starting conversation: ${error.message}`);
    next(error);
  }
};

/**
 * Send a message in an existing conversation
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
exports.sendMessage = async (req, res, next) => {
  try {
    const { sessionId, message, sequenceId } = req.body;
    
    if (!sessionId || !message) {
      return res.status(400).json({ error: 'sessionId and message are required' });
    }
    // Pass sequenceId if provided, otherwise let the service auto-increment
    const response = await agentforceService.sendMessage(sessionId, message, sequenceId);
    
    logger.info(`Message sent in session ${sessionId}`);
    return res.status(200).json(response);
  } catch (error) {
    logger.error(`Error sending message: ${error.message}`);
    next(error);
  }
};

/**
 * End an existing conversation
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
exports.endConversation = async (req, res, next) => {
  try {
    const { sessionId } = req.body;
    
    if (!sessionId) {
      return res.status(400).json({ error: 'sessionId is required' });
    }
    
    await agentforceService.endSession(sessionId);
    
    logger.info(`Ended conversation session ${sessionId}`);
    return res.status(200).json({ success: true, message: 'Conversation ended' });
  } catch (error) {
    logger.error(`Error ending conversation: ${error.message}`);
    next(error);
  }
};