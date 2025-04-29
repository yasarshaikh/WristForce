/**
 * Main JavaScript file for the application
 */

document.addEventListener('DOMContentLoaded', function() {
  // Add active class to current nav item
  const currentPath = window.location.pathname;
  const navLinks = document.querySelectorAll('.nav-link');
  
  navLinks.forEach(link => {
    if (link.getAttribute('href') === currentPath) {
      link.classList.add('active');
    }
  });
  
  // Format JSON in textareas
  const jsonTextareas = document.querySelectorAll('textarea[data-format="json"]');
  jsonTextareas.forEach(textarea => {
    textarea.addEventListener('blur', function() {
      try {
        const json = JSON.parse(textarea.value);
        textarea.value = JSON.stringify(json, null, 2);
      } catch (e) {
        // Not valid JSON, leave as is
      }
    });
  });
});