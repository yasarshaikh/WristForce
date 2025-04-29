/**
 * Render the home page
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.renderHome = (req, res) => {
  res.render('index', {
    title: 'Einstein AI Agent Chat'
  });
};

/**
 * Render the chat interface
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.renderChat = (req, res) => {
  res.render('data-form', {
    title: 'Chat with Einstein AI Agent'
  });
};