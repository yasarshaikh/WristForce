# WristForce - Salesforce CRM & Agentforce Metadata

## Overview
WristForce repository stores core metadata for the Salesforce CRM and Agentforce applications. It includes configurations, custom objects, and Apex classes essential for the functionality of these applications. While some agent-related metadata is not stored here, the repository contains related Apex classes and flows used by Agentforce.

## Agentforce Agent Features
- **Meeting Insights**:
    - Example: "I have a meeting with Acme, need to provide a summary for them."
- **Slack Communication**:
    - Example: "I need the latest case details from the channel. Kate, please provide more details ASAP."
    - Response: "Posted on Slack channel #sales-experts for Kate."
- **Meeting Notes**:
    - Example:
        1. "I had a meeting with John. It was an excellent meeting. He is excited for our demo on 10th April."
        2. "I need to send quotes by 9th April (Task for contact or Lead)."
- **Meeting Reminders**: Push notifications for upcoming meetings.
- **Slack Notifications**: Push notifications for Slack updates.
- **Meeting List**:
    - Example Queries:
        - "Do I have any meetings tomorrow?"
        - "List all my meetings for a week."
        - "Have I had any meetings with Maria last week?"
- **Approval List**:
    - Example Queries:
        - "Show opportunities waiting for my approval."
        - "Prioritize on Amount."
        - "What latest opportunity have I approved?"
    - Push notifications for approval lists.
- **Meeting Coach**:
    - Example Queries:
        - "Do I have any meetings tomorrow?"
        - "Help me be prepared for this meeting."
        - "What should I know and prepare for the closest meeting?"
        - "What should I know for the next meeting with Bree?"

## Prerequisites
- Salesforce Org with Agentforce enabled
- Installed Salesforce CLI
- Node.js and npm (for additional tools or scripts)