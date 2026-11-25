# 십이지 테니스: working rules

The owner reviews every change on a phone. These rules come from their repeated requests; follow them without being asked.

## Text inside boxes
- Every piece of text sits inside its box with even margins: the same space above and below, and on both sides.
- When a box holds several lines (a title and one or two lines under it), centre the whole block vertically and check the bottom margin as carefully as the top.
- Text must never run past a box's edge or be cut off. Shrink it to fit (measure with `ctx.measureText`) rather than let it overflow.
- After any layout change, take a screenshot at phone size (390 x 844, and a short screen such as 390 x 600) and look at the margins before committing.
- No text is smaller than MIN_TEXT (16 in the 720-wide page, set beside text() in index.html). Shrink-to-fit stops there; if a label still does not fit, move it somewhere with room or use two lines instead of going smaller. Never cut a word into an abbreviation nobody can read (타이브레이크 is never 타이브).
- Use the plain fonts (F_T, F_B) for anything that must read cleanly; the handwritten font (F_H) has uneven spacing, so keep it to short accents.

## Buttons and space
- A button need not fill the width of its box or the screen: size it to its words plus comfortable padding, and centre it, unless it is one of the bottom row's main buttons. Prefer a small icon to a worded button wherever the icon reads at once (a person for a profile, a cross to close), placed beside what it acts on. Popups and cards stay compact and dense (the 명예의 전당 score card is the model): no large empty areas, no oversized boxes; leave even margins instead.

## Drawing
- Work of one kind stays of one kind: a redrawn animal, item or button must match the others in style (outline, shading with shade(), proportions).
- After touching any shared drawing code (drawAnimal, drawHead, drawEars, drawTail, items), render all twelve animals front and back and look at every one before committing, not just the one changed.
- index.html is full of one-line chains like `if (...) { } else if (...) { }`: never add a `//` comment in the middle of such a line; it silently comments out the rest.

## Versions (APP_VERSION in index.html)
- Keep the numbers small: players should never see something like 1.10.0. The owner set it back to 1.8.6 on 2026-11-16.
- Most updates, new content included (achievements, items, tuning), raise only the last number, one step per batch of work (1.8.6 -> 1.8.7). Do not raise it for every small request.
- Not every day either: the owner finds daily versions too many for players. Keep adding to the current version and its note; move the number only when the owner asks, or for a big batch of new content, and then ask first.
- Raise the middle number only for a big new way to play (doubles, online for four, the hall of fame were that size), and ask the owner first.
- Renaming things (items, labels) does not change the version at all.
- Item names live in two places, index.html (ITEMS) and supabase/2_wardrobe.sql: change both, and give the owner the SQL to run.

## The database
- The database is kept in numbered files, one per part, so the owner can save them apart and re-run only the part that changed: supabase/1_ranking.sql, 2_wardrobe.sql, 3_feedback.sql, 4_lobby.sql (open rooms for quick match and the room list, who is online), 5_notice.sql (공지사항, written by the owner in the Table Editor), 6_plays.sql (every finished match, for the owner to read in the Table Editor: plays_recent, plays_daily, plays_players), 7_social.sql (rival records from online matches, members' public profiles), 8_tiers.sql (조선 품계 tiers: each member's Elo score and days played; the 티어 랭킹 board). A new part gets the next number.
- When a part changes, give the owner that whole file again (not a fragment), and say which file it is.
- Send that SQL as an attached file (the whole numbered file), and say in one line which file to run in the SQL Editor. Do not paste the SQL into the reply: long SQL fills the owner's chat.
- Every file must stay safe to run again on the live database: create ... if not exists, create or replace, drop policy if exists, on conflict do update. Test it twice on an empty database and once on one that already has data.

## Other standing choices
- Computers (partners and opponents) never wear items; items apply only to the player.
- Nicknames are 1 to 8 letters everywhere (game and database, since 2026-11-19; no longer names exist). Check layouts with an 8-letter name, never 10.
- 명예의 전당 stays at night.

## 공지사항 (notices.json)
- Every push that players can notice gets a note in notices.json, written by Claude without being asked; the owner's own notes (events, notices) live in Supabase (5_notice.sql) and both show together.
- APP_VERSION raised: kind "update", title "1.9.4 업데이트". Not raised: kind "patch", title "1.9.3 패치"; patches on the same day go into one note (add lines, move created_at to now).
- A patch made after an update, before the version moves again, goes into that update's note instead of a separate patch note. A line the patch makes untrue is replaced, not kept beside the new one (the count moved from the 온라인 button to beside 로그인: only the new place is written).
- Short Korean lines starting with "· ", in players' words (what they will see or feel), no code or file names. Fixes for testing tools or invisible changes get no note.
- Lines are as short as a headline ("· 업적 80개, 히든 업적 추가"), no explanations.
- Keep notes short so players can take them in at a glance: only big changes (new content, new features, rule changes, bugs players actually hit). Small touch-ups get no line at all: redrawn or renamed items, colours, layout nudges, wording. A push with nothing big gets no note, not even a patch note. Three or four lines per note at most; merge related lines.
- created_at is UTC ISO (date -u); id is unique text such as "patch-2026-11-17" or "update-1.9.4". Newest first is not needed; the game sorts.
