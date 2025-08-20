# User Flow: Habits & Notes

This document describes the end-to-end user experience: screen transitions, key actions, and state changes. It complements the technical README by focusing on how users move through the app.

## Overview

- Startup → Splash (auth check)
- Authenticated → Home
- Unauthenticated → Auth (Sign In / Sign Up)
- From Home → Create/Edit Habit, Open Habit Details, Toggle Completion, Search
- From Habit Details → Create/Edit/Delete Notes
- Sign Out from Home menu → back to Auth

## Navigation Flow

1) Launch App
- App shows `SplashScreen`
- `AuthCubit` listens to Firebase `authStateChanges`
- If user is signed in → navigate to `HomeScreen`
- If not signed in → navigate to `AuthScreen`

2) Auth Screens
- Tabbed interface: Sign In | Sign Up
- Visible field labels and improved spacing for inputs
- Successful auth → `Authenticated` state → `HomeScreen`
- Errors shown as snackbars; user remains on `AuthScreen`

3) Home Screen (single scroll)
- Profile header with email and member-since date
- Search bar (debounced)
- Analytics card with paging (Today | Week) and segmented control switcher
- Habits list
- FAB to create a habit
- App bar menu → Sign Out

4) Habit Details
- Habit stats (streak, total completions, created date)
- Notes list for that habit
- Add/Edit/Delete notes
- App bar actions: Edit habit, Mark Complete

5) Sign Out
- From app bar menu on Home → Sign Out → back to `AuthScreen`

## First Launch / Splash
- Purpose: Wait for auth state to resolve and initial services to be ready
- UI: Animated logo/title and loading indicator
- Transitions:
  - If Firebase has a current user: `Authenticated → Home`
  - Else: `Unauthenticated → Auth`

## Sign Up Flow
- User opens `AuthScreen`, selects "Sign Up" tab
- Enters email + password + confirm password
- Taps "Sign Up"
- `AuthCubit.signUp(email, password)`
- On success, the auth stream emits an authenticated user
- App saves user locally (Hive) and routes to `HomeScreen`
- On error (weak password, email in use, etc.), snackbar shows the message

## Sign In Flow
- User opens `AuthScreen`, stays on "Sign In" tab
- Enters email + password
- Taps "Sign In"
- `AuthCubit.signIn(email, password)`
- On success, the auth stream emits an authenticated user → `HomeScreen`
- On error (wrong password, user not found, etc.), snackbar shows the message

## Home Screen Flow
- On first build:
  - Loads habits (`HabitsCubit.loadHabits()`)
  - Triggers sync (`SyncCubit.syncData(userId)`)
  - Analytics card appears after initial habits are loaded
- Interactions:
  - Search field filters the habits list with 300ms debounce and hides analytics during input
  - FAB opens `CreateHabitScreen`
  - Tapping a habit opens `HabitDetailScreen`
  - Tapping progress ring toggles completion (with Undo snackbar)
  - Slide a row left to reveal Delete; tap Delete to confirm
  - App bar menu → Sign Out

## Create/Edit Habit Flow
- User enters or updates title
- Picks a color (visual preview updates)
- Taps "Save" / "Update"
- `HabitsCubit.createHabit(...)` or `HabitsCubit.updateHabit(...)`
- Persist locally first; remote write in background
- Navigates back to Home; list updates immediately

## Toggle Habit Completion Flow
- User taps the progress ring or toolbar action
- `HabitsCubit.toggleHabitCompletion(habit, userId)`
- UI updates optimistically; snackbar offers Undo
- Change persists locally then syncs to Firestore

## Habit Detail Flow
- Displays up-to-date habit info (streak, total completions)
- Notes section:
  - Add Note → `CreateNoteScreen`
  - Tap Note → edit in `CreateNoteScreen`
  - Delete Note → swipe to reveal Delete; tap to confirm
- Notes operations update immediately and sync in background

## Notes Flows
- Create:
  - `NotesCubit.createNote(text, habitId, userId)`
  - Local save first → remote save best-effort
- Edit:
  - `NotesCubit.updateNote(note, userId)`
  - Local update first → remote update best-effort
- Delete:
  - `NotesCubit.deleteNote(noteId, userId)`
  - Local delete first → remote delete best-effort

## Sync & Offline Behavior
- Offline-first: All changes are stored in Hive immediately
- Sync runs after auth and on Home; uses two-way merge (last-write-wins)
- `SyncIndicator` in app bar shows: idle, syncing, completed (with time), or error

## State Model (High Level)
- Auth States: `AuthInitial` → `AuthLoading` → `Authenticated` | `Unauthenticated` | `AuthError`
- Habits States: `HabitsInitial` → `HabitsLoading` → `HabitsLoaded` | `HabitsError`
- Notes States: `NotesInitial` → `NotesLoading` → `NotesLoaded` | `NotesError`
- Sync States: `SyncInitial` → `SyncIdle` | `SyncInProgress` | `SyncCompleted` | `SyncError`

## Persistence
- Hive boxes:
  - `habitsBox`: all habits
  - `notesBox`: all notes
  - `userBox`: `current_user`
- On auth change, the app updates `userBox`; on sign out, clears it

## Platform Notes
- iOS/Android: Requires proper Firebase config files
- Desktop/web support depends on platform Firebase availability and configuration

## QA Scenarios
- Fresh install → Splash → Auth → Sign Up → Home
- App relaunch when signed in → Splash → Home
- Wrong password → stays on Auth with snackbar
- Create/edit habit with color selection → verify exact color on list and detail
- Toggle completion → Undo works; reflects after re-entering screen
- Add/Edit/Delete notes → reflected instantly; persists after app restart
- Sign Out → returns to Auth; next relaunch stays on Auth
