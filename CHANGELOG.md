# Changelog

## v10 · Pre-foaling vaccines, exam read-back, management cards, collection & shipping rules
- **Pre-foaling vaccines:** scheduled 30 days before each mare's due date (EWT, WNV, rabies, flu/rhino). The due date shows a "Pre-foaling vaccines" chip on her profile. Existing reminders are retitled and re-dated automatically.
- **Read the last exam back:** every exam form shows her last exam (left, right, tone, ovulation, result, notes) with follicle growth since the one before, plus earlier exams. "Read it back" speaks it aloud. While dictating, say "last exam" to hear it hands-free.
- **Mare management cards:** upload a photo, PDF or CSV of a paper breeding or vet card from her profile, or several at once with "Import mare cards" on the roster.
  - AI reads the dated entries into a review sheet: exams with ovary findings, breedings, vaccines, deworming, foaling and treatments.
  - Check each row, then import. Rows already logged that day start unchecked.
  - Imported ovulations train her heat prediction. A recent bred cycle can start her pregnancy checks.
  - Blank mare details (breed, color, registry, reg #, year foaled) fill in from the card. Cards stay on her profile.
  - Without AI, you type entries in beside the card photo. A CSV template is included.
  - AI on Netlify needs `ANTHROPIC_API_KEY` set (see `netlify/functions/read-card.mjs`).
- **Collection schedules:** stallions can collect on weekdays, odd dates, even dates, or both (for example odd dates except Sundays).
- **Cooled-semen shipping:** collections that can't ship and arrive are skipped when timing a mare's ultrasound and order. That covers Sunday deliveries, carrier holidays (New Year's, Memorial Day, July 4, Labor Day, Thanksgiving, Christmas, with observed days), Saturday when the station doesn't ship for it, and the station's own not-shipping dates.
  - The stallion calendar flags blocked dates and lists holidays ahead.
  - The order form warns when the needed date can't arrive and suggests the next one that can.

## v9 · Real accounts, phone app, heat prediction
- **Real accounts, ready to switch on:** Supabase backend (`supabase/schema.sql`).
  - Email log-in, sign-up with email confirmation, and password reset by email.
  - Shared barns with live sync across phones and team join codes.
  - Roles enforced by the database; Viewer is read-only.
  - Photo and video storage, and Stallion Search across all barns.
  - Changes save instantly on the phone, sync in batches, and wait in an outbox when offline.
- **Phone app:** installs to the home screen (manifest, icons, service worker). The app works with no signal. It shows an install prompt on Android and step-by-step instructions on iPhone.
- **Heat prediction:**
  - Predicts each open mare's next heat and ovulation from her last ovulation, learning her own cycle length. Teasing ("In heat today") updates the prediction.
  - A 35 mm or larger follicle on a recent exam flags "ovulation likely within 24–48 hrs".
  - Heat checks and follicle ultrasounds land on the calendar automatically.
  - The stallion order is lined up with his collection days so semen arrives the day before ovulation.
  - Pregnancy checks record Pregnant, Open or Twins. Open clears her pregnancy schedule and puts her back on heat watch. An ovulation logged without breeding just tracks the cycle.
  - Heat watch card on the member home.

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
