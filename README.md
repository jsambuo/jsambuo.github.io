# sambuo.com static migration

This repository now serves as a plain static HTML/CSS site (no Jekyll build required).

Canonical host is `https://www.sambuo.com`.

## Current architecture

- Static HTML pages at repository root and route folders.
- Static stylesheet at `/css/main.css`.
- Static RSS feed at `/feed.xml`.
- Legacy image asset preserved at `/assets/GCP_Functions_Tester.png`.
- GitHub Pages Jekyll processing is disabled via `/.nojekyll`.
- Legacy Jekyll source folders are kept only as content/input archives.

## Jekyll audit and route mapping

Previous Jekyll content sources:

- Posts: `/_posts/*.markdown`
- Layouts: `/_layouts/*.html`
- Includes: `/_includes/*.html`
- Styles: `/css/main.scss` + `/_sass/*.scss`
- Site config: `/_config.yml`

Legacy post source to static output mapping:

| Jekyll source | Static output routes |
| --- | --- |
| `/_posts/2018-02-09-financial-independence.markdown` | `/financial-independence.html`, `/financial-independence/` |
| `/_posts/2018-01-29-global-game-jam-2018.markdown` | `/global-game-jam-2018.html`, `/global-game-jam-2018/` |
| `/_posts/2018-01-15-my-experience-with-gcp.markdown` | `/my-experience-with-gcp.html`, `/my-experience-with-gcp/` |
| `/_posts/2018-01-12-bitcoin.markdown` | `/bitcoin.html`, `/bitcoin/` |
| `/_posts/2018-01-06-happy-2018.markdown` | `/happy-2018.html`, `/happy-2018/` |
| `/_posts/2015-07-12-hello-everybody.markdown` | `/hello-everybody.html`, `/hello-everybody/` |

Core pages:

- `/` -> `/index.html`
- `/about/` -> `/about/index.html`
- `/articles/` -> `/articles/index.html`
- `/feed.xml` -> `/feed.xml`

## Compatibility checklist (required routes)

Expected behavior when served by a basic static server:

| Route | Expected result |
| --- | --- |
| `/` | `200` |
| `/about/` | `200` |
| `/about` | `301`/`308` redirect to `/about/` (then `200`) |
| `/feed.xml` | `200` |
| `/financial-independence.html` | `200` |
| `/financial-independence` | `301`/`308` redirect to `/financial-independence/` (then `200`) |
| `/global-game-jam-2018.html` | `200` |
| `/global-game-jam-2018` | `301`/`308` redirect to `/global-game-jam-2018/` (then `200`) |
| `/my-experience-with-gcp.html` | `200` |
| `/my-experience-with-gcp` | `301`/`308` redirect to `/my-experience-with-gcp/` (then `200`) |
| `/bitcoin.html` | `200` |
| `/bitcoin` | `301`/`308` redirect to `/bitcoin/` (then `200`) |
| `/happy-2018.html` | `200` |
| `/happy-2018` | `301`/`308` redirect to `/happy-2018/` (then `200`) |
| `/hello-everybody.html` | `200` |
| `/hello-everybody` | `301`/`308` redirect to `/hello-everybody/` (then `200`) |
| `/css/main.css` | `200` |
| `/assets/GCP_Functions_Tester.png` | `200` |

## Local preview

Run a basic server:

```bash
python3 -m http.server 4173
```

Run compatibility checks:

```bash
./scripts/verify_compatibility.sh http://127.0.0.1:4173
```

Regenerate static legacy pages from `/_posts/*.markdown`:

```bash
./scripts/generate_static_posts.sh
```

## Publishing new content

Legacy routes are intentionally preserved and should not be replaced.

For new writing, publish under `/articles/`:

1. Add a new HTML file in `/articles/` (for example, `/articles/my-new-post.html`).
2. Add a link to it in `/articles/index.html`.
3. If desired, add it to `/feed.xml`.

## Notes

- The apex domain `https://sambuo.com` is currently out of scope for this migration.
- `CNAME` remains `www.sambuo.com`.
