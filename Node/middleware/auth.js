/**
 * Authentication middleware
 * This is a simple API key authentication for demonstration purposes.
 * In a production environment, you would use a more robust authentication method.
 */

const { logger } = require('../utils/logger');

/**
 * Middleware to authenticate API requests
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next middleware function
 */
const apiAuth = (req, res, next) => {
  // Skip authentication in development mode
  if (process.env.NODE_ENV === 'development') {
    return next();
  }
  
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey || apiKey !== process.env.API_KEY) {
    logger.warn(`Unauthorized API access attempt: ${req.ip}`);
    return res.status(401).json({ error: { message: 'Unauthorized', status: 401 } });
  }
  
  next();
};

module.exports = { apiAuth };