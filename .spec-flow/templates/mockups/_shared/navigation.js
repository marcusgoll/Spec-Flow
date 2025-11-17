/**
 * Keyboard Navigation for Multi-Screen Mockups
 *
 * Features:
 * - Number keys (1-9) navigate to screens
 * - 'H' key returns to hub (index.html)
 * - 'Esc' key closes modals/dialogs
 * - Accessible keyboard shortcuts
 *
 * Usage: Include this script in both hub and screen HTML files
 */

(function() {
  'use strict';

  // Configuration
  const KEYS = {
    HUB: 'h',
    ESCAPE: 'Escape',
    NUMBER_MIN: '1',
    NUMBER_MAX: '9'
  };

  const HUB_FILE = 'index.html';

  /**
   * Navigate to hub page
   */
  function navigateToHub() {
    if (window.location.pathname.endsWith(HUB_FILE)) {
      // Already on hub, scroll to top
      window.scrollTo({ top: 0, behavior: 'smooth' });
      return;
    }
    window.location.href = HUB_FILE;
  }

  /**
   * Navigate to screen by number
   * @param {number} screenNumber - Screen number (1-9)
   */
  function navigateToScreen(screenNumber) {
    const screenCard = document.querySelector(`[data-screen="${screenNumber}"]`);
    if (screenCard) {
      const href = screenCard.getAttribute('href');
      if (href) {
        window.location.href = href;
      }
    }
  }

  /**
   * Close active modal/dialog
   */
  function closeModal() {
    // Close any open dialogs
    const dialogs = document.querySelectorAll('dialog[open]');
    dialogs.forEach(dialog => dialog.close());

    // Close any elements with role="dialog" that have aria-hidden="false"
    const roleDialogs = document.querySelectorAll('[role="dialog"][aria-hidden="false"]');
    roleDialogs.forEach(dialog => {
      dialog.setAttribute('aria-hidden', 'true');
      dialog.style.display = 'none';
    });

    // Trigger custom modal close event
    const modalCloseEvent = new CustomEvent('modal:close');
    document.dispatchEvent(modalCloseEvent);
  }

  /**
   * Global keyboard event handler
   */
  function handleKeydown(event) {
    const key = event.key;
    const target = event.target;

    // Don't intercept if user is typing in an input field
    const isInputActive = (
      target.tagName === 'INPUT' ||
      target.tagName === 'TEXTAREA' ||
      target.tagName === 'SELECT' ||
      target.isContentEditable
    );

    // Allow Escape even in input fields (to close modals)
    if (key === KEYS.ESCAPE) {
      closeModal();
      return;
    }

    // Don't process other shortcuts if input is active
    if (isInputActive) {
      return;
    }

    // Hub navigation (H key)
    if (key.toLowerCase() === KEYS.HUB) {
      event.preventDefault();
      navigateToHub();
      return;
    }

    // Screen navigation (Number keys 1-9)
    if (key >= KEYS.NUMBER_MIN && key <= KEYS.NUMBER_MAX) {
      event.preventDefault();
      const screenNumber = parseInt(key, 10);
      navigateToScreen(screenNumber);
      return;
    }
  }

  /**
   * Initialize navigation
   */
  function init() {
    // Add global keyboard listener
    document.addEventListener('keydown', handleKeydown);

    // Add visual feedback for keyboard shortcuts
    const helpText = document.querySelector('.state-banner .help');
    if (helpText) {
      // Add accessible label
      helpText.setAttribute('role', 'status');
      helpText.setAttribute('aria-live', 'polite');
    }

    // Announce current page to screen readers
    const pageTitle = document.title;
    const announcement = document.createElement('div');
    announcement.className = 'sr-only';
    announcement.setAttribute('role', 'status');
    announcement.setAttribute('aria-live', 'polite');
    announcement.textContent = `Current page: ${pageTitle}. Press H to return to hub.`;
    document.body.appendChild(announcement);

    // Log initialization (for debugging)
    console.log('[Navigation] Keyboard shortcuts initialized:', {
      hub: 'H key',
      screens: '1-9 keys',
      closeModal: 'Escape key'
    });
  }

  /**
   * Cleanup function (called on page unload)
   */
  function cleanup() {
    document.removeEventListener('keydown', handleKeydown);
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Cleanup on page unload
  window.addEventListener('beforeunload', cleanup);

  // Expose public API (optional - for custom integrations)
  window.MockupNavigation = {
    navigateToHub,
    navigateToScreen,
    closeModal
  };
})();
