# Changelog

## v8 · Foaling season & real logo
- Uses the original Marebook logo artwork in the header, footer, hero and log-in box.
- Foaling-season planner, per Charles & Kelly:
  - Target foaling window is January–April, with April as the ideal month. May–June counts as late.
  - The goal is earlier in the year, because every foal turns one on January 1.
  - The planner shows a crop timeline with every mare's due date and works the breeding dates back 340 days.
  - It shows the days left in the window and each open mare's projected foaling date if bred now.
  - It can add lights-program reminders for December 1.
- Mare cards and profiles show which part of the season the foal lands in. Foal pages show "calendar age", meaning how many months old the foal is when it's a two-year-old on paper.
- Season settings under Account let them change the window, the ideal month and the late cutoff.
- Removed the decorative orb behind the hero text.

## v7 · Brand, public site, spec pass (Oct 2026)
Built against Charles & Kelly's wireframes, page summaries, the App Build Workbook and the Platform & Ownership Checklist.

**Brand**
- New identity from the Marebook logo: night black, teal ring, silver lettering, blue orb, antique-gold accents.
- Cormorant Garamond display type, Manrope body, Pinyon Script in the logo. Light and dark themes.
- Header and footer on every page. Footer carries Hixson Group Enterprises LLC, d/b/a Marebook · Weatherford, Texas.

**Public site** (wireframe nav: mare owner · stallion owner · contact us · about us · log in / new member · herd management)
- Home page with hero, sponsored banner-ad slot, audience cards, reminder timeline, featured stallions, pricing.
- Mare owners, Stallion owners, About us and Contact us pages.
- Log-in popup with remember me and forgot password (email link or texted PIN), plus a "Not a member?" join path.
- Join page for mare owners (with membership tier) and stallion owners (ranch name, address, contact name, position, email, phone, password).
- Passwords are never stored in the preview.

**Member home** (wireframe: My Mares · Add New Mare · Foal · Stallion Search · Calendar · Daily To-Do)
- Type-ahead menus for My Mares, Foals, My Stallions and Stallion Search. Each has an Add New button.
- Stallion Search on the home page filters by breed and discipline, with results grouped by breed.
- Month calendar card, daily to-do grouped by mares, foals and stallions, today's alerts, and a featured-stallion sponsored slot.

**Profiles**
- Foal page in the wireframe layout: Date · Action column, photos plus videos, and the foal's own calendar.
- Video clips on mare, foal and stallion pages.
- Stallion page:
  - Breed shown with abbreviation (AQHA, APHA, TB…) and a discipline field.
  - Contact preference and a "Contact stallion owner" button.
  - Booking card for mare owners and a payment-portal card for owners (Stripe at launch).
- Stallion Search: breed, discipline and semen-type filters, results grouped by breed, featured listings first.

**Admin**
- Members & inquiries: every sign-up and Contact us message, CSV export and copy-all-emails.

**Preview (Netlify)**
- Opens on the public home page.
- Photos and videos are stored on the device (IndexedDB).
- Print buttons open the browser's print dialog.

## v6 · Integrations
Google/Apple Calendar (.ics), QuickBooks CSV, farm tax summary, AI receipt scanning (Claude version), voice exam entry, breeding contracts, SMS settings, team roles, offline saving.
