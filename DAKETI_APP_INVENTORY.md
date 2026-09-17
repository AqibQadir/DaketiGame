# Daketi Phase I — Full App Inventory

**Prepared from the implemented Flutter project**  
**Audit date:** 16 September 2026  
**App format:** Landscape Flutter game for Android, iOS, Web, Windows, macOS, and Linux

## 1. App summary

Daketi Phase I currently contains a complete navigation structure for onboarding, account access, guest play, single-player/AI play, multiplayer team rooms, gameplay, results, tutorial, profile/history, social areas (Baithak), tables, shop (Dukan), side quests, leaderboard, settings, legal pages, and support.

Current visual identity:

- Rainy South Asian street / Chai Hotel setting
- Orange paint-brush buttons
- Black, cream, orange, and translucent-glass interface
- “Dirty Brush” display font
- Standard Material icons are still used in many places as temporary icons
- Playing cards use a complete 52-card PNG deck

Important status note: some UI is functional and backed by API/socket code, while some controls are visual placeholders. In particular, social-media icons, several audio hooks, shop purchasing, some Baithak actions, and certain settings still need final configuration or backend integration.

## 2. Complete screen/module list

The app defines **34 named routes**, plus dialogs and gameplay overlays. Grouped as user-visible pages/flows, the inventory is:

### Launch, legal, and onboarding

1. Splash
2. Terms & Conditions
3. Privacy Policy
4. Welcome
5. Login / Signup choice
6. Guest name
7. Guest opponent selection
8. Login
9. Signup

### Main game experience

10. Home
11. Start game / gameplay
12. Interactive game tutorial
13. Multiplayer setup
14. Multiplayer waiting room
15. Game results

### Player account

16. Profile
17. Edit profile dialog
18. Change password dialog
19. Game history
20. Settings

### Menu and ranking

21. Menu
22. General Settings / account information
23. Leaderboard

### Baithak / social

24. Baithak hub
25. My Clan
26. Global players
27. Chat Lobby
28. Personal Chat

### Economy and progression

29. Dukan / Shop
30. Side Quests
31. Tables list
32. Individual table room

### Help and support

33. Support hub
34. Contact Us
35. Report an Issue
36. FAQs

## 3. Button and action names

### Splash and legal

- **Terms & Conditions:** acceptance/continue button supplied dynamically by the legal flow
- **Privacy Policy:** acceptance/continue button supplied dynamically by the legal flow
- Standard close/back control where applicable

### Welcome and account access

- **Welcome:** Play, Play as guest, Menu, Settings, Support
- **Login / Signup choice:** Login, Signup, Connect
- **Guest name:** Play, Menu, Settings, Support
- **Guest opponents:** 1 opponent, 2 opponents, 3 opponents, Custom, Beginner, Master, Play/Starting
- **Login:** Login, Forgot password?, Reset Password → Cancel, Send; Menu, Settings, Support
- **Signup:** Signup, Menu, Settings, Support
- Social/media icon controls displayed on welcome/auth screens: Facebook, Camera/Instagram-style icon, Play/YouTube-style icon, Music/TikTok-style icon. These currently have no action connected.

### Home

- Start game
- Missions
- Daily (badge count shown)
- Clan
- Shop
- Settings
- Profile
- Support
- Teams
- Ranking
- Menu

### Gameplay

- Card selection/tap controls
- Table-card capture selection
- Draw card / action controls depending on game state
- End turn
- Bike Daketi special action/overlay
- Chat open/close
- Send chat message
- Moves/history panel
- Leave/close game
- Leave Match confirmation
- Cancel
- Results: Replay, Home

### Tutorial

- Skip Tutorial
- Back
- Next
- Start Playing
- End turn
- Context-sensitive action for the selected tutorial card
- Skip confirmation: Continue Tutorial, Skip Tutorial

Tutorial subjects shown to the user:

- Game Overview
- This Is Your Hand
- It Is Your Turn
- Select a Card
- Capture From the Table
- Legal Move Controls
- Extend Your Stack
- Steal a Stack
- Invalid Move
- Scores and Results

### Multiplayer

- Create room / Please wait
- Join room / Please wait
- Room-size selection: 2, 3, or 4 team members
- Copy room code
- Ready / Ready ✓
- Close/back

