# 십이지 테니스: working rules

The owner reviews every change on a phone. These rules come from their repeated requests; follow them without being asked.

## Text inside boxes
- Every piece of text sits inside its box with even margins: the same space above and below, and on both sides.
- When a box holds several lines (a title and one or two lines under it), centre the whole block vertically and check the bottom margin as carefully as the top.
- Text must never run past a box's edge or be cut off. Shrink it to fit (measure with `ctx.measureText`) rather than let it overflow.
- After any layout change, take a screenshot at phone size (390 x 844, and a short screen such as 390 x 600) and look at the margins before committing.
- Use the plain fonts (F_T, F_B) for anything that must read cleanly; the handwritten font (F_H) has uneven spacing, so keep it to short accents.

## Drawing
- Work of one kind stays of one kind: a redrawn animal, item or button must match the others in style (outline, shading with shade(), proportions).
- After touching any shared drawing code (drawAnimal, drawHead, drawEars, drawTail, items), render all twelve animals front and back and look at every one before committing, not just the one changed.
- index.html is full of one-line chains like `if (...) { } else if (...) { }`: never add a `//` comment in the middle of such a line; it silently comments out the rest.

## Versions (APP_VERSION in index.html)
- A new feature raises the middle number (1.8.0).
- The small fixes after it are bundled into one last-number step (1.8.1). Do not raise the number for every small request.
- Renaming things (items, labels) does not change the version at all.
- Item names live in two places, index.html (ITEMS) and supabase/setup.sql: change both, and give the owner the SQL to run.

## The database
- supabase/setup.sql is the one file for everything in Supabase (ranking, wardrobe, feedback). Add new parts to it; do not start new .sql files.
- It must stay safe to run again on the live database: create ... if not exists, create or replace, drop policy if exists, on conflict do update. Test it twice on an empty database and once on one that already has data.

## Other standing choices
- Computers (partners and opponents) never wear items; items apply only to the player.
- 명예의 전당 stays at night.
