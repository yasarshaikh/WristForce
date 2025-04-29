/**
 * Configuration module to load and validate environment variables
 */

require('dotenv').config();

// Validate required environment variables
const requiredEnvVars = [
  'SF_USERNAME',
  'SF_PASSWORD'
];

const recommendedEnvVars = [
  'SF_CLIENT_ID',
  'SF_CLIENT_SECRET'
];

const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);
const missingRecommendedVars = recommendedEnvVars.filter(envVar => !process.env[envVar]);

if (missingEnvVars.length > 0) {
  console.error(`Error: Missing required environment variables: ${missingEnvVars.join(', ')}`);
  process.exit(1);
}

if (missingRecommendedVars.length > 0) {
  console.warn(`Warning: Missing recommended environment variables: ${missingRecommendedVars.join(', ')}`);
}

// Export configuration
module.exports = {
  // Server configuration
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // Salesforce configuration
  salesforce: {
    username: process.env.SF_USERNAME,
    password: process.env.SF_PASSWORD,
    securityToken: process.env.SF_SECURITY_TOKEN,
    clientId: process.env.SF_CLIENT_ID,
    clientSecret: process.env.SF_CLIENT_SECRET,
    loginUrl: process.env.SF_LOGIN_URL || 'https://login.salesforce.com',
    apiVersion: '57.0'
  }
};