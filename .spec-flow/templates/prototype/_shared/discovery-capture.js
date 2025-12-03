/**
 * Discovery Capture System
 *
 * Captures ideas, questions, and scrap decisions during prototype exploration.
 * Data is stored in localStorage and can be exported for Claude to process.
 *
 * Keyboard Shortcuts:
 *   I - Log an idea
 *   Q - Log a question
 *   X - Scrap current screen
 *   E - Export all captured data (copies to clipboard)
 *   H - Return to hub
 *   S - Cycle states
 *   1-9 - Jump to screen
 */

(function() {
  'use strict';

  // Storage keys
  const STORAGE_KEY = 'prototype-discovery';
  const EXPLORATION_KEY = 'prototype-exploration';

  // Get current screen info
  function getCurrentScreen() {
    const path = window.location.pathname;
    const filename = path.split('/').pop().replace('.html', '');
    const category = path.split('/').slice(-2, -1)[0] || 'unknown';
    return {
      filename: filename,
      category: category,
      path: path,
      timestamp: new Date().toISOString()
    };
  }

  // Get current exploration name (if in exploration mode)
  function getCurrentExploration() {
    const path = window.location.pathname;
    const match = path.match(/_explorations\/([^/]+)\//);
    return match ? match[1] : null;
  }

  // Load stored data
  function loadData() {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? JSON.parse(stored) : {
      ideas: [],
      questions: [],
      scrapped: [],
      exportedAt: null
    };
  }

  // Save data
  function saveData(data) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  }

  // Create modal overlay
  function createModal(title, placeholder, icon, onSave) {
    // Remove existing modal if any
    const existing = document.getElementById('discovery-modal');
    if (existing) existing.remove();

    const modal = document.createElement('div');
    modal.id = 'discovery-modal';
    modal.innerHTML = `
      <div class="discovery-modal-backdrop"></div>
      <div class="discovery-modal-content">
        <div class="discovery-modal-header">
          <span class="discovery-modal-icon">${icon}</span>
          <span class="discovery-modal-title">${title}</span>
          <button class="discovery-modal-close" aria-label="Close">&times;</button>
        </div>
        <div class="discovery-modal-body">
          <textarea
            class="discovery-modal-input"
            placeholder="${placeholder}"
            rows="4"
            autofocus
          ></textarea>
          <div class="discovery-modal-context">
            <span class="discovery-modal-screen">Screen: ${getCurrentScreen().filename}</span>
            ${getCurrentExploration() ? `<span class="discovery-modal-exploration">Exploration: ${getCurrentExploration()}</span>` : ''}
          </div>
        </div>
        <div class="discovery-modal-footer">
          <button class="discovery-modal-cancel">Cancel</button>
          <button class="discovery-modal-save">Save</button>
        </div>
      </div>
    `;

    // Add styles
    const style = document.createElement('style');
    style.textContent = `
      .discovery-modal-backdrop {
        position: fixed;
        inset: 0;
        background: rgba(0,0,0,0.5);
        z-index: 9998;
      }
      .discovery-modal-content {
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: white;
        border-radius: 12px;
        box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
        width: 90%;
        max-width: 500px;
        z-index: 9999;
        font-family: system-ui, -apple-system, sans-serif;
      }
      .discovery-modal-header {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 16px 20px;
        border-bottom: 1px solid #e5e7eb;
      }
      .discovery-modal-icon {
        font-size: 24px;
      }
      .discovery-modal-title {
        flex: 1;
        font-size: 18px;
        font-weight: 600;
        color: #111827;
      }
      .discovery-modal-close {
        background: none;
        border: none;
        font-size: 24px;
        color: #6b7280;
        cursor: pointer;
        padding: 0;
        line-height: 1;
      }
      .discovery-modal-close:hover {
        color: #111827;
      }
      .discovery-modal-body {
        padding: 20px;
      }
      .discovery-modal-input {
        width: 100%;
        padding: 12px;
        border: 1px solid #d1d5db;
        border-radius: 8px;
        font-size: 16px;
        resize: vertical;
        font-family: inherit;
      }
      .discovery-modal-input:focus {
        outline: none;
        border-color: #6366f1;
        box-shadow: 0 0 0 3px rgba(99,102,241,0.1);
      }
      .discovery-modal-context {
        margin-top: 12px;
        display: flex;
        gap: 12px;
        font-size: 13px;
        color: #6b7280;
      }
      .discovery-modal-exploration {
        background: #ede9fe;
        color: #7c3aed;
        padding: 2px 8px;
        border-radius: 4px;
      }
      .discovery-modal-footer {
        display: flex;
        justify-content: flex-end;
        gap: 12px;
        padding: 16px 20px;
        border-top: 1px solid #e5e7eb;
      }
      .discovery-modal-cancel {
        padding: 8px 16px;
        border: 1px solid #d1d5db;
        border-radius: 6px;
        background: white;
        color: #374151;
        font-size: 14px;
        font-weight: 500;
        cursor: pointer;
      }
      .discovery-modal-cancel:hover {
        background: #f9fafb;
      }
      .discovery-modal-save {
        padding: 8px 16px;
        border: none;
        border-radius: 6px;
        background: #6366f1;
        color: white;
        font-size: 14px;
        font-weight: 500;
        cursor: pointer;
      }
      .discovery-modal-save:hover {
        background: #4f46e5;
      }
    `;
    document.head.appendChild(style);
    document.body.appendChild(modal);

    const input = modal.querySelector('.discovery-modal-input');
    const closeBtn = modal.querySelector('.discovery-modal-close');
    const cancelBtn = modal.querySelector('.discovery-modal-cancel');
    const saveBtn = modal.querySelector('.discovery-modal-save');
    const backdrop = modal.querySelector('.discovery-modal-backdrop');

    function close() {
      modal.remove();
    }

    function save() {
      const value = input.value.trim();
      if (value) {
        onSave(value);
        showToast('Saved! Run /prototype sync to import.');
      }
      close();
    }

    closeBtn.addEventListener('click', close);
    cancelBtn.addEventListener('click', close);
    backdrop.addEventListener('click', close);
    saveBtn.addEventListener('click', save);

    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && e.metaKey) {
        save();
      }
      if (e.key === 'Escape') {
        close();
      }
    });

    input.focus();
  }

  // Show toast notification
  function showToast(message, type = 'success') {
    const existing = document.getElementById('discovery-toast');
    if (existing) existing.remove();

    const toast = document.createElement('div');
    toast.id = 'discovery-toast';
    toast.style.cssText = `
      position: fixed;
      bottom: 24px;
      right: 24px;
      background: ${type === 'success' ? '#059669' : '#dc2626'};
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      font-family: system-ui, -apple-system, sans-serif;
      font-size: 14px;
      font-weight: 500;
      box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1);
      z-index: 10000;
      animation: slideIn 0.3s ease-out;
    `;
    toast.textContent = message;

    const style = document.createElement('style');
    style.textContent = `
      @keyframes slideIn {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
      }
    `;
    document.head.appendChild(style);
    document.body.appendChild(toast);

    setTimeout(() => toast.remove(), 3000);
  }

  // Log an idea
  function logIdea() {
    createModal(
      'Log an Idea',
      'What idea came to mind? This could become a feature...',
      '💡',
      (text) => {
        const data = loadData();
        data.ideas.push({
          text: text,
          screen: getCurrentScreen(),
          exploration: getCurrentExploration(),
          timestamp: new Date().toISOString()
        });
        saveData(data);
      }
    );
  }

  // Log a question
  function logQuestion() {
    createModal(
      'Log a Question',
      'What needs to be figured out? What\'s unclear?',
      '❓',
      (text) => {
        const data = loadData();
        data.questions.push({
          text: text,
          screen: getCurrentScreen(),
          exploration: getCurrentExploration(),
          timestamp: new Date().toISOString()
        });
        saveData(data);
      }
    );
  }

  // Scrap current screen
  function scrapScreen() {
    const screen = getCurrentScreen();

    if (confirm(`Scrap "${screen.filename}"? This will mark it for removal.`)) {
      const data = loadData();
      data.scrapped.push({
        screen: screen,
        exploration: getCurrentExploration(),
        timestamp: new Date().toISOString()
      });
      saveData(data);
      showToast(`Marked "${screen.filename}" for scrapping. Run /prototype sync.`);
    }
  }

  // Export all data to clipboard
  function exportData() {
    const data = loadData();

    if (data.ideas.length === 0 && data.questions.length === 0 && data.scrapped.length === 0) {
      showToast('Nothing to export yet!', 'error');
      return;
    }

    // Format as markdown for Claude
    let markdown = `# Prototype Discovery Export\n\n`;
    markdown += `Exported: ${new Date().toISOString()}\n\n`;

    if (data.ideas.length > 0) {
      markdown += `## Ideas (${data.ideas.length})\n\n`;
      data.ideas.forEach((idea, i) => {
        markdown += `### Idea ${i + 1}\n`;
        markdown += `- **Text**: ${idea.text}\n`;
        markdown += `- **Screen**: ${idea.screen.filename}\n`;
        if (idea.exploration) markdown += `- **Exploration**: ${idea.exploration}\n`;
        markdown += `- **Timestamp**: ${idea.timestamp}\n\n`;
      });
    }

    if (data.questions.length > 0) {
      markdown += `## Questions (${data.questions.length})\n\n`;
      data.questions.forEach((q, i) => {
        markdown += `### Question ${i + 1}\n`;
        markdown += `- **Text**: ${q.text}\n`;
        markdown += `- **Screen**: ${q.screen.filename}\n`;
        if (q.exploration) markdown += `- **Exploration**: ${q.exploration}\n`;
        markdown += `- **Timestamp**: ${q.timestamp}\n\n`;
      });
    }

    if (data.scrapped.length > 0) {
      markdown += `## Screens to Scrap (${data.scrapped.length})\n\n`;
      data.scrapped.forEach((s, i) => {
        markdown += `- ${s.screen.filename} (${s.screen.category})\n`;
      });
    }

    // Copy to clipboard
    navigator.clipboard.writeText(markdown).then(() => {
      showToast('Copied to clipboard! Paste to Claude with /prototype sync');

      // Also offer download
      const blob = new Blob([markdown], { type: 'text/markdown' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'prototype-export.md';
      // Don't auto-download, just show toast
    }).catch(err => {
      console.error('Failed to copy:', err);
      showToast('Failed to copy. Check console.', 'error');
    });
  }

  // Clear exported data
  function clearData() {
    if (confirm('Clear all captured ideas, questions, and scrap marks?')) {
      localStorage.removeItem(STORAGE_KEY);
      showToast('Cleared all captured data.');
    }
  }

  // Show help
  function showHelp() {
    const helpModal = document.createElement('div');
    helpModal.id = 'discovery-help';
    helpModal.innerHTML = `
      <div class="discovery-modal-backdrop"></div>
      <div class="discovery-modal-content" style="max-width: 400px;">
        <div class="discovery-modal-header">
          <span class="discovery-modal-icon">⌨️</span>
          <span class="discovery-modal-title">Keyboard Shortcuts</span>
          <button class="discovery-modal-close">&times;</button>
        </div>
        <div class="discovery-modal-body" style="padding: 0;">
          <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
            <tr style="border-bottom: 1px solid #e5e7eb;">
              <td style="padding: 12px 16px;"><kbd style="background:#f3f4f6;padding:4px 8px;border-radius:4px;font-family:monospace;">I</kbd></td>
              <td style="padding: 12px 16px;">Log an idea</td>
            </tr>
            <tr style="border-bottom: 1px solid #e5e7eb;">
              <td style="padding: 12px 16px;"><kbd style="background:#f3f4f6;padding:4px 8px;border-radius:4px;font-family:monospace;">Q</kbd></td>
              <td style="padding: 12px 16px;">Log a question</td>
            </tr>
            <tr style="border-bottom: 1px solid #e5e7eb;">
              <td style="padding: 12px 16px;"><kbd style="background:#f3f4f6;padding:4px 8px;border-radius:4px;font-family:monospace;">X</kbd></td>
              <td style="padding: 12px 16px;">Scrap current screen</td>
            </tr>
            <tr style="border-bottom: 1px solid #e5e7eb;">
              <td style="padding: 12px 16px;"><kbd style="background:#f3f4f6;padding:4px 8px;border-radius:4px;font-family:monospace;">E</kbd></td>
              <td style="padding: 12px 16px;">Export to clipboard</td>
            </tr>
            <tr style="border-bottom: 1px solid #e5e7eb;">
              <td style="padding: 12px 16px;"><kbd style="background:#f3f4f6;padding:4px 8px;border-radius:4px;font-family:monospace;">S</kbd></td>
              <td style="padding: 12px 16px;">Cycle states</td>
            </tr>
            <tr style="border-bottom: 1px solid #e5e7eb;">
              <td style="padding: 12px 16px;"><kbd style="background:#f3f4f6;padding:4px 8px;border-radius:4px;font-family:monospace;">H</kbd></td>
              <td style="padding: 12px 16px;">Return to hub</td>
            </tr>
            <tr>
              <td style="padding: 12px 16px;"><kbd style="background:#f3f4f6;padding:4px 8px;border-radius:4px;font-family:monospace;">1-9</kbd></td>
              <td style="padding: 12px 16px;">Jump to screen</td>
            </tr>
          </table>
        </div>
      </div>
    `;
    document.body.appendChild(helpModal);

    helpModal.querySelector('.discovery-modal-close').addEventListener('click', () => helpModal.remove());
    helpModal.querySelector('.discovery-modal-backdrop').addEventListener('click', () => helpModal.remove());
  }

  // Main keyboard handler
  document.addEventListener('keydown', (e) => {
    // Don't trigger if user is typing in an input
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
      return;
    }

    // Don't trigger if modal is open
    if (document.getElementById('discovery-modal')) {
      return;
    }

    switch (e.key.toLowerCase()) {
      case 'i':
        e.preventDefault();
        logIdea();
        break;
      case 'q':
        e.preventDefault();
        logQuestion();
        break;
      case 'x':
        e.preventDefault();
        scrapScreen();
        break;
      case 'e':
        e.preventDefault();
        exportData();
        break;
      case '?':
        e.preventDefault();
        showHelp();
        break;
    }
  });

  // Show floating indicator
  function showFloatingIndicator() {
    const data = loadData();
    const count = data.ideas.length + data.questions.length;

    if (count === 0) return;

    const indicator = document.createElement('div');
    indicator.id = 'discovery-indicator';
    indicator.style.cssText = `
      position: fixed;
      bottom: 24px;
      left: 24px;
      background: #6366f1;
      color: white;
      padding: 8px 16px;
      border-radius: 20px;
      font-family: system-ui, -apple-system, sans-serif;
      font-size: 13px;
      font-weight: 500;
      box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
      z-index: 9990;
      cursor: pointer;
    `;
    indicator.innerHTML = `💡 ${data.ideas.length} ideas · ❓ ${data.questions.length} questions · <kbd style="background:rgba(255,255,255,0.2);padding:2px 6px;border-radius:3px;font-size:11px;">E</kbd> export`;
    indicator.addEventListener('click', exportData);
    document.body.appendChild(indicator);
  }

  // Initialize
  showFloatingIndicator();

  // Expose for debugging
  window.prototypeDiscovery = {
    loadData,
    exportData,
    clearData,
    showHelp
  };

})();
