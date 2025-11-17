/**
 * State Switcher for Multi-Screen Mockups
 *
 * Features:
 * - Press 'S' to cycle through states (Success → Loading → Error → Empty)
 * - Visual indicator updates automatically
 * - Accessibility announcements for screen readers
 * - Persists state in sessionStorage (optional)
 *
 * Usage:
 * 1. Include this script in your screen HTML
 * 2. Call initStateSwitcher(['success', 'loading', 'error', 'empty'])
 * 3. Use state-specific CSS classes: .show-on-success, .show-on-loading, etc.
 */

(function() {
  'use strict';

  // Configuration
  const STATE_KEY = 'S';
  const STORAGE_KEY = 'mockup-state';

  let availableStates = ['success', 'loading', 'error', 'empty'];
  let currentStateIndex = 0;
  let initialized = false;

  /**
   * Get state metadata (labels, colors, etc.)
   */
  const STATE_META = {
    success: {
      label: 'Success',
      className: 'success',
      icon: '✓',
      description: 'Success state - happy path with data'
    },
    loading: {
      label: 'Loading',
      className: 'loading',
      icon: '⟳',
      description: 'Loading state - data being fetched'
    },
    error: {
      label: 'Error',
      className: 'error',
      icon: '⚠',
      description: 'Error state - something went wrong'
    },
    empty: {
      label: 'Empty',
      className: 'empty',
      icon: '∅',
      description: 'Empty state - no data available'
    }
  };

  /**
   * Get current state
   * @returns {string}
   */
  function getCurrentState() {
    return availableStates[currentStateIndex];
  }

  /**
   * Update DOM to reflect current state
   */
  function updateDOM() {
    const state = getCurrentState();
    const meta = STATE_META[state];

    // Update body data-state attribute
    document.body.setAttribute('data-state', state);

    // Update state indicator in banner
    const indicator = document.getElementById('state-indicator');
    const label = document.getElementById('state-label');

    if (indicator && meta) {
      // Remove all state classes
      indicator.className = 'state-indicator';
      // Add current state class
      indicator.classList.add(meta.className);

      if (label) {
        label.textContent = `${meta.icon} ${meta.label}`;
      }
    }

    // Announce state change to screen readers
    announceStateChange(state, meta);

    // Trigger custom state change event
    const stateChangeEvent = new CustomEvent('state:change', {
      detail: { state, meta }
    });
    document.dispatchEvent(stateChangeEvent);

    // Persist state in sessionStorage (optional)
    try {
      sessionStorage.setItem(STORAGE_KEY, state);
    } catch (e) {
      // Ignore storage errors
    }

    // Log state change (for debugging)
    console.log('[StateSwitcher] State changed:', state);
  }

  /**
   * Announce state change to screen readers
   * @param {string} state - Current state name
   * @param {object} meta - State metadata
   */
  function announceStateChange(state, meta) {
    // Find or create announcement element
    let announcer = document.getElementById('state-announcer');
    if (!announcer) {
      announcer = document.createElement('div');
      announcer.id = 'state-announcer';
      announcer.className = 'sr-only';
      announcer.setAttribute('role', 'status');
      announcer.setAttribute('aria-live', 'polite');
      document.body.appendChild(announcer);
    }

    // Update announcement text
    if (meta) {
      announcer.textContent = `State changed to ${meta.label}: ${meta.description}`;
    }
  }

  /**
   * Cycle to next state
   */
  function nextState() {
    currentStateIndex = (currentStateIndex + 1) % availableStates.length;
    updateDOM();
  }

  /**
   * Set state by name
   * @param {string} stateName - Name of the state to activate
   */
  function setState(stateName) {
    const index = availableStates.indexOf(stateName);
    if (index !== -1) {
      currentStateIndex = index;
      updateDOM();
    } else {
      console.warn(`[StateSwitcher] Invalid state: ${stateName}`);
    }
  }

  /**
   * Load persisted state from sessionStorage
   */
  function loadPersistedState() {
    try {
      const savedState = sessionStorage.getItem(STORAGE_KEY);
      if (savedState && availableStates.includes(savedState)) {
        setState(savedState);
        return true;
      }
    } catch (e) {
      // Ignore storage errors
    }
    return false;
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

    if (isInputActive) {
      return;
    }

    // State cycling (S key)
    if (key.toLowerCase() === STATE_KEY.toLowerCase()) {
      event.preventDefault();
      nextState();
    }
  }

  /**
   * Initialize state switcher
   * @param {string[]} states - Array of available states (default: ['success', 'loading', 'error', 'empty'])
   */
  function initStateSwitcher(states) {
    if (initialized) {
      console.warn('[StateSwitcher] Already initialized');
      return;
    }

    // Update available states if provided
    if (states && Array.isArray(states) && states.length > 0) {
      availableStates = states;
    }

    // Try to load persisted state first
    const loaded = loadPersistedState();

    // If no persisted state, initialize to first state
    if (!loaded) {
      currentStateIndex = 0;
      updateDOM();
    }

    // Add keyboard listener
    document.addEventListener('keydown', handleKeydown);

    initialized = true;

    // Log initialization
    console.log('[StateSwitcher] Initialized with states:', availableStates);
    console.log('[StateSwitcher] Current state:', getCurrentState());
  }

  /**
   * Cleanup function
   */
  function cleanup() {
    document.removeEventListener('keydown', handleKeydown);
    initialized = false;
  }

  // Cleanup on page unload
  window.addEventListener('beforeunload', cleanup);

  // Expose public API
  window.initStateSwitcher = initStateSwitcher;
  window.StateSwitcher = {
    init: initStateSwitcher,
    getCurrentState,
    setState,
    nextState,
    getAvailableStates: () => [...availableStates],
    getStateMeta: (state) => STATE_META[state]
  };
})();