### Profile and account

- Edit
- History
- Log Out
- Change password
- Resend verification
- Edit Profile dialog: Cancel, Save
- Change Password dialog: Cancel, Update

### Menu, settings, and leaderboard

- **Menu:** General settings, Leaderboard, How to play
- **General Settings:** Logout
- **Settings:** Tutorial; Music toggle; Media toggle; Vibration toggle; Notification toggle; Language selector (English, Urdu)
- **Leaderboard:** ranked player list; navigation controls

### Baithak / social

- My Clan — Make Your Own Clan
- Global — pairs randomly with player
- Chat Lobby — chat with people across the globe
- Chat With AI — practice with AI
- Player-card action button (dynamic action text)
- Personal chat: Send
- Shared navigation: Settings, Profile, Support, Menu/close

### Tables

- Enter Match
- Table/category navigation
- Settings, Profile, Support, close/back

Available visual table rooms:

- Old Lahore — Classic Street Vibes
- Karachi Clan — The City That Never Sleeps
- Dubai Rise — Skyscrapers, High Rolls, Only for the Bold
- Thai Bliss — High Stakes, High Rollers, Only for the Bold

### Dukan / shop

- Tabs: Coins, XP, Tables
- Buy
- Coin packages shown: 50,000; 100,000; 250,000; 500,000; 750,000; 1,000,000
- XP packages shown: 10,000; 20,000; 30,000; 40,000; 50,000; 60,000
- Table items shown: Old Lahore, Thai Bliss, Karachi Clan, Dubai Bliss, Dubai Rise, London Lounge

### Side Quests

- Tabs: Rookie, Champion, Legend
- Buy Coins
- Currency/status displays: 125,000 and 25,000
- 18 quest items across three tiers, with rewards of 100, 500, and 1,000

### Support

- Contact us
- Report an issue
- FAQs
- Email us
- WA support
- Call support
- Submit issue
- FAQ expand/collapse rows

### Common system buttons

- Close (custom cross image)
- Back
- Menu
- Settings
- Profile
- Support
- OK alert action

## 4. Text fields and input names

| Screen | Field name / placeholder | Input behavior |
|---|---|---|
| Guest name | Temporary username | Single-line name entry |
| Login | Email | Email keyboard |
| Login | Password | Hidden/obscured text |
| Reset password | Email | Email entry in dialog |
| Signup | Email | Email keyboard |
| Signup | Username | Single-line user name |
| Signup | Password | Hidden/obscured text |
| Signup | Re-enter password | Hidden confirmation |
| Edit Profile | Name | Single-line name |
| Edit Profile | Date of birth (YYYY-MM-DD) | Date entered as text |
| Change Password | Current password | Hidden password |
| Change Password | New password | Hidden password |
| Multiplayer | Player name | Single-line player name |
| Multiplayer | Room size | Dropdown: 2/3/4 team members |
| Multiplayer | 4-digit code | Numeric room-code entry |
| Personal Chat | Write a Message... | Chat message |
| In-game Chat | Type a message… | Chat message |
| Report An Issue | What problem did you face... | Multi-line issue description |

Recommended missing inputs/validation for product review:

- Signup has no separate display name, phone, date of birth, country, or referral field.
- Password requirements and strength guidance are not visibly defined.
- Date of birth uses free text instead of a date picker.
- Report Issue has no category, attachment/screenshot, device info, or contact-email field.
- Chat has no visible attachment, emoji, voice-note, block, or report controls.

## 5. Sound inventory

The project packages **18 WAV sound files**. Sound playback is split into UI, gameplay, and alert channels, allowing effects to overlap. Playback mixes with other audio and temporarily ducks other sound on Android.

### Connected and triggered in current gameplay

