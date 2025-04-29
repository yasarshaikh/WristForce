require('dotenv').config();
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');

async function getAccessToken() {
  const url = `${process.env.SF_LOGIN_URL}/services/oauth2/token`;
  const params = new URLSearchParams();
  params.append('grant_type', 'client_credentials');
  params.append('client_id', process.env.SF_CLIENT_ID);
  params.append('client_secret', process.env.SF_CLIENT_SECRET);

  const headers = { 'Content-Type': 'application/x-www-form-urlencoded' };

  const response = await axios.post(url, params, { headers });
  return response.data.access_token;
}

async function createSession(accessToken) {
  const agentId = process.env.AGENT_ID; // Set this in your .env
  const domainUrl = process.env.MY_DOMAIN_URL; // Set this in your .env
  const url = `https://api.salesforce.com/einstein/ai-agent/v1/agents/${agentId}/sessions`;
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
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${accessToken}`
  };
  const response = await axios.post(url, body, { headers });
  return response.data;
}

async function sendMessage(sessionId, accessToken, sequenceId, text) {
  const url = `https://api.salesforce.com/einstein/ai-agent/v1/sessions/${sessionId}/messages`;
  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${accessToken}`
  };
  const body = {
    message: {
      sequenceId: sequenceId,
      type: 'Text',
      text: text
    }
  };
  const response = await axios.post(url, body, { headers });
  return response.data;
}

async function endSession(sessionId, accessToken) {
  const url = `https://api.salesforce.com/einstein/ai-agent/v1/sessions/${sessionId}`;
  const headers = {
    'x-session-end-reason': 'UserRequest',
    'Authorization': `Bearer ${accessToken}`
  };
  const response = await axios.delete(url, { headers });
  return response.data;
}

(async () => {
  try {
    const token = await getAccessToken();
    console.log('Access Token:', token);
    const session = await createSession(token);
    console.log('Session Response:', JSON.stringify(session, null, 2));
    const sessionId = session.sessionId;
    // Send a message to the session
    const messageResponse = await sendMessage(sessionId, token, 1, 'Show me my leads.');
    console.log('Send Message Response:', JSON.stringify(messageResponse, null, 2));
    // End the session
    const endResponse = await endSession(sessionId, token);
    console.log('End Session Response:', JSON.stringify(endResponse, null, 2));
  } catch (error) {
    if (error.response) {
      console.error('Error Response:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
  }
})();
