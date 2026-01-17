// Player real-time updates via ActionCable
// Receives submission verification results and points updates

document.addEventListener('DOMContentLoaded', function() {
  // Only run on player pages
  if (!window.location.pathname.startsWith('/play')) return;
  
  // Get group and session info from page data
  const playerData = document.getElementById('player-data');
  if (!playerData) return;
  
  const groupId = playerData.dataset.groupId;
  const sessionToken = playerData.dataset.sessionToken;
  
  if (!groupId || !sessionToken) return;
  
  // Check if ActionCable is available
  if (typeof ActionCable === 'undefined') {
    console.log('ActionCable not available');
    return;
  }

  // Create cable connection
  const cable = ActionCable.createConsumer();
  
  // Subscribe to player channel with group and session params
  const playerChannel = cable.subscriptions.create(
    { 
      channel: "PlayerChannel", 
      group_id: groupId,
      session_token: sessionToken 
    },
    {
      connected() {
        console.log('Connected to PlayerChannel');
      },
      
      disconnected() {
        console.log('Disconnected from PlayerChannel');
      },
      
      received(data) {
        console.log('Player received:', data);
        
        switch(data.type) {
          case 'submission_update':
            handleSubmissionUpdate(data.submission);
            break;
          case 'points_update':
            handlePointsUpdate(data.points);
            break;
        }
      }
    }
  );

  // Handle submission status update
  function handleSubmissionUpdate(submission) {
    const isVerified = submission.status === 'verified';
    const message = isVerified 
      ? `✅ "${submission.option_name}" wurde bestätigt!`
      : `❌ "${submission.option_name}" wurde abgelehnt.`;
    
    // Show notification
    showPlayerNotification(message, submission.admin_message, isVerified);
    
    // Vibrate if available
    if (navigator.vibrate) {
      navigator.vibrate(isVerified ? [100, 50, 100] : [200, 100, 200]);
    }
  }

  // Handle points update
  function handlePointsUpdate(points) {
    // Update points display on page
    const pointsDisplay = document.querySelector('[data-points]');
    if (pointsDisplay) {
      const oldPoints = parseInt(pointsDisplay.textContent) || 0;
      pointsDisplay.textContent = points;
      
      // Animate if points changed
      if (points !== oldPoints) {
        pointsDisplay.classList.add('points-changed');
        setTimeout(() => pointsDisplay.classList.remove('points-changed'), 1000);
      }
    }
    
    // Also update any other points displays
    document.querySelectorAll('.group-points').forEach(el => {
      el.textContent = points;
    });
  }

  // Show player notification
  function showPlayerNotification(title, message, isSuccess) {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `player-notification ${isSuccess ? 'success' : 'error'}`;
    notification.innerHTML = `
      <div class="notification-content">
        <strong>${title}</strong>
        ${message ? `<p>${message}</p>` : ''}
        <button class="close-notification">×</button>
      </div>
    `;
    
    // Style the notification
    notification.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      padding: 16px;
      background: ${isSuccess ? '#27ae60' : '#e74c3c'};
      color: white;
      z-index: 10000;
      animation: slideDown 0.3s ease;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    `;
    
    document.body.appendChild(notification);
    
    // Close button handler
    notification.querySelector('.close-notification').onclick = () => {
      notification.style.animation = 'slideUp 0.3s ease';
      setTimeout(() => notification.remove(), 300);
    };
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      if (notification.parentNode) {
        notification.style.animation = 'slideUp 0.3s ease';
        setTimeout(() => notification.remove(), 300);
      }
    }, 5000);
  }

  // Add CSS for notifications and animations
  const style = document.createElement('style');
  style.textContent = `
    @keyframes slideDown {
      from { transform: translateY(-100%); }
      to { transform: translateY(0); }
    }
    @keyframes slideUp {
      from { transform: translateY(0); }
      to { transform: translateY(-100%); }
    }
    .notification-content {
      display: flex;
      align-items: center;
      justify-content: space-between;
      max-width: 600px;
      margin: 0 auto;
    }
    .notification-content p {
      margin: 0;
      font-size: 14px;
      opacity: 0.9;
    }
    .close-notification {
      background: none;
      border: none;
      color: white;
      font-size: 24px;
      cursor: pointer;
      padding: 0 8px;
    }
    .points-changed {
      animation: pointsPulse 1s ease;
    }
    @keyframes pointsPulse {
      0%, 100% { transform: scale(1); }
      50% { transform: scale(1.2); color: #f1c40f; }
    }
  `;
  document.head.appendChild(style);
});
