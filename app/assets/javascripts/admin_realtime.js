// Admin real-time updates via ActionCable
// This subscribes to the submissions channel to get live updates

document.addEventListener('DOMContentLoaded', function() {
  // Only run on admin submissions page
  if (!window.location.pathname.includes('/admin/submissions')) return;
  
  // Check if ActionCable is available
  if (typeof ActionCable === 'undefined') {
    console.log('ActionCable not available');
    return;
  }

  // Create cable connection
  const cable = ActionCable.createConsumer();
  
  // Subscribe to submissions channel
  const submissionsChannel = cable.subscriptions.create("SubmissionsChannel", {
    connected() {
      console.log('Connected to SubmissionsChannel');
      showConnectionStatus(true);
    },
    
    disconnected() {
      console.log('Disconnected from SubmissionsChannel');
      showConnectionStatus(false);
    },
    
    received(data) {
      console.log('Received:', data);
      
      if (data.type === 'new_submission') {
        handleNewSubmission(data.submission);
      } else if (data.type === 'submission_processed') {
        handleSubmissionProcessed(data.submission_id, data.status);
      }
    }
  });

  // Show connection status indicator
  function showConnectionStatus(connected) {
    let indicator = document.getElementById('realtime-indicator');
    if (!indicator) {
      indicator = document.createElement('div');
      indicator.id = 'realtime-indicator';
      indicator.style.cssText = 'position: fixed; bottom: 20px; right: 20px; padding: 8px 16px; border-radius: 20px; font-size: 12px; z-index: 9999; transition: all 0.3s;';
      document.body.appendChild(indicator);
    }
    
    if (connected) {
      indicator.textContent = '🟢 Live';
      indicator.style.backgroundColor = '#2ecc71';
      indicator.style.color = 'white';
    } else {
      indicator.textContent = '🔴 Offline';
      indicator.style.backgroundColor = '#e74c3c';
      indicator.style.color = 'white';
    }
  }

  // Handle new submission notification
  function handleNewSubmission(submission) {
    // Play notification sound
    playNotificationSound();
    
    // Show notification badge
    showNotificationBadge();
    
    // Flash the page title
    flashTitle('🔔 Neue Einreichung!');
    
    // Show toast notification
    showToast(`Neue Einreichung von ${submission.group_name}: ${submission.option_name}`);
    
    // Auto-refresh the page after a short delay if viewing pending
    const urlParams = new URLSearchParams(window.location.search);
    const scope = urlParams.get('scope') || 'pending';
    if (scope === 'pending' || scope === 'all') {
      setTimeout(() => {
        window.location.reload();
      }, 2000);
    }
  }

  // Handle submission processed (remove from list)
  function handleSubmissionProcessed(submissionId, status) {
    const row = document.querySelector(`tr[data-id="${submissionId}"]`);
    if (row) {
      row.style.transition = 'opacity 0.5s';
      row.style.opacity = '0';
      setTimeout(() => row.remove(), 500);
    }
  }

  // Play notification sound
  function playNotificationSound() {
    try {
      // Create a simple beep sound using Web Audio API
      const audioContext = new (window.AudioContext || window.webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      oscillator.frequency.value = 800;
      oscillator.type = 'sine';
      gainNode.gain.value = 0.3;
      
      oscillator.start();
      setTimeout(() => {
        oscillator.stop();
      }, 200);
    } catch (e) {
      console.log('Could not play notification sound:', e);
    }
  }

  // Show notification badge in page title
  let originalTitle = document.title;
  let titleFlashInterval = null;
  
  function flashTitle(newTitle) {
    if (titleFlashInterval) clearInterval(titleFlashInterval);
    
    let showOriginal = false;
    titleFlashInterval = setInterval(() => {
      document.title = showOriginal ? originalTitle : newTitle;
      showOriginal = !showOriginal;
    }, 1000);
    
    // Stop after 10 seconds
    setTimeout(() => {
      if (titleFlashInterval) {
        clearInterval(titleFlashInterval);
        document.title = originalTitle;
      }
    }, 10000);
    
    // Stop when window gets focus
    window.addEventListener('focus', () => {
      if (titleFlashInterval) {
        clearInterval(titleFlashInterval);
        titleFlashInterval = null;
        document.title = originalTitle;
      }
    }, { once: true });
  }

  // Show toast notification
  function showToast(message) {
    let toast = document.createElement('div');
    toast.className = 'admin-toast';
    toast.innerHTML = `
      <strong>🔔 Neue Einreichung</strong>
      <p>${message}</p>
    `;
    toast.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: #3498db;
      color: white;
      padding: 16px 24px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      z-index: 10000;
      animation: slideIn 0.3s ease;
      max-width: 300px;
    `;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
      toast.style.animation = 'slideOut 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, 5000);
  }

  // Add CSS animations
  const style = document.createElement('style');
  style.textContent = `
    @keyframes slideIn {
      from { transform: translateX(100%); opacity: 0; }
      to { transform: translateX(0); opacity: 1; }
    }
    @keyframes slideOut {
      from { transform: translateX(0); opacity: 1; }
      to { transform: translateX(100%); opacity: 0; }
    }
  `;
  document.head.appendChild(style);

  // Show notification badge
  function showNotificationBadge() {
    const menuItem = document.querySelector('a[href*="/admin/submissions"]');
    if (menuItem && !menuItem.querySelector('.notification-badge')) {
      const badge = document.createElement('span');
      badge.className = 'notification-badge';
      badge.textContent = '!';
      badge.style.cssText = `
        background: #e74c3c;
        color: white;
        padding: 2px 6px;
        border-radius: 10px;
        font-size: 10px;
        margin-left: 5px;
        animation: pulse 1s infinite;
      `;
      menuItem.appendChild(badge);
    }
  }
});
