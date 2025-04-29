const axios = require('axios');
const { logger } = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');
const salesforceService = require('./salesforceService');

class AgentforceService {
  constructor() {
    this.baseUrl = 'https://api.salesforce.com/einstein/ai-agent/v1';
    this.sessions = new Map();
  }

  /**
   * Get authorization headers for API calls
   * @returns {Promise<Object>} Headers object with authorization
   */
  async getHeaders() {
    const accessToken = await salesforceService.getAccessToken();
    return {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    };
  }

  /**
   * Start a new session with the Einstein AI Agent
   * @param {string} userId - Unique identifier for the user
   * @returns {Promise<Object>} - Session information
   */
  async startSession(userId) {
    try {
      const headers = await this.getHeaders();
      const agentId = process.env.AGENT_ID;
      const domainUrl = process.env.MY_DOMAIN_URL;
      const url = `${this.baseUrl}/agents/${agentId}/sessions`;
      const body = {
        externalSessionKey: uuidv4(),
        instanceConfig: {
          endpoint: domainUrl
        },
        streamingCapabilities: {
          chunkTypes: ["Text"]
        },
        bypassUser: true
      };
      const response = await axios.post(url, body, { headers });
      // Store session info
      this.sessions.set(userId, {
        sessionId: response.data.sessionId,
        messageCount: 0
      });
      logger.info(`Started new session for user ${userId}: ${response.data.sessionId}`);
      return response.data;
    } catch (error) {
      if (error.response?.status === 401) {
        logger.warn('Access token expired. Retrying session start...');
        return this.startSession(userId);
      }
      logger.error(`Error starting session: ${error.message}`);
      if (error.response) {
        logger.error('Agentforce error response:', error.response.data);
      }
      throw error;
    }
  }

  /**
   * Send a message to the Einstein AI Agent (new /messages endpoint, sequenceId managed)
   * @param {string} sessionId - The active session ID
   * @param {string} message - Message text to send
   * @param {number} [sequenceId] - Optional: sequence number for this message
   * @returns {Promise<Object>} - Agent's response
   */
  async sendMessage(sessionId, message, sequenceId = null) {
    try {
      const headers = await this.getHeaders();
      const url = `${this.baseUrl}/sessions/${sessionId}/messages`;
      // Sequence management
      let seq = sequenceId;
      // If not provided, auto-increment per session
      const sessionInfo = Array.from(this.sessions.values()).find(s => s.sessionId === sessionId);
      if (!seq) {
        if (sessionInfo) {
          sessionInfo.messageCount = (sessionInfo.messageCount || 0) + 1;
          seq = sessionInfo.messageCount;
        } else {
          // Fallback: start from 1
          seq = 1;
        }
      } else if (sessionInfo) {
        sessionInfo.messageCount = seq; // sync up
      }
      const body = {
        message: {
          sequenceId: seq,
          type: 'Text',
          text: message
        }
      };
      const response = await axios.post(url, body, { headers });
      logger.info(`Sent message (seq ${seq}) in session ${sessionId}`);
      return response.data;
    } catch (error) {
      if (error.response?.status === 401) {
        logger.warn('Access token expired. Retrying message send...');
        return this.sendMessage(sessionId, message, sequenceId);
      }
      logger.error(`Error sending message: ${error.message}`);
      if (error.response) {
        logger.error('Agentforce error response:', error.response.data);
      }
      throw error;
    }
  }

  /**
   * End a session with the Einstein AI Agent
   * @param {string} sessionId - The session ID to end
   * @returns {Promise<void>}
   */
  async endSession(sessionId) {
    try {
      const headers = await this.getHeaders();
      const url = `${this.baseUrl}/sessions/${sessionId}`;
      await axios.delete(url, {
        headers: {
          ...headers,
          'x-session-end-reason': 'UserRequest'
        }
      });
      this.sessions.delete(sessionId);
      logger.info(`Ended session ${sessionId}`);
    } catch (error) {
      if (error.response?.status === 401) {
        logger.warn('Access token expired. Retrying session end...');
        return this.endSession(sessionId);
      }
      logger.error(`Error ending session: ${error.message}`);
      if (error.response) {
        logger.error('Agentforce error response:', error.response.data);
      }
      throw error;
    }
  }
}

module.exports = new AgentforceService();