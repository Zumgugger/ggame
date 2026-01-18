// ============================================
// GGame Admin Control Room - JavaScript
// ============================================

// State management
let lastAction = null;
let lastActionTimeout = null;
const UNDO_WINDOW_MS = 10000; // 10 seconds

// ============================================
// Photo Modal Functions
// ============================================

function openPhotoModal(src) {
  const modal = document.getElementById('photo-modal');
  const img = document.getElementById('modal-photo');
  img.src = src;
  modal.classList.remove('hidden');
}

function closePhotoModal() {
  const modal = document.getElementById('photo-modal');
  modal.classList.add('hidden');
}

// ============================================
// Keyboard Shortcuts
// ============================================

document.addEventListener('keydown', function(e) {
  // Don't trigger shortcuts if typing in textarea
  if (e.target.tagName === 'TEXTAREA') return;

  switch(e.key.toUpperCase()) {
    case 'A':
      submitVerification(getSubmissionId(), 'verified');
      break;
    case 'D':
      submitVerification(getSubmissionId(), 'denied');
      break;
    case 'ENTER':
      // Submit message if in message field, otherwise approve
      if (e.target.id !== 'admin_message') {
        submitVerification(getSubmissionId(), 'verified');
      }
      break;
  }
});

// ============================================
// Submission Verification
// ============================================

function getSubmissionId() {
  const form = document.getElementById('verification-form');
  if (!form) return null;
  return form.getAttribute('data-submission-id');
}

function submitVerification(submissionId, action) {
  if (!submissionId) return;

  const message = document.getElementById('admin_message')?.value || '';
  const token = document.querySelector('[name="authenticity_token"]').value;

  // Record for undo
  lastAction = {
    submissionId: submissionId,
    action: action,
    message: message,
    timestamp: Date.now()
  };

  showUndoButton();
  clearUndoTimeout();
  lastActionTimeout = setTimeout(() => {
    hideUndoButton();
  }, UNDO_WINDOW_MS);

  // Send request
  fetch(`/admin/submissions/${submissionId}/${action}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': token
    },
    body: JSON.stringify({
      admin_message: message
    })
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      // Show success feedback
      showNotification(`Submission ${action}!`, 'success');
      
      // Reload page after 1 second to show next submission
      setTimeout(() => {
        location.reload();
      }, 1000);
    } else {
      showNotification(`Error: ${data.message}`, 'danger');
      lastAction = null; // Don't allow undo on error
    }
  })
  .catch(error => {
    console.error('Error:', error);
    showNotification('Error submitting verification', 'danger');
    lastAction = null;
  });
}

// ============================================
// Undo Function
// ============================================

function undoLastAction() {
  if (!lastAction) return;

  const token = document.querySelector('[name="authenticity_token"]').value;
  
  // Reverse the action
  const reverseAction = lastAction.action === 'verified' ? 'unverify' : 'deny_undo';

  fetch(`/admin/submissions/${lastAction.submissionId}/${reverseAction}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': token
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      showNotification('Action undone!', 'success');
      lastAction = null;
      hideUndoButton();
      setTimeout(() => {
        location.reload();
      }, 500);
    } else {
      showNotification('Undo failed', 'danger');
    }
  })
  .catch(error => {
    console.error('Error:', error);
    showNotification('Error undoing action', 'danger');
  });
}

function showUndoButton() {
  const btn = document.getElementById('undo-btn');
  if (btn) {
    btn.style.display = 'block';
  }
}

function hideUndoButton() {
  const btn = document.getElementById('undo-btn');
  if (btn) {
    btn.style.display = 'none';
  }
}

function clearUndoTimeout() {
  if (lastActionTimeout) {
    clearTimeout(lastActionTimeout);
  }
}

// ============================================
// Notifications
// ============================================

function showNotification(message, type = 'info') {
  // Create notification element
  const notification = document.createElement('div');
  notification.className = `notification notification-${type}`;
  notification.textContent = message;
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    background-color: ${type === 'success' ? '#10b981' : type === 'danger' ? '#ef4444' : '#a855f7'};
    color: white;
    padding: 16px 24px;
    border-radius: 0;
    z-index: 2000;
    animation: slideIn 0.3s ease;
  `;

  document.body.appendChild(notification);

  // Auto-remove after 3 seconds
  setTimeout(() => {
    notification.style.animation = 'slideOut 0.3s ease';
    setTimeout(() => {
      notification.remove();
    }, 300);
  }, 3000);
}

// ============================================
// Game Timer
// ============================================

function updateGameTimer() {
  const timerElement = document.getElementById('timer-value');
  if (!timerElement) return;

  // This would be set by the server; for now, placeholder
  // In real implementation, calculate from game_end_time
  
  // Example: update every second
  setInterval(() => {
    // Calculate remaining time
    // This needs to be implemented based on your GameSettings model
  }, 1000);
}

// ============================================
// Real-time Updates via ActionCable
// ============================================

// This will be handled separately with ActionCable
// Listen for new submissions and queue updates

document.addEventListener('DOMContentLoaded', function() {
  updateGameTimer();
  
  // If ActionCable is available, subscribe to real-time updates
  if (typeof App !== 'undefined' && App.cable) {
    subscribeToSubmissionUpdates();
  }
});

function subscribeToSubmissionUpdates() {
  App.admin_control_room = App.cable.subscriptions.create("AdminControlRoomChannel", {
    connected() {
      console.log('Connected to admin control room channel');
    },
    disconnected() {
      console.log('Disconnected from admin control room channel');
    },
    received(data) {
      // Handle real-time updates
      if (data.type === 'new_submission') {
        showNotification('New submission received!', 'info');
        // Optionally refresh or update the display
      } else if (data.type === 'queue_update') {
        // Update queue stats
        updateQueueStats(data.stats);
      }
    }
  });
}

function updateQueueStats(stats) {
  const statsDiv = document.getElementById('queue-stats');
  if (statsDiv) {
    statsDiv.innerHTML = `
      <div>
        <span class="text-accent">${stats.pending}</span> <span class="text-muted">pending</span>
      </div>
      <div>
        <span class="text-accent">${stats.verified_today}</span> <span class="text-muted">approved today</span>
      </div>
      <div>
        <span class="text-accent">${stats.denied_today}</span> <span class="text-muted">denied today</span>
      </div>
    `;
  }
}

// ============================================
// Animations
// ============================================

const style = document.createElement('style');
style.textContent = `
  @keyframes slideIn {
    from {
      transform: translateX(400px);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  @keyframes slideOut {
    from {
      transform: translateX(0);
      opacity: 1;
    }
    to {
      transform: translateX(400px);
      opacity: 0;
    }
  }
`;
document.head.appendChild(style);