| Sound event | Audio file | Use |
|---|---|---|
| Card selected | `SwipeCard.wav` | Player selects a card |
| Opening shuffle | `cardshuffleatbeginning.wav` | Game/deal begins |
| Card placed/slapped | `throwcardontable.wav` | Card played to table |
| Good move | `good move.wav` | Successful normal move |
| Special card | `Special card.wav` | Special move/card event |
| Steal card | `stealcard.wav` | Stack/card steal |
| Invalid move | `invalidmove.wav` | Illegal action warning |
| Next player | `nextplayermove.wav` | Turn moves to another player |
| 10-second warning | `timerwarning10secondsleft.wav` | Timer reaches warning point |
| 5-to-0 countdown | `timerwarning5-0secondleft.wav` | Final countdown |
| Round won | `rOUNDwIN.wav` | Winner result sting |

### Implemented in the sound service but not currently called

| Sound event | Audio file | Status |
|---|---|---|
| General UI click | `CardMove.wav` | Playback method exists; no current call site |
| Challenge | `Challenge.wav` | Playback method exists; no current call site |

### Packaged but not connected

- `CardShuffle.wav`
- `Timer Start.wav`
- `timerwarning.wav`
- `TurnChange.wav`
- `TurnChange2.wav`

### Empty sound hooks requiring completion

- Player joined
- Match found
- Reaction
- Game lost

## 6. Image and visual asset inventory

### File formats and totals

- **73 PNG files** in the main image tree
- **5 SVG logo variants**
- **52 PNG playing-card faces** (a full standard deck)
- **1 PNG card back**
- Platform icons are additionally supplied for Web, Android, iOS, macOS, and Windows
- **1 custom TTF font:** Dirty Brush Regular

### Image types used

| Type | Format | Current assets/use |
|---|---|---|
| Environmental backgrounds | PNG/JPG-style raster stored as PNG | Police/bike chase, Chai Hotel rainy street, gameplay table |
| Logos | SVG | Primary, black, orange, white, white/orange variants |
| Button artwork | Transparent PNG | Standard orange brush, action brush, Facebook brush |
| Close control | Transparent PNG | Painted/custom close cross |
| Playing cards | Transparent PNG | 52 face cards + card back |
| Player portraits | Transparent PNG | Hamza, Ayesha, Bilal, Mahnoor, Saad; plus generic avatar |
| Table-room artwork | Transparent PNG | Old Lahore, Karachi Clan, Dubai Rise, Thai Bliss |
| App icon | PNG and platform-specific derivatives | Launcher/browser/desktop icons |
| UI icons | Flutter Material vector icons | Menu, settings, profile, support, missions, daily, clan, shop, teams, ranking, social/media, chat/send, close |

### Main image files and dimensions

- Chai Hotel background: 2622 × 1206 PNG
- Chase background: 2048 × 941 PNG
- Gameplay table background: 1842 × 854 PNG
- App icon: 1024 × 1024 PNG
- Card back: 181 × 253 PNG
- Five named player portraits: 256 × 256 PNG each
- Generic player avatar: 81 × 81 PNG
- Four table-room images: 176 × 228 PNG each
- Button brush: 152 × 39 PNG
- Action button brush: 150 × 34 PNG
- Facebook brush: 154 × 40 PNG
- Close cross: 42 × 42 PNG

### Likely legacy/duplicate assets

- `background1.png` appears to be an older/duplicate chase background.
- `background2.png` appears to be an older/duplicate Chai Hotel background.
- The current app constants use `chase_background.png` and `chai_hotel_background.png` instead.

## 7. Current content and placeholder status

The following should be reviewed before presenting the app as production-complete:

- Material icons are explicitly described in the project as temporary until custom Figma icons are supplied.
- Facebook, camera/social, play/video, and music/social icons have disabled actions.
- Player joined, match found, reaction, and game-lost sound methods are empty.
- Dukan shows product options, but final prices, payment flow, purchase confirmation, ownership, and restore-purchase behavior need product/backend approval.
- Some account information in General Settings is sample content: “Dakait 420,” sample email, and sample Pakistani phone number.
- AI/opponent and player display names include sample personas.
- Table naming is inconsistent: the shop mentions Dubai Bliss and London Lounge, but only four table-room assets/routes exist.
- Language selector shows English and Urdu; full localization coverage should be verified.
- Settings toggles need persistence and confirmed runtime effects.
- Legal copy, privacy disclosures, support contacts, and store-compliance wording need final legal/business approval.

---

This inventory describes what is present in the current source project and distinguishes visible UI, connected behavior, and known placeholders.
