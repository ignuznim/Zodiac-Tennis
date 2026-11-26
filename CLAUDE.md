# 십이지 테니스: working rules

The owner reviews every change on a phone. These rules come from their repeated requests; follow them without being asked.

## Text inside boxes
- Every piece of text sits inside its box with even margins: the same space above and below, and on both sides.
- When a box holds several lines (a title and one or two lines under it), centre the whole block vertically and check the bottom margin as carefully as the top.
- Everything inside one button or card is one block, centred in it both ways (the owner has asked many times): a picture with a title and a line under it, a label with a bar under it, an icon with a word. Measure the block (picture width + gap + widest line; first line top to last line bottom) and place the block, never the parts one by one at fixed offsets.
- Text must never run past a box's edge or be cut off. Shrink it to fit (measure with `ctx.measureText`) rather than let it overflow.
- After any layout change, take a screenshot at phone size (390 x 844, and a short screen such as 390 x 600) and look at the margins before committing.
- No text is smaller than MIN_TEXT (16 in the 720-wide page, set beside text() in index.html). Shrink-to-fit stops there; if a label still does not fit, move it somewhere with room or use two lines instead of going smaller. Never cut a word into an abbreviation nobody can read (타이브레이크 is never 타이브).
- Use the plain fonts (F_T, F_B) for anything that must read cleanly; the handwritten font (F_H) has uneven spacing, so keep it to short accents.

## Buttons and space
- A button need not fill the width of its box or the screen: size it to its words plus comfortable padding.
- A button that confirms, decides, goes on or closes (확인, 결정, 다시 하기, 닫기, 로그아웃 …) always sits at the right of its row or box, never centred. Back and home are square icon keys at the left of the bottom row; a refresh key sits at the right where there is no such button. The same row looks the same on every page. Prefer a small icon to a worded button wherever the icon reads at once (a person for a profile, a cross to close), placed beside what it acts on. Popups and cards stay compact and dense (the 명예의 전당 score card is the model): no large empty areas, no oversized boxes; leave even margins instead.

- The same thing looks the same everywhere, always (the owner has asked many times): what sits in the same place on different pages, or shows the same content (the ticket count, a page's main key at the bottom right, a switch), is drawn by one shared function at one size. Before drawing anything, look for where the game already shows it and reuse that; when two pages share a row (뽑기 and 업적), its keys keep one size so nothing jumps as you switch. Slides follow the order things sit in: going to what is on the left moves the page right.
- When one of a family is fixed (a window, a card, a verdict, a key), fix every member of that family the same way in the same push, size, type and style alike; only colour may tell them apart. The owner should never have to ask for each one.
- One hierarchy, applied by what a thing is (the owner's rule, 2026-11-26), not one look pasted everywhere:
  1. Windows and panels: cream fill, the dark outline (OUT, 3), a soft shadow.
  2. Things you tap (keys, buttons, item and choice cards): the dark outline, or the item's grade colour on item cards, and a drop under it that it sinks into when pressed.
  3. Things you only read inside them (stat tiles, tables, pictures, info lines): no dark outline: a light rim (#e6dccd, 2) or a soft fill.
  An empty place to fill is the tappable card, dashed. Before removing or adding outlines on one page, place each part in this order and keep the other pages consistent with it.
- Windows come in three widths (the owner's choice, 2026-11-26), POP_S / POP_M / POP_L in index.html: S (468) for a question or a short notice (홈으로 확인, 일시정지, 경기 보상, 코드로 참가, 설정); M (611) for one card or form or a short list (프로필, 품계, 점수 카드, 방 만들기, 공지사항, 조작법, 레슨 고르기, 개발자에게 한마디); L (the page's width) for the closets. A window's keys are popKey: 56 tall, 25 type as shown, sized to their words at the bottom right; a pair shares one width, the one that goes on at the right.
- Before committing any UI change, check the whole screen, not just the part touched: nothing overlaps (text on text, text past its box, buttons on buttons, a popup's parts on the page under it), margins are even and the same from screen to screen, and things sit on a grid: rows share one left edge and one baseline, columns line up, equal items get equal sizes and gaps. Run the layout audit (overlaps and overflow at 390 x 844 and 390 x 600) and look at the screenshots.

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

## Design skills (.claude/skills, added 2026-11-25 from the owner's uploads)
- Kept (2026-11-26, the rest removed at the owner's request): emil-design-eng and animate (motion), apple-design, gestures and mobile-native (touch and phone), ui-ux-pro-max (run its search with `python3 -I .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --domain <domain>` from the repo root), web-design-guidelines (review). Reach for one only when the work needs it; the owner's own words and the rules above come first.
- Use them for UI, motion and review work. They are written for DOM, CSS and React; this game draws everything on one canvas, so carry over the principle (timing, easing, what to animate, press feedback, touch targets) and implement it in the canvas code. Ignore their advice about frameworks, libraries and CSS that does not exist here.
- These working rules come first where a skill disagrees.
