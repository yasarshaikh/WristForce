const cache = require('memory-cache');
const { logger } = require('./logger');

// Default TTL from environment or 4 hours (in milliseconds)
const DEFAULT_TTL = (process.env.CONVERSATION_TTL || 14400) * 1000;

class ConversationCache {
  /**
   * Store a conversation ID for a user
   * @param {string} userId - Unique identifier for the user
   * @param {string} conversationId - The conversation ID to store
   * @param {number} ttl - Time to live in milliseconds (optional)
   */
  static storeConversation(userId, conversationId, ttl = DEFAULT_TTL) {
    cache.put(`conversation:${userId}`, conversationId, ttl);
    logger.debug(`Stored conversation ID ${conversationId} for user ${userId} with TTL ${ttl}ms`);
  }

  /**
   * Retrieve a conversation ID for a user
   * @param {string} userId - Unique identifier for the user
   * @returns {string|null} - The conversation ID or null if not found/expired
   */
  static getConversation(userId) {
    const conversationId = cache.get(`conversation:${userId}`);
    logger.debug(`Retrieved conversation ID ${conversationId} for user ${userId}`);
    return conversationId;
  }

  /**
   * Delete a conversation ID for a user
   * @param {string} userId - Unique identifier for the user
   */
  static deleteConversation(userId) {
    cache.del(`conversation:${userId}`);
    logger.debug(`Deleted conversation ID for user ${userId}`);
  }

  /**
   * Check if a conversation exists and is still valid
   * @param {string} userId - Unique identifier for the user
   * @returns {boolean} - True if conversation exists and is valid
   */
  static hasValidConversation(userId) {
    return cache.get(`conversation:${userId}`) !== null;
  }
}

module.exports = ConversationCache;