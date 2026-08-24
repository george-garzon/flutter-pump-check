# App Direction: Calorie-First Fitness Tracker

## Summary

The app should move toward a StepUp-style experience: dark, simple, highly readable, social, and metric-focused. The core difference is that this app tracks calories burned manually instead of step count automatically. Directly below calories, the app should track minutes worked out, also entered manually.

The product should feel like a lightweight workout scoreboard: open the app, see today’s burned calories, see training minutes, compare with friends/groups, and review progress by day, week, and month.

Reference screenshots are stored in:

`assets/StepUp/`

## Core product direction

Primary metric:

- Calories burned
- Manually entered by the user
- Displayed as the largest value on the home screen
- Used for rankings, charts, goals, streaks, and summaries

Secondary metric:

- Minutes worked out
- Manually entered with each calorie entry
- Displayed directly below calories
- Included in daily, weekly, and monthly summaries

Do not build around step tracking, distance, GPS, wearable sync, or automatic pedometer behavior. The StepUp screenshots should guide the layout and interaction style, not the exact fitness domain.

## Visual direction

Use a dark-first interface:

- Main background: near-black
- Header/nav background: saturated teal
- Selected states: lighter teal pill or teal icon
- Primary text: white
- Secondary text: muted gray
- Positive/action accent: teal
- Goal/edit accent: lime green, used sparingly
- Dividers: very dark gray, subtle but visible

The interface should be high contrast and uncluttered. Large numbers should dominate the page. Supporting data should be smaller and visually subordinate.

Suggested palette:

- Header teal: `#078C9A`
- Active teal: `#0893A5`
- Selected teal pill: `#38A6B6`
- App black: `#000000`
- Surface dark: `#1F1F1F`
- Divider dark: `#171717`
- Primary text: `#FFFFFF`
- Secondary text: `#8D8D93`
- Goal lime: `#8BC540`

## Typography and spacing

The screenshots rely on large, simple typography and generous vertical rhythm.

Guidelines:

- Use a clean sans-serif font already available in the app theme.
- The main calorie value should be oversized and centered.
- Labels should be short, lowercase where appropriate, and plain.
- Rows should have clear vertical padding and thin dividers.
- Buttons should be wide, rounded rectangles.
- Avoid dense cards on the main screen; StepUp’s look is flatter and list-driven.

Approximate hierarchy:

- Main metric value: very large, 80-110px on mobile
- Main metric label: 22-28px
- Secondary metric line: 22-28px
- Segment tabs: 18-22px
- List row names: 24-30px
- List row values: 24-30px
- Muted captions: 14-18px

## Navigation model

Use a bottom navigation bar similar to the screenshots:

- Home
- History
- Social/messages or groups
- Notifications/activity
- Settings

The active tab should use teal. Inactive icons should be white. The bottom bar should sit on a dark surface and remain visually separate from the black page background.

## Home screen direction

The home screen should be the primary scoreboard.

Top area:

- Teal header
- Centered app title/logo
- Left action: share or profile
- Right action: add entry
- Period tabs: Today, Yesterday, Week, Month
- Selected period uses a rounded lighter-teal pill

Main metric area:

- Label changes by selected period:
  - Today: `calories today`
  - Yesterday: `calories yesterday`
  - Week: `avg calories last 7 days` or `calories this week`
  - Month: `avg calories this month` or `calories this month`
- Large centered calorie number
- Small chevron on the right to indicate drill-in/history
- Secondary line directly below:
  - Today: `{minutes} min trained`
  - Week/Month: `{avgMinutes} min/day` or `{totalMinutes} min trained`

Social comparison area:

- Toggle between Friends and Groups
- Friends selected by default
- Rows ranked by calories for the selected period
- Show rank, avatar/icon, name, calorie value, and timestamp/subtitle
- For groups, rank groups by total or average calories depending on group rules

Primary action:

- Replace StepUp’s “Sign in to add friends” button with the most relevant state:
  - Signed out: `Sign in to add friends`
  - Signed in with no workout today: `Add today’s workout`
  - Signed in with workout today: `Add another workout`

