---
name: reddit-fetch
description: "Fetching data from Reddit — reading a reddit.com URL or thread, or pulling posts, comments, or subreddit listings — when direct access fails (403, 429, anti-bot page, empty body). Verified no-auth routes: RSS, PullPush, Arctic Shift, Wayback Machine. Use whenever a Reddit link must be read or Reddit data is requested."
---

# Fetching data from Reddit

All routes verified 2026-09-19 from this machine with plain `curl`. Reddit's front door is closed to agents: it TLS-fingerprints clients, so a browser User-Agent gains nothing, and since the 2026-05-28 deprecation the unauthenticated `.json` endpoints return 403. Skip the blocked list below and start with route 1.

## Blocked (measured 2026-09-19)

| Route | Result |
|---|---|
| `webfetch` tool on any `reddit.com` host | anti-bot page or empty body |
| `www.reddit.com/<path>.json`, `api.reddit.com` | 403 |
| `old.reddit.com` | 302 to a login wall |
| Any endpoint sent a browser/generic UA | 429 — the UA string itself is the filter key |
| Public redlib/libreddit mirrors | dead DNS, Anubis proof-of-work, or proxying the same 403 |

## User-Agent rule

Send a unique, descriptive UA — never a browser string, never curl's default:

```bash
-A "research-script/0.1 (local testing)"
```

## Route 1 — RSS (live thread, one request)

```bash
curl -A "research-script/0.1 (local testing)" \
  "https://www.reddit.com/r/SUB/comments/ID/SLUG/.rss" -o thread.rss
```

Returns the whole thread as feed entries (post + comments, HTML bodies). The allowance is roughly one request per 30 s window — after one hit `x-ratelimit-remaining` drops to 0.0; wait `x-ratelimit-reset` seconds before retrying. Subreddit and listing feeds work the same way: `/r/SUB/new/.rss`.

## Route 2 — PullPush (JSON, no auth)

```bash
curl "https://api.pullpush.io/reddit/search/submission/?ids=ID"
curl "https://api.pullpush.io/reddit/search/comment/?link_id=ID&size=100"
```

`link_id` takes the bare post id (no `t3_` prefix). Also supports `subreddit=`, `author=`, `q=`, `after=`/`before=` (epoch seconds). Ingestion lags live Reddit by hours to days.

## Route 3 — Arctic Shift (JSON, no auth, historical)

```bash
curl "https://arctic-shift.photon-reddit.com/api/posts/ids?ids=t3_ID"
```

The parameter is `ids=` and the id keeps its `t3_` prefix (passing the prefixed id as the query key itself returns 400). Comments have their own endpoint under `/api/comments/`.

## Route 4 — Wayback Machine (deleted, edited, or fully blocked content)

1. List captures via the CDX API — the `webfetch` tool fails on it with transport errors, use `curl`:

   ```bash
   curl --http1.1 "https://web.archive.org/cdx/search/cdx?url=reddit.com/r/SUB/comments/ID*&limit=50"
   ```

2. Prefer captures whose URL carries `js_challenge=1&solution=…` — the archiver passed Reddit's JS challenge, so the saved HTML is the rendered thread (~100 KB+), not the 3.5 KB challenge shell.
3. Fetch the raw capture with the `id_` suffix and `--compressed` (without it the gzip bytes land on disk undecoded):

   ```bash
   curl --compressed -o thread.html \
     "https://web.archive.org/web/TIMESTAMPid_/https://www.reddit.com/r/SUB/comments/ID/SLUG/"
   ```

4. Parse locally: post text sits in the `shreddit-post-text-body` element; split comments on `<shreddit-comment ` (attributes `author=`, `score=`, `depth=`; paragraphs in `<p>` inside the `*-post-rtjson-content` div).

## Route 5 — Official OAuth (high volume, needs a Reddit account)

Register a script app at `reddit.com/prefs/apps` and use its client credentials against `oauth.reddit.com`. The only route with a real rate allowance; required for anything that loops.

## Completion bar

One route returning the requested data ends the fetch. Every route attempted is named in the reply with its HTTP status; when all fail, list them — never report Reddit content as absent on the strength of a blocked fetch.
