# Arcade Aura (Flutter + Firebase Multiplayer Mini Games)

A lightweight, beginner-friendly college project with modern UI and real-time multiplayer mini games.

## Dependencies

Add these in `/tmp/workspace/AryanNagori1405/arcade-aura/pubspec.yaml`:
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `google_sign_in` (optional)
- `lottie` (for loading/match animations)
- `intl`

Then run:
```bash
flutter pub get
```

## Firebase setup

1. Create Firebase project.
2. Enable **Authentication** (Email/Password, optional Google).
3. Create **Cloud Firestore** database.
4. Put actual values in `/tmp/workspace/AryanNagori1405/arcade-aura/lib/firebase_options.dart`.
5. Add platform files (`google-services.json`, `GoogleService-Info.plist`) for Android/iOS.

## File structure

- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/main.dart` – app entry, auth gate
- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/firebase_options.dart` – Firebase config template
- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/services/`
  - `auth_service.dart` – signup/login/logout/google/forgot password
  - `user_service.dart` – profile stats + leaderboard stream
  - `room_service.dart` – create/join/random matchmaking + room updates
  - `trophy_service.dart` – trophy rules and stats update
- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/screens/auth/` – login/signup
- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/screens/home/home_screen.dart` – profile, trophies, all game buttons
- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/screens/lobby/lobby_screen.dart` – create room/join room/random
- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/screens/games/` – all 6 game screens
- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/screens/profile/profile_screen.dart` – profile + history + favorite game
- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/screens/leaderboard/leaderboard_screen.dart` – realtime ranking
- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/utils/game_logic.dart` – all winner checks and board logic
- `/tmp/workspace/AryanNagori1405/arcade-aura/lib/widgets/` – neon buttons + gradient scaffolds

## Firestore data model

### `users/{uid}`
```json
{
  "username": "Aryan",
  "email": "aryan@mail.com",
  "trophies": 25,
  "wins": 10,
  "losses": 6,
  "draws": 2,
  "favoriteGame": "tic_tac_toe",
  "matchHistory": [
    {"gameType": "tic_tac_toe", "result": "win", "roomId": "AB12", "at": "..."}
  ]
}
```

### `rooms/{roomId}`
```json
{
  "gameType": "tic_tac_toe",
  "status": "waiting | playing | finished",
  "players": ["uid1", "uid2"],
  "playerNames": {"uid1": "A", "uid2": "B"},
  "turnUid": "uid1",
  "winnerUid": "uid1",
  "board": [],
  "moveCount": 0,
  "matchData": {},
  "updatedAt": "serverTimestamp"
}
```

## Multiplayer synchronization (how it works)

1. Every game uses a single `rooms/{roomId}` document as the **source of truth**.
2. Both devices subscribe using Firestore snapshots.
3. A move updates room fields (`board`, `matchData`, `turnUid`, `moveCount`).
4. UI updates immediately on both players because snapshots are real-time.
5. `finishRoom()` uses transaction logic so result is written once.
6. After finish, `trophy_service.dart` updates both users.

## Turn handling

- `turnUid` stores who can move now.
- On valid move, app switches `turnUid` to the other player.
- Invalid moves are blocked in UI (not your turn, occupied cells, etc).

## Winner detection + game state updates

- Winner checks are done after each move from current board/matchData.
- If winner/draw found, room status becomes `finished`.
- Trophy rules applied:
  - Win = `+3`
  - Loss = `-3`
  - Draw = `+1`

## Game-wise logic summary

### 1) Tic Tac Toe
- Board: 9 cells (`board` list)
- Turn markers: `X/O` from player order
- Winner check: all 8 winning combinations
- Sync: each tap writes full board + next turn

### 2) Connect 4
- Board: `6x7` grid in `board`
- Move: drop token into selected column (lowest empty row)
- Winner: horizontal/vertical/diagonal 4-match checks
- Sync: grid + turn updates after token drop

### 3) Rock Paper Scissors (Best of 3)
- Secret choice saved in `matchData.choices`
- Reveal after both choices submitted
- Round score in `matchData.scores`
- Finish at 2 wins or 3 rounds

### 4) Memory Match
- Shared shuffled deck in `matchData.deck`
- Turn-based card picks (`matchData.picks`)
- Match adds to `matchData.matched` and score
- Timer support via `matchData.deadlineMs`

### 5) Quiz Battle
- Same question index for both players (`matchData.qIndex`)
- Answers tracked in `matchData.answers`
- Timer per question via `deadlineMs`
- Auto scoring when both answer or timer ends

### 6) Snake & Ladder (Simple)
- Positions in `matchData.positions`
- Dice roll synced in `matchData.lastDice`
- Turn-based movement with snake/ladder jumps
- First to cell 30 wins

## UI/UX highlights included

- Dark gradient premium gaming UI
- Neon/glow animated buttons (`AnimatedContainer`)
- Hero profile animation
- Fade page transitions
- Responsive card-based layout
- Smooth loading indicators

## Run

```bash
flutter pub get
flutter run
```

## Optional improvements

- Add Lottie JSON assets for match found / victory / defeat
- Add stricter Firestore security rules
- Add disconnect handling for player leave/rejoin
