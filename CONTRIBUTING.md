# Contributing
## Building Locally
GitHub Pages builds and publishes the site on every push to `master`. To preview changes first, install
[Ruby](https://www.ruby-lang.org/) with Bundler, then run one of the scripts in `scripts/` from anywhere.
Missing gems are installed automatically by the PowerShell script; on Linux or macOS run `bundle install` once first.

| Command | Result |
| --- | --- |
| `.\scripts\build.ps1` | One-off build into `_site` |
| `.\scripts\build.ps1 -Serve` | Preview at http://127.0.0.1:4000, rebuilt on every change |
| `sh scripts/build.sh` | One-off build into `_site` (Linux or macOS) |

## File Format
Content files are markdown with a YAML header at the top, between two `---` lines.
Everything below the header is plain markdown.
```
---
title: Example Title
---
Body text in markdown.
```

* Filenames: lowercase letters, digits and `-` only.
* `title:` values can be written any sane way.
* `name:` values follow the filename rule.
* Dates use the format `2026-01-31 17:00:00` and are NZ time.
* Posts and events dated in the future stay hidden until that time.

## Add a news post
* Create `_posts/YYYY-MM-DD-[slug].md`, where the date is the post date.
* The home page shows the latest five posts; `/news/` shows all of them.

example post: `_posts/2026-01-31-example-post.md`
```
---
title: Example Post
date: 2026-01-31 17:00:00
---
Post text here.
```

## Add an event
* Create `_events/[event].md`.
* Optional poster: add it to `images/events`, and a 100x100 copy with the same filename to `images/events/thumb`.
  Put the filename only (no path) in `image:`.
* Without a thumbnail the default one is used. The full poster shows on the event page only when both files exist.
* The home page shows the latest four events; `/news/` shows all of them.

example event: `_events/example-event.md`
```
---
title: Example Event
date: 2026-01-31 17:00:00
image: example-event.png
---
Event text here. It can be blank, a sentence, or a full essay.
```

## Resident DJ and Staff pages
These sections are currently switched off. To switch one back on:

* set `output: true` for its collection (`rdjs` or `staff`) in `_config.yml`
* set `published: true` in `rdj/index.html` or `staff/index.html`
* add its link back to `_includes/header.html`

### Add a RDJ bio
* Create `_rdjs/[artist].md`.
* Optional logo: `images/rdj/[artist].png`, preferably all-white. Without one the default is used.

example rdj: `_rdjs/example-artist.md`
```
---
title: Example Artist
name: example-artist
---
Bio text here.
```

### Add a staff bio
* Create `_staff/[staff].md`.
* Optional photo: `images/staff/[staff].jpg`. Without one the default is used.

example staff: `_staff/example-staff.md`
```
---
name: Example Staff
---
Bio text here.
```

## Tastybot
`_data/tastybot-commands.json` drives the `/tastybot` page. It is generated from the TastyBot command registry;
replace the whole file with a newly generated one rather than editing it by hand.