Do not include ads.

## Manual entry flow

The add button should open a quick manual entry sheet or screen.

Required fields:

- Calories burned
- Minutes trained
- Date

Optional fields:

- Workout type
- Notes
- Group visibility or privacy

Expected behavior:

- User can add multiple entries per day.
- Daily total calories is the sum of entries for that date.
- Daily total minutes is the sum of workout minutes for that date.
- Editing/deleting entries should update totals, history, rankings, and streaks.

Entry form direction:

- Dark modal or full-screen sheet
- Large numeric fields
- Stepper controls can be used for goals, but direct typing should be supported for workout entries
- Primary CTA: `Save workout`
- Secondary CTA: `Cancel`

## History screen direction

The history screen should mirror the StepUp screenshots but use calories.

Header:

- Teal background
- Title: `History`
- Summary rows:
  - `Daily goal: {goal} cals`
  - `Longest streak: {n} days`
  - `Best week: {date} · {calories} cals`
  - `Best month: {month} · {calories} cals`

Tabs:

- Day
- Week
- Month
- Calendar

Day view:

- List daily calorie totals
- Show minutes trained as a muted subtitle

Week view:

- Horizontal bars grouped by week
- Bar length represents calories burned
- Week average or total shown at the right
- Show minutes trained as secondary text

Month/calendar view:

- Calendar grid
- Each date shows compact calorie value, such as `450`
- Selected date is highlighted with a teal block
- Empty days remain muted

## Goal model

The user should set a daily calorie goal.

Goal editing should follow the StepUp pattern:

- Bottom sheet
- Title: `Daily Calorie Goal`
- Done button
- Large goal number
- Minus and plus controls
- Supporting guidance text

Suggested increments:

- Plus/minus by 50 calories
- Long-term option: allow direct numeric input

Minutes can have an optional daily goal later, but the immediate direction is calorie-goal first.

## Settings direction

Settings should use simple rows on a black background with gray section separators.

Adapt StepUp rows into this domain:

- Daily calorie goal
- Default workout duration
- Streak mode
- Dark theme
- Notifications
- Update profile
- Recaps
- Invite friends
- Hidden friends

Remove or avoid:

- Sync with wearable
- Distance unit
- Step-specific settings

## Social and ranking behavior

Rank users primarily by calories burned.

For each period:

- Today: daily calorie total
- Yesterday: previous day calorie total
- Week: weekly calorie total or daily average
- Month: monthly calorie total or daily average

Rows should show:

- Rank
- Avatar
- Name
- Calories
- Secondary detail:
  - `now`
  - entry time
  - `{minutes} min`
  - `{avg} avg`

Use minutes as context, not as the primary ranking value.

## Streak behavior

A streak should count days where the user meets or exceeds the daily calorie goal.

Potential modes:

- Strict: every calendar day must hit the goal
- Flexible: allow a limited number of rest days per week

Initial implementation can default to Strict.

## Data model direction

Recommended workout entry shape:

```text
WorkoutEntry
- id
- userId
- date
- caloriesBurned
- minutesTrained
- workoutType optional
- notes optional
- createdAt
- updatedAt
```

Derived totals:

```text
DailyWorkoutSummary
- date
- totalCaloriesBurned
- totalMinutesTrained
- entryCount
- goalMet
```

The UI should read summaries for speed, but entries remain the source of truth.

## Implementation priorities

1. Convert copy and metrics from steps to calories.
2. Make the home screen match the StepUp layout pattern.
3. Add manual workout entry for calories and minutes.
4. Update history views to display calorie totals and workout minutes.
5. Update settings and goal editing for daily calorie goals.
6. Update friends/groups ranking logic to use calories.
7. Polish dark theme, teal navigation, row spacing, and selected states.

## Non-goals

These are not part of the intended direction right now:

- Automatic step counting
- Wearable sync
- Distance tracking
- GPS workout tracking
- Calorie estimation from workout type
- Ads

## Product principle

The app should answer one question immediately:

“How many calories did I burn today, how long did I train, and how do I compare?”

