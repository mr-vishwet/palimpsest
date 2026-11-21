# PALIMPSEST

**Your life, as an editable memory.** A local-first life archive: ask
a question about an old memory and watch it reconstruct the moment —
in order, with the reason each piece is there.

> **v0.1 — started, not finished.** The archive engine is real and
> tested (see [Verification](#verification)): the layer model, the
> on-device search index, the reconstruction flow, timeline ordering
> and deterministic export all run on real data. All 30 screens exist
> as functional routes with mobile and web layouts. What is simulated
> in v0.1 is listed honestly in [What v0.1 simulates](#what-v01-simulates).
> This is a build specification brought to code, not a shipped product.

## What it does

1. **Ask** — type a question in plain words ("Show me everything from
   the weekend when I first started working on that project"). The
   archive searches its on-device index and rebuilds the moment:
   photos, videos, voice notes and notes in chronological order, each
   with its reason. Items the archive is unsure about are flagged as
   looking wrong; removing one teaches the archive what you meant,
   and the correction is remembered.
2. **Curate** — four stories with chapters in the order you remember
   them (drag to reorder), a cutting-room media library with aspect
   ratios as data, a 35+ year timeline, people grouped on-device
   (names are yours to add), a schematic map of places, and voice
   notes whose transcripts make them searchable.
3. **Edit in layers** — nothing is ever overwritten. Every edit to a
   caption, tag or cover writes a new layer on top; the older layers
   stay visible beneath, and the top layer can be reverted to reveal
   what was there before. The palimpsest metaphor is the product.
4. **Stay local** — guest-first: the whole archive works without an
   account. Search, stories, edits and export never leave the device.
   An account unlocks three things only: share links, encrypted
   cloud backup (your key, your copy) and sync.

## The model

- **Memory** — one photo, video, voice note or written note, with a
  SHA-256 checksum, capture time, tags, people, place and aspect
  ratio. Provenance contract: every search result and export element
  links back to a source id + checksum.
- **Layer** — one edit to a memory: kind, previous value, new value,
  timestamp. The current value of a field is the newest layer of
  that kind; reverting peels the top layer off. Buried layers cannot
  be reverted (that would rewrite history).
- **Story / Chapter** — a story is a curated collection; chapters
  carry their own play times and the story total is the sum of its
  chapters. Wedding Cruise: 42 + 78 + 124 + 36 + 12 = 292s (4:52).
- **Reconstructed moment** — the answer to one question: ordered
  item ids, a reason per item, flagged ids, removed ids, rebuild
  time. Saving a moment as a story creates a real story from it.
- **Deterministic export** — re-exporting a story or moment produces
  identical bytes: items sorted by id, layers by time, keys in fixed
  order. The manifest is the provenance record.

## Screens

30 routes, each with a mobile layout (below 900px) and a wide/web
layout (at or above 900px) — the 60 designed screens (m01–m30 +
w01–w30):

| # | Route | Screen |
|---|---|---|
| 01 | `/` | Home — ask, rebuilt moment, stories |
| 02 | `/story` | Story detail — chapters, play, share |
| 03 | `/ask` | Ask the archive |
| 04 | `/ask/reconstructing` | Reconstructing — the orb and the ring |
| 05 | `/moment` | Reconstructed moment — reasons, flags |
| 06 | `/library` | Media library — cutting-room grid |
| 07 | `/media` | Media detail — Frame 042, layers |
| 08 | `/compose` | Story compose — drag chapters to reorder |
| 09 | `/chapter-edit` | Chapter edit — title, caption, cover |
| 10 | `/timeline` | Timeline — 35+ years, the photo box |
| 11 | `/people` | People — on-device face groups |
| 12 | `/places` | Places — schematic map |
| 13 | `/voice` | Voice note — waveform, transcript |
| 14 | `/import` | Import — honest indexing progress |
| 15 | `/offline` | Offline — a state, not a failure |
| 16 | `/share` | Share story — view-only link |
| 17 | `/settings` | Settings — archive rules, data controls |
| 18 | `/resurface` | Resurface — three years ago this week |
| 19 | `/first-launch` | First launch — import, scan, or ask |
| 20 | `/payoff` | The payoff — every moment, one question away |
| 21 | `/welcome` | Welcome — guest-first |
| 22 | `/guest-mode` | Guest mode — what works, what needs an account |
| 23 | `/sign-in` | Sign in |
| 24 | `/create-account` | Create account |
| 25 | `/verify` | Verify — 6-digit code |
| 26 | `/upgrade` | Upgrade prompt — share needs an account |
| 27 | `/migrate` | Migrate — 0 left behind |
| 28 | `/account` | Account home — backup, sync, links |
| 29 | `/connected` | Connected accounts — pull in, never push out |
| 30 | `/sign-out` | Sign out — local stays, cloud goes |

## Setup

Prerequisites: Flutter >= 3.27, Dart SDK >= 3.6.

```sh
flutter pub get
flutter run            # iOS / Android / macOS / Windows / Linux
flutter run -d chrome  # web
flutter test           # unit tests (engine + models + seed)
flutter analyze        # lints (flutter_lints + docs rules)
```

No backend, no API keys, no accounts to configure. First launch
seeds the demo library (below) and shows the first-launch flow.

## Architecture

```
lib/
  main.dart            # loads the store, seeds on first run, runs the app
  app.dart             # MaterialApp + the 30-route table
  core/                # theme (single V7 palette), constants, format, routes
  models/              # memory_item, layer, story, person, place,
                       # voice_note, share_link, account, ask_result,
                       # archive_data (the whole archive as one document)
  engine/              # archive_index (search), reconstructor,
                       # timeline, exporter (deterministic manifests)
  services/            # archive_store (SharedPreferences JSON),
                       # demo_seed (the curated demo library)
  state/               # archive_controller, ask_controller,
                       # auth_controller (ChangeNotifier)
  screens/             # 30 screens, mobile + wide layout each
  widgets/             # app shell, orb, ask field, story card,
                       # frame tile, waveform, layer history, map
test/                  # layer model, timeline, search, reconstruction,
                       # export determinism, demo-seed integrity
assets/logos/          # the four logo versions (SVG, via flutter_svg)
web/                   # index.html, manifest.json
```

State is simple `ChangeNotifier` controllers; persistence is one
versioned JSON document (`ArchiveStore`, key
`palimpsest_archive_v1`). The store interface is deliberately narrow
(`load` / `save` / `clear`) so a Drift/SQLite store can replace it
behind the same interface in phase 2.

## The demo library

v0.1 ships with a seeded demo library, labelled as such in the UI
(Home badge, Settings disclosure): four stories (Wedding Cruise,
Motorcycle Adventure, Family Vacation, Childhood), the
project-weekend items behind the hero question, five named people
(Dad, Mum, Ana, Ravi, Sara) plus one unnamed group, four places,
nine voice notes, and the layer history on Frame 042. Headline
totals (5,012 photos, 143 videos, 18.4 GB) are the demo archive's
numbers; the browsable item list is the curated 38-item seed subset.
Settings offers a "Reset demo library" action that restores the
seed. Real imports replace the seed over time.

## What v0.1 simulates

No backend exists yet, so these flows are simulated on-device and
the UI says so where it matters:

- **Account / verification** — sign-in and account creation are
  recorded locally; any 6-digit code verifies (the demo code from
  the spec is `428195`). Passwords are never sent anywhere.
- **Backup / sync / migration** — progress advances locally; sync
  lists the devices the archive knows about.
- **Share links** — links are created and recorded locally with the
  production URL shape (`https://palimpsest.app/s/<code>`);
  no hosted service resolves them yet.
- **Social sign-in** — the buttons explain that social sign-in
  arrives with the account backend.
- **Connected accounts** — connections are recorded locally; real
  OAuth and import arrive in phase 2.
- **Import** — the queue advances over simulated batches; real
  photo-library access arrives in phase 2.
- **Thumbnails / audio** — frames render as deterministic gradients
  and voice playback is a timed playhead over the waveform; real
  media bytes arrive in phase 2.

## Verification

```sh
flutter test
```

- `layer_model_test.dart` — current value, newest-wins, revert
  semantics (buried layers cannot be reverted).
- `timeline_test.dart` — years newest first, stories placed by
  start year, ordering reverses.
- `search_test.dart` — tokenization/stopwords, tag vs title
  scoring, person/place matching, filters, determinism.
- `reconstruction_test.dart` — the canonical question (14 items,
  2 flagged, sketch/voice/cut anchors), corrections, empty results.
- `export_test.dart` — re-export is byte-identical; input order
  does not change the manifest.
- `demo_seed_test.dart` — canon numbers (4:52 cruise, 14:32 moto,
  1,852 photos with people, 9 voice notes, 842/1,204 indexed) and
  a full JSON round-trip of the archive document.

## Roadmap (phase 2)

- Dual dark/light themes (the palette is isolated in
  `lib/core/theme.dart` as `Palette`; phase 2 adds a light palette
  and a `ThemeMode` toggle — no screen changes needed).
- Drift/SQLite store behind the `ArchiveStore` interface, with a
  real migration path for the v1 JSON document.
- Real photo-library import, thumbnails, and audio playback.
- Account backend: real verification, backup, sync, hosted share
  links, social sign-in, connected-account OAuth.
- AI as an adapter (per the catalog): opt-in embeddings and local
  transcription behind interfaces — the app stays useful with zero AI.
- Camera scanning for the photo box.

## Appendix: CI workflow (add via web UI)

The GitHub App cannot push `.github/workflows/` (403), so no
workflow file is in this repo. To add CI, create
`.github/workflows/flutter.yml` in the GitHub web UI with:

```yaml
name: Flutter

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build web --release
```
