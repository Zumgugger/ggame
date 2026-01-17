# GGame Feature Implementation Plan

> **Document Created:** January 17, 2026  
> **Last Updated:** January 17, 2026
> **Status:** Phase 1 Complete - Proceeding to Phase 1.8-1.9 (Point Multiplier & Cooldowns)  
> **Estimated Total Effort:** 4-6 weeks

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Feature Summary](#2-feature-summary)
3. [Database Schema Changes](#3-database-schema-changes)
4. [Implementation Phases](#4-implementation-phases)
5. [Technical Architecture](#5-technical-architecture)
6. [Security Considerations](#6-security-considerations)
7. [Testing Strategy](#7-testing-strategy)
8. [Risk Assessment](#8-risk-assessment)

---

## 1. Project Overview

### Current State
- Rails app with ActiveAdmin control room
- Models: User, Group, Target, Option, Event, AdminUser
- Basic event tracking for live-action game
- Docker deployment

### Goal State
- Configurable game rules via admin settings
- Mobile PWA for players with QR-code group assignment
- Photo submission & verification workflow
- Real-time updates between players and control room
- Dynamic rules page generated from settings

---

## 2. Feature Summary

### Feature 1: Game Settings & Rules Configuration
Centralized settings management with:
- **Point multiplier** for all targets (e.g., 1.5x during special hours)
- **Game time window** (start/end datetime)
- **Cooldowns** between actions per group
- **Option costs** (points deducted for using certain options)
- **Default values** with one-click reset

### Feature 2: Admin Panel Design Improvements
*(Implemented last)*
- Cleaner, more usable interface
- Better mobile responsiveness for admin
- Improved verification workflow UX

### Feature 3: Mobile PWA for Players
- QR code generation per group
- Browser-based "install" flow
- Group assignment on scan
- Player features:
  - View group name
  - View targets (with completed ones marked)
  - View rules
  - Submit options with optional photo
  - Receive verification notifications

### Feature 4: Rules View
- Dynamic page generated from Option settings
- In-place editing in admin
- Auto-updates when settings change
- Basic HTML/CSS output

### Feature 5: Security & Sanitization
- Input sanitization for all external data
- Rate limiting (1 request per 10 seconds per device)
- Secure session tokens for player identity

---

## 3. Database Schema Changes

### 3.1 New Tables

#### `game_settings` (Single-row configuration table)
```ruby
create_table :game_settings do |t|
  t.decimal :point_multiplier, default: 1.0, precision: 4, scale: 2
  t.datetime :game_start_time
  t.datetime :game_end_time
  t.boolean :game_active, default: false
  t.json :default_values  # Store defaults for reset functionality
  t.timestamps
end
```

#### `option_settings` (Extended option configuration)
```ruby
create_table :option_settings do |t|
  t.references :option, foreign_key: true, null: false
  t.boolean :requires_photo, default: false
  t.boolean :requires_target, default: false
  t.boolean :auto_verify, default: true
  t.integer :points, default: 0
  t.integer :cost, default: 0  # Points deducted when using this option
  t.integer :cooldown_seconds, default: 0
  t.text :rule_text  # Rule explanation for this option
  t.text :rule_text_default  # Default rule text for reset
  t.boolean :available_to_players, default: true
  t.timestamps
end
```

#### `player_sessions` (Device-to-group mapping)
```ruby
create_table :player_sessions do |t|
  t.references :group, foreign_key: true, null: false
  t.string :session_token, null: false, index: { unique: true }
  t.string :device_fingerprint
  t.string :player_name
  t.datetime :last_seen_at
  t.timestamps
end
```

#### `submissions` (Player submissions pending verification)
```ruby
create_table :submissions do |t|
  t.references :group, foreign_key: true, null: false
  t.references :option, foreign_key: true, null: false
  t.references :target, foreign_key: true, optional: true
  t.references :player_session, foreign_key: true, null: false
  t.string :status, default: 'pending'  # pending, verified, denied
  t.text :description
  t.text :admin_message  # Custom message from admin on verify/deny
  t.datetime :submitted_at  # Server timestamp on receipt
  t.datetime :verified_at
  t.references :verified_by, foreign_key: { to_table: :admin_users }, optional: true
  t.timestamps
end
# Note: Photo attached via ActiveStorage
```

### 3.2 Table Modifications

#### `groups` - Add QR code token
```ruby
add_column :groups, :join_token, :string, null: false
add_column :groups, :name_editable, :boolean, default: true
add_index :groups, :join_token, unique: true
```

#### `options` - Link to option_settings
```ruby
# No changes needed - option_settings references options
```

#### `events` - Add submission reference
```ruby
add_reference :events, :submission, foreign_key: true, optional: true
add_column :events, :queued_behind_id, :bigint, optional: true
# queued_behind_id: If this event is waiting for another to be verified
```

### 3.3 Entity Relationship Diagram

```
┌─────────────────┐     ┌─────────────────┐
│  GameSettings   │     │     Option      │
│  (singleton)    │     │                 │
└─────────────────┘     └────────┬────────┘
                                 │ 1
                                 │
                                 │ 1
                        ┌────────▼────────┐
                        │ OptionSettings  │
                        └─────────────────┘

┌─────────────────┐            ┌─────────────────┐
│     Group       │◄───────────│  PlayerSession  │
│  (join_token)   │ 1        * │ (session_token) │
└────────┬────────┘            └────────┬────────┘
         │ 1                            │ 1
         │                              │
         │ *                            │ *
┌────────▼────────┐            ┌────────▼────────┐
│   Submission    │◄───────────│                 │
│                 │            │                 │
└────────┬────────┘            └─────────────────┘
         │ 1
         │
         │ 0..1
┌────────▼────────┐
│     Event       │
│                 │
└─────────────────┘
```

---

## 4. Implementation Phases

### Phase 1: Foundation & Settings (Week 1) ✅ MOSTLY COMPLETE
**Goal:** Core settings infrastructure

| Task | Description | Status | Effort |
|------|-------------|--------|--------|
| 1.1 | Create `game_settings` migration & model | ✅ Done | 2h |
| 1.2 | Create `option_settings` migration & model | ✅ Done | 2h |
| 1.3 | Build GameSettings singleton pattern | ✅ Done | 1h |
| 1.4 | Admin view for GameSettings (point multiplier, time window) | ✅ Done | 3h |
| 1.5 | Admin view for OptionSettings (per-option config) | ✅ Done | 4h |
| 1.6 | "Reset to Defaults" functionality | ✅ Done | 2h |
| 1.7 | Manual start/stop game buttons in admin | ✅ Done | 2h |
| 1.8 | Update Event point calculations to use multiplier | ⏳ In Progress | 2h |
| 1.9 | Add cooldown checking logic | ⏳ Queued | 3h |

**Deliverable:** Admin can configure all game rules, reset to defaults

**Additions beyond plan:**
- ✅ GameTimeWindows table for multiple time windows (Morning/Afternoon/etc.)
- ✅ QR code generation and display in Groups admin
- ✅ Multiple separate date/time fields for better UX
- ✅ German rule text defaults for all 9 options
- ✅ Ransack configurations for all new models

---

### Phase 2: Player Session & QR System (Week 2)
**Goal:** QR code group assignment

| Task | Description | Effort |
|------|-------------|--------|
| 2.1 | Add `join_token` to Groups migration | 1h |
| 2.2 | Create `player_sessions` migration & model | 2h |
| 2.3 | QR code generation (using `rqrcode` gem) | 2h |
| 2.4 | Display QR codes in admin Group view | 2h |
| 2.5 | Create `/join/:token` endpoint | 2h |
| 2.6 | Session token generation & storage (localStorage) | 3h |
| 2.7 | Device fingerprinting (basic) | 2h |
| 2.8 | Group name entry flow (if not set) | 2h |
| 2.9 | Returning player detection (same token = same group) | 2h |

**Deliverable:** Players can scan QR, get assigned to group, session persists

---

### Phase 3: PWA & Player Interface (Week 2-3)
**Goal:** Mobile app experience

| Task | Description | Effort |
|------|-------------|--------|
| 3.1 | Configure PWA manifest & service worker | 3h |
| 3.2 | Create player layout (mobile-first) | 4h |
| 3.3 | Home screen with option buttons | 4h |
| 3.4 | Hamburger menu navigation | 2h |
| 3.5 | Group info page | 1h |
| 3.6 | Target list page (with strikethrough for completed) | 3h |
| 3.7 | Rules page (dynamically generated) | 3h |
| 3.8 | "Add to Home Screen" prompt | 2h |

**Deliverable:** Installable PWA with all player views

---

### Phase 4: Submission System (Week 3-4)
**Goal:** Players can submit, admins can verify

| Task | Description | Effort |
|------|-------------|--------|
| 4.1 | Create `submissions` migration & model | 2h |
| 4.2 | Submission controller & form | 4h |
| 4.3 | Photo capture/upload (camera integration) | 4h |
| 4.4 | Server timestamp on receipt | 1h |
| 4.5 | Option validity checking (cooldown, game time, etc.) | 3h |
| 4.6 | Admin submissions queue view | 4h |
| 4.7 | Photo display in admin with verify/deny buttons | 3h |
| 4.8 | Admin message field for feedback | 1h |
| 4.9 | Auto-verify flow (for non-photo options) | 2h |
| 4.10 | Create Event on verification | 2h |

**Deliverable:** Full submission → verification → event flow

---

### Phase 5: Real-time & Notifications (Week 4)
**Goal:** Live updates via ActionCable

| Task | Description | Effort |
|------|-------------|--------|
| 5.1 | Set up ActionCable channels | 2h |
| 5.2 | `SubmissionsChannel` for admin (new submissions appear) | 3h |
| 5.3 | `PlayerChannel` for players (verification result) | 3h |
| 5.4 | Admin notification sound/badge for new submissions | 2h |
| 5.5 | Player notification on verify/deny with admin message | 2h |
| 5.6 | Auto-refresh target list when events verified | 2h |

**Deliverable:** Real-time bidirectional updates

---

### Phase 6: Verification Queue Logic (Week 4)
**Goal:** Maintain event time ordering

| Task | Description | Effort |
|------|-------------|--------|
| 6.1 | Add `queued_behind_id` to events | 1h |
| 6.2 | Queue detection logic (pending submission blocks newer) | 3h |
| 6.3 | Queue visualization in admin | 2h |
| 6.4 | Auto-process queue when blocking submission verified | 2h |
| 6.5 | Handle denied submission (release queue) | 2h |

**Deliverable:** Events maintain correct time order despite verification delays

---

### Phase 7: Photo Management (Week 5)
**Goal:** Download & delete workflow

| Task | Description | Effort |
|------|-------------|--------|
| 7.1 | "Download & Archive" button in admin | 2h |
| 7.2 | Trigger local download via browser | 1h |
| 7.3 | Delete photo from server after download | 1h |
| 7.4 | Confirmation dialog before delete | 1h |
| 7.5 | Bulk download/delete for multiple submissions | 2h |

**Deliverable:** Admin can archive photos locally, server stays clean

---

### Phase 8: Rules View System (Week 5)
**Goal:** Dynamic rules page

| Task | Description | Effort |
|------|-------------|--------|
| 8.1 | Rules page generation from OptionSettings | 2h |
| 8.2 | In-place editing in admin (contenteditable or AJAX) | 4h |
| 8.3 | Auto-update when options added/removed | 2h |
| 8.4 | Auto-update when settings change | 2h |
| 8.5 | Basic CSS styling for rules page | 2h |

**Deliverable:** Rules page always reflects current settings

---

### Phase 9: Security Hardening (Week 5)
**Goal:** Protect against malicious input

| Task | Description | Effort |
|------|-------------|--------|
| 9.1 | Rate limiting middleware (1 req/10s per session) | 3h |
| 9.2 | Input sanitization for all player inputs | 2h |
| 9.3 | CSRF protection for API endpoints | 1h |
| 9.4 | Session token validation | 1h |
| 9.5 | Prevent group hopping (one device = one group) | 2h |
| 9.6 | SQL injection prevention audit | 1h |
| 9.7 | XSS prevention audit | 1h |

**Deliverable:** Secure against common attack vectors

---

### Phase 10: Admin Design Improvements (Week 6)
**Goal:** Better admin UX

| Task | Description | Effort |
|------|-------------|--------|
| 10.1 | Design mockups/wireframes | 4h |
| 10.2 | Custom ActiveAdmin theme or custom views | 8h |
| 10.3 | Mobile-responsive admin | 4h |
| 10.4 | Improved verification workflow UX | 4h |
| 10.5 | Dashboard with live game stats | 4h |

**Deliverable:** Polished, usable admin interface

---

## 5. Technical Architecture

### 5.1 System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        ADMIN                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Settings   │  │   Groups    │  │  Verification Queue │  │
│  │  Management │  │  & QR Codes │  │  (Real-time)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ ActionCable (WebSocket)
                             │
┌────────────────────────────▼────────────────────────────────┐
│                     RAILS SERVER                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Controllers: Admin, Player, Submissions, Sessions   │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Models: GameSettings, OptionSettings, Submission,   │   │
│  │          PlayerSession, Group, Event, Target, Option │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Services: SubmissionProcessor, QueueManager,        │   │
│  │            CooldownChecker, PointCalculator          │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ ActionCable (WebSocket)
                             │
┌────────────────────────────▼────────────────────────────────┐
│                     PLAYER PWA                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │    Home     │  │   Targets   │  │       Rules         │  │
│  │  (Options)  │  │    List     │  │       View          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Photo Capture & Submit                   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Key Gems to Add

```ruby
# Gemfile additions
gem 'rqrcode'           # QR code generation
gem 'rack-attack'       # Rate limiting
gem 'image_processing'  # Photo processing (already have ActiveStorage)
```

### 5.3 ActionCable Channels

```ruby
# app/channels/admin_channel.rb
# - Broadcasts new submissions
# - Broadcasts verification updates

# app/channels/player_channel.rb
# - Receives verification results
# - Receives game state updates (start/end)
```

### 5.4 Service Objects

```ruby
# app/services/submission_processor.rb
# - Validates submission
# - Checks cooldowns
# - Checks game time window
# - Creates submission record
# - Triggers auto-verify if applicable

# app/services/queue_manager.rb
# - Manages verification queue
# - Processes queued events on verification
# - Handles denied submissions

# app/services/point_calculator.rb
# - Applies point multiplier
# - Deducts option costs
# - Calculates final points
```

### 5.5 URL Structure

```
# Admin (existing + new)
/admin                          # Dashboard
/admin/game_settings            # Global settings
/admin/options/:id/settings     # Per-option settings
/admin/groups/:id               # Group with QR code
/admin/submissions              # Verification queue
/admin/rules                    # Rules editor

# Player PWA (new)
/join/:token                    # QR landing page
/play                           # Home (requires session)
/play/targets                   # Target list
/play/rules                     # Rules view
/play/group                     # Group info
/play/submit/:option_id         # Submission form
```

---

## 6. Security Considerations

### 6.1 Input Sanitization

| Input | Sanitization Method |
|-------|---------------------|
| Player name | Strip HTML, limit length (50 chars) |
| Descriptions | Strip HTML, limit length (500 chars) |
| Admin messages | Allow basic HTML (bold, italic) |
| File uploads | Validate MIME type, limit to images |
| Session tokens | UUID format validation |

### 6.2 Rate Limiting (Rack::Attack)

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle("submissions/session", limit: 1, period: 10.seconds) do |req|
  if req.path.start_with?("/play/submit")
    req.session[:player_token]
  end
end
```

### 6.3 Session Security

- Session tokens: 32-character SecureRandom.urlsafe_base64
- Tokens stored in httpOnly cookies + localStorage backup
- Device fingerprint prevents simple token theft
- One device = one group (no switching)

### 6.4 Photo Handling

- Max file size: 10MB (reasonable for phone photos)
- Accepted formats: JPEG, PNG, WebP
- Photos stored temporarily in ActiveStorage
- Deleted after admin download or after 24h (configurable)

---

## 7. Testing Strategy

### 7.1 Unit Tests

- Model validations (all new models)
- Service objects (SubmissionProcessor, QueueManager)
- Point calculations with multiplier
- Cooldown checking logic

### 7.2 Integration Tests

- QR scan → session creation → group assignment
- Submission → verification → event creation
- Queue behavior (blocking, release)
- ActionCable message delivery

### 7.3 Manual Testing

- PWA installation on iOS & Android
- Camera capture workflow
- Admin verification workflow
- Real-time updates

### 7.4 Security Testing

- Rate limit verification
- Input injection attempts
- Session manipulation attempts

---

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| ActionCable connection issues | Medium | High | Fallback to polling, reconnection logic |
| Photo upload failures | Medium | Medium | Retry mechanism, clear error messages |
| Queue logic bugs | Low | High | Extensive testing, manual override in admin |
| PWA installation issues on iOS | Medium | Medium | Clear instructions, fallback to browser |
| Rate limiting too aggressive | Low | Medium | Configurable limits, admin override |
| Database performance with many events | Low | Medium | Proper indexing, pagination |

---

## 9. Implementation Checklist

### Pre-Development
- [ ] Review plan with stakeholders
- [ ] Set up development environment locally (non-Docker)
- [ ] Create feature branch

### Phase 1: Settings
- [ ] 1.1 GameSettings migration
- [ ] 1.2 OptionSettings migration
- [ ] 1.3 GameSettings singleton
- [ ] 1.4 Admin GameSettings view
- [ ] 1.5 Admin OptionSettings view
- [ ] 1.6 Reset to defaults
- [ ] 1.7 Point multiplier integration
- [ ] 1.8 Cooldown logic

### Phase 2: Player Sessions
- [ ] 2.1 Group join_token
- [ ] 2.2 PlayerSession model
- [ ] 2.3 QR generation
- [ ] 2.4 QR in admin
- [ ] 2.5 Join endpoint
- [ ] 2.6 Session management
- [ ] 2.7 Device fingerprint
- [ ] 2.8 Group name entry
- [ ] 2.9 Returning player

### Phase 3: PWA
- [ ] 3.1 PWA manifest
- [ ] 3.2 Player layout
- [ ] 3.3 Home screen
- [ ] 3.4 Hamburger menu
- [ ] 3.5 Group page
- [ ] 3.6 Targets page
- [ ] 3.7 Rules page
- [ ] 3.8 Install prompt

### Phase 4: Submissions
- [ ] 4.1 Submission model
- [ ] 4.2 Submission controller
- [ ] 4.3 Photo capture
- [ ] 4.4 Server timestamp
- [ ] 4.5 Validity checks
- [ ] 4.6 Admin queue view
- [ ] 4.7 Photo display
- [ ] 4.8 Admin message
- [ ] 4.9 Auto-verify
- [ ] 4.10 Event creation

### Phase 5: Real-time
- [ ] 5.1 ActionCable setup
- [ ] 5.2 Admin channel
- [ ] 5.3 Player channel
- [ ] 5.4 Admin notifications
- [ ] 5.5 Player notifications
- [ ] 5.6 Target list refresh

### Phase 6: Queue
- [ ] 6.1 Queue field
- [ ] 6.2 Queue detection
- [ ] 6.3 Queue visualization
- [ ] 6.4 Queue processing
- [ ] 6.5 Denied handling

### Phase 7: Photos
- [ ] 7.1 Download button
- [ ] 7.2 Browser download
- [ ] 7.3 Server delete
- [ ] 7.4 Confirmation
- [ ] 7.5 Bulk operations

### Phase 8: Rules
- [ ] 8.1 Rules generation
- [ ] 8.2 In-place editing
- [ ] 8.3 Option sync
- [ ] 8.4 Settings sync
- [ ] 8.5 CSS styling

### Phase 9: Security
- [ ] 9.1 Rate limiting
- [ ] 9.2 Input sanitization
- [ ] 9.3 CSRF protection
- [ ] 9.4 Token validation
- [ ] 9.5 Group locking
- [ ] 9.6 SQL audit
- [ ] 9.7 XSS audit

### Phase 10: Design
- [ ] 10.1 Mockups
- [ ] 10.2 Admin theme
- [ ] 10.3 Responsive
- [ ] 10.4 Verification UX
- [ ] 10.5 Dashboard

---

## 10. Notes & Decisions Log

| Date | Decision | Rationale | Status |
|------|----------|-----------|--------|
| 2026-01-17 | Use PWA over native app | Same codebase, faster dev, sufficient for needs | ✅ |
| 2026-01-17 | Server timestamp for submissions | Ensures fair ordering regardless of client time | ✅ |
| 2026-01-17 | Local photo download, not cloud | Cost savings, privacy, simplicity | ✅ |
| 2026-01-17 | Admin design last | Focus on functionality first | ✅ |
| 2026-01-17 | Multiple time windows for game | Flexibility for multi-day events with breaks | ✅ Implemented |

## 11. Implementation Progress

### Completed in Phase 1:
- ✅ GameSettings model with singleton pattern
- ✅ GameTimeWindows model for flexible scheduling
- ✅ OptionSettings model with per-option configuration
- ✅ Groups.join_token for QR code generation
- ✅ Admin interface for all settings
- ✅ Start/Stop/Reset functionality
- ✅ QR code display in Groups admin
- ✅ German rule text for all 9 options
- ✅ Seed data with defaults
- ✅ Multiple date/time input fields

### Next Steps:
1. Integrate point_multiplier into Event.calculate_points
2. Add cooldown validation to Event model
3. Create PlayerSession model and join flow

---

*End of Feature Plan*
