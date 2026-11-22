# PALIMPSEST — Demo Media Manifest

Real photos and videos shipped with the app so the import/index pipeline demos on genuine files. Collected 2026-11-22. **Total: 30 files, 20,760,492 bytes (~19.8 MiB)** — under the ~50 MB budget.

License for every file below: **Pexels free license** (free to use, no attribution required). Source URLs are the exact files downloaded.

## Photos (26 JPEGs, 7,127,097 bytes)

All verified with PIL (`Image.verify()` + format/dimensions). Every photo is under 500 KB; max long edge 1600 px except the two recompressed files noted below.

| # | File | Pexels photo ID | Dimensions | Size (bytes) | Notes |
|---|------|-----------------|------------|--------------|-------|
| 1 | palimpsest-01-kovalam-sunset.jpg | 34014757 | 1600x2133 | 416,524 | |
| 2 | palimpsest-02-phuket-sunset.jpg | 3718633 | 1600x1200 | 270,091 | |
| 3 | palimpsest-03-bali-palm-dawn.jpg | 6685756 | 1600x1067 | 284,436 | |
| 4 | palimpsest-04-hikkaduwa-beach-people.jpg | 12728482 | 1600x1067 | 201,940 | |
| 5 | palimpsest-05-father-son-cooking.jpg | 4261783 | 1600x2397 | 415,649 | |
| 6 | palimpsest-06-family-kitchen.jpg | 4262002 | 1600x1110 | 262,155 | |
| 7 | palimpsest-07-family-breakfast.jpg | 5442687 | 1600x2400 | 343,298 | |
| 8 | palimpsest-08-family-turkey-dinner.jpg | 5876477 | 1600x1067 | 234,851 | |
| 9 | palimpsest-09-family-dinner-table.jpg | 20488720 | 1600x2400 | 316,842 | |
| 10 | palimpsest-10-nyc-street.jpg | 12206307 | 1600x1067 | 147,666 | |
| 11 | palimpsest-11-city-rain-umbrellas.jpg | 8568757 | 1600x1067 | 291,898 | |
| 12 | palimpsest-12-rome-street.jpg | 8307575 | 800x1200 | 220,732 | Recompressed: original download was 976 KB; resized to 1200 px long edge, JPEG q82 |
| 13 | palimpsest-13-city-night-street.jpg | 13662658 | 1024x1280 | 246,243 | Recompressed: original download was 592 KB; resized to 1280 px long edge, JPEG q82 |
| 14 | palimpsest-14-city-crowd.jpg | 9941794 | 1600x1060 | 229,458 | |
| 15 | palimpsest-15-basque-shepherd.jpg | 9287556 | 1600x2133 | 339,680 | |
| 16 | palimpsest-16-dog-snow-mountains.jpg | 5593744 | 1600x1154 | 187,193 | |
| 17 | palimpsest-17-dog-hiking-snowdonia.jpg | 16637564 | 1600x1200 | 351,276 | |
| 18 | palimpsest-18-dog-dolomites.jpg | 17821414 | 1600x1067 | 201,419 | |
| 19 | palimpsest-19-boxer-dog-portrait.jpg | 7149700 | 1600x1067 | 181,347 | |
| 20 | palimpsest-20-birthday-candles.jpg | 7337029 | 1600x2400 | 337,986 | |
| 21 | palimpsest-21-birthday-restaurant.jpg | 9543840 | 1600x1067 | 247,623 | |
| 22 | palimpsest-22-birthday-party-hats.jpg | 30682893 | 1600x1067 | 195,927 | |
| 23 | palimpsest-23-outdoor-birthday.jpg | 36713424 | 1600x900 | 257,218 | |
| 24 | palimpsest-24-reading-coffee-flowers.jpg | 29035721 | 1600x2133 | 306,139 | |
| 25 | palimpsest-25-cafe-book-patio.jpg | 20885639 | 1600x2341 | 477,277 | |
| 26 | palimpsest-26-coffee-on-book.jpg | 15002639 | 1600x1067 | 162,229 | |

Photo download URL pattern (verified working): `https://images.pexels.com/photos/{id}/pexels-photo-{id}.jpeg?auto=compress&cs=tinysrgb&w=1600`

## Videos (4 MP4s, 13,633,395 bytes)

All verified with ffprobe (codec, resolution, frame rate, duration, audio streams). Every video is under 5 MB.

| File | Source | Duration | Resolution / fps | Audio | Size (bytes) | Processing |
|------|--------|----------|------------------|-------|--------------|------------|
| palimpsest-video-01-ocean-waves.mp4 | Pexels video 5968005 — `https://videos.pexels.com/video-files/5968005/5968005-hd_1280_720_30fps.mp4` | 12.4 s | 1280x720 / 29.97 | AAC | 4,346,336 | As downloaded |
| palimpsest-video-02-london-night-street.mp4 | Pexels video 5962271 — `https://videos.pexels.com/video-files/5962271/5962271-hd_1920_1080_30fps.mp4` | 15.0 s | 1280x720 / 29.97 | AAC | 2,859,423 | Trimmed to first 15 s, re-encoded libx264 CRF 28, maxrate 1500k (source file was 9.5 MB). Note: the Pexels file named 1080p is actually 720p |
| palimpsest-video-03-london-streets.mp4 | Pexels video 5402285 — `https://videos.pexels.com/video-files/5402285/5402285-hd_1920_1080_30fps.mp4` | 15.0 s | 1280x720 / 29.97 | AAC | 2,530,915 | Trimmed to first 15 s, scaled to 720p, re-encoded libx264 CRF 28, maxrate 1500k (source was 13.3 MB) |
| palimpsest-video-04-aerial-shore.mp4 | Pexels video 9094060 — `https://videos.pexels.com/video-files/9094060/9094060-hd_1920_1080_30fps.mp4` | 20.0 s | 1280x720 / 30 | None (source has no audio track) | 3,896,721 | Trimmed to first 20 s, scaled to 720p, re-encoded libx264 CRF 28, maxrate 1500k (source was 25.3 MB) |

## Audio

Skipped. Two suitable CC BY 3.0 voice recordings were identified on Wikimedia Commons (Tariana Turia voice introduction, English + Māori, by Superu NZ), but upload.wikimedia.org returned HTTP 429 (rate limit) on both download attempts, including after a 20 s wait with a descriptive User-Agent. Audio was optional in the brief; no audio files are included.

## Sources rejected

- Pexels video 28941612 (Bondi Beach): file URLs returned 404 for every fps variant tried (30/25/24) — skipped.
- Pexels video 34290117 (busy night city street, 4K 60 fps): file URLs returned 404 for every variant tried — skipped.
- Wikimedia Commons: most voice/audio search results were CC BY-SA (not allowed under this brief — only CC0 / public domain / CC-BY) — not used.
