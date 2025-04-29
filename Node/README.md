# Salesforce & Agentforce Integration App

A Node.js Express application that integrates with Salesforce and Agentforce APIs, designed for deployment on Render.com.

## Features

- **API Endpoint `/send-data`**: Accepts JSON input from external sources and forwards to Salesforce and Agentforce
- **Salesforce Integration**: Authenticates via OAuth2 and sends data to Salesforce
- **Agentforce API Integration**: Manages conversations and sends messages to the Agentforce AI
- **Conversation ID Management**: Caches conversation IDs for 2-4 hours per user/session
- **Slack Webhook Integration**: Receives Slack messages and forwards them via FCM
- **FCM Push Notifications**: Sends notifications to mobile devices
- **Frontend Demo**: Simple UI to test the API endpoints

## Setup

### Prerequisites

- Node.js 14 or higher
- Salesforce Developer Account
- Agentforce API access
- Firebase project (for FCM)

### Installation

1. Clone the repository
2. Install dependencies:
   ```
   npm install
   ```
3. Create a `.env` file based on `.env.example`
4. Start the server:
   ```
   npm start
   ```

## Environment Variables

Copy `.env.example` to `.env` and fill in your credentials:

```
# Salesforce Credentials
SF_LOGIN_URL=https://login.salesforce.com
SF_USERNAME=your_salesforce_username
SF_PASSWORD=your_salesforce_password
SF_CLIENT_ID=your_salesforce_client_id
SF_CLIENT_SECRET=your_salesforce_client_secret

# Agentforce API
AGENTFORCE_BASE_URL=https://api.salesforce.com/v1/agent
AGENTFORCE_TOKEN=your_agentforce_token

# Firebase Cloud Messaging
FCM_SERVER_KEY=your_fcm_server_key
FCM_SENDER_ID=your_fcm_sender_id

# App Configuration
PORT=3000
NODE_ENV=development

# Conversation Cache Settings
CONVERSATION_TTL=14400 # 4 hours in seconds
```

## API Endpoints

### `/api/send-data` (POST)

Sends data to Salesforce and a message to Agentforce.

**Request Body:**

```json
{
  "userId": "user123",
  "message": "create a meeting",
  "data": {
    "objectType": "Contact",
    "operation": "create",
    "fields": {
      "FirstName": "John",
      "LastName": "Doe",
      "Email": "john.doe@example.com"
    }
  }
}
```

### `/api/end-conversation` (POST)

Ends a conversation with Agentforce.

**Request Body:**

```json
{
  "userId": "user123"
}
```

### `/api/slack-webhook` (POST)

Receives Slack webhook notifications and forwards them via FCM.
