#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

format_display_date() {
  local raw="$1"
  date -j -f "%Y-%m-%d %H:%M:%S" "$raw" "+%b %-d, %Y"
}

format_rfc822_date() {
  local raw="$1"
  date -j -u -f "%Y-%m-%d %H:%M:%S" "$raw" "+%a, %d %b %Y %H:%M:%S +0000"
}

# Build newest first
for post_file in $(ls -1 "$ROOT_DIR"/_posts/*.markdown | sort -r); do
  title="$(sed -n 's/^title:[[:space:]]*"\(.*\)"/\1/p' "$post_file")"
  raw_date="$(sed -n 's/^date:[[:space:]]*\(.*\)$/\1/p' "$post_file")"

  base_name="$(basename "$post_file" .markdown)"
  slug="${base_name#????-??-??-}"

  display_date="$(format_display_date "$raw_date")"
  rfc822_date="$(format_rfc822_date "$raw_date")"

  body_md="$TMP_DIR/${slug}.md"
  body_html="$TMP_DIR/${slug}.html"

  awk '
    BEGIN { delim=0 }
    /^---[[:space:]]*$/ {
      delim++
      next
    }
    delim >= 2 { print }
  ' "$post_file" > "$body_md"

  # Replace leftover Jekyll liquid URL helper with static URL.
  sed -i '' 's#{{ "/assets/GCP_Functions_Tester.png" | absolute_url }}#/assets/GCP_Functions_Tester.png#g' "$body_md"

  pandoc --from markdown --to html5 "$body_md" -o "$body_html"

  out_html="$ROOT_DIR/${slug}.html"
  out_dir="$ROOT_DIR/${slug}"
  mkdir -p "$out_dir"

  {
    cat <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>${title} | Random Thoughts of Jimmy</title>
  <meta name="description" content="Random Thoughts of Jimmy by Jimmy Sambuo.">
  <link rel="stylesheet" href="/css/main.css">
  <link rel="canonical" href="https://www.sambuo.com/${slug}.html">
  <link rel="alternate" type="application/rss+xml" title="Random Thoughts of Jimmy" href="https://www.sambuo.com/feed.xml">
</head>
<body>
  <header class="site-header">
    <div class="wrapper">
      <a class="site-title" href="/">Random Thoughts of Jimmy</a>
      <nav class="site-nav">
        <a class="page-link" href="/about/">About</a>
        <a class="page-link" href="/articles/">Articles</a>
      </nav>
    </div>
  </header>

  <main class="page-content">
    <div class="wrapper">
      <article class="post">
        <header class="post-header">
          <h1 class="post-title">${title}</h1>
          <p class="post-meta">${display_date}</p>
        </header>

        <div class="post-content">
EOF
    cat "$body_html"
    cat <<EOF
        </div>
      </article>

      <p class="post-nav-link"><a href="/">Back to all posts</a></p>
    </div>
  </main>

  <footer class="site-footer">
    <div class="wrapper">
      <p>Jimmy Sambuo · <a href="mailto:jimmy@sambuo.com">jimmy@sambuo.com</a></p>
      <p>
        <a href="https://github.com/jsambuo">GitHub</a> ·
        <a href="https://www.linkedin.com/in/jsambuo">LinkedIn</a> ·
        <a href="https://twitter.com/jsambuo">Twitter</a>
      </p>
    </div>
  </footer>
</body>
</html>
EOF
  } > "$out_html"

  cp "$out_html" "$out_dir/index.html"

  # Save metadata for feed/index generation.
  printf '%s\t%s\t%s\t%s\n' "$slug" "$title" "$display_date" "$rfc822_date" >> "$TMP_DIR/post_meta.tsv"
done

# Create homepage from metadata list.
{
  cat <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>Random Thoughts of Jimmy</title>
  <meta name="description" content="This is Jimmy Sambuo's website with essays on software, projects, and life.">
  <link rel="stylesheet" href="/css/main.css">
  <link rel="canonical" href="https://www.sambuo.com/">
  <link rel="alternate" type="application/rss+xml" title="Random Thoughts of Jimmy" href="https://www.sambuo.com/feed.xml">
</head>
<body>
  <header class="site-header">
    <div class="wrapper">
      <a class="site-title" href="/">Random Thoughts of Jimmy</a>
      <nav class="site-nav">
        <a class="page-link" href="/about/">About</a>
        <a class="page-link" href="/articles/">Articles</a>
      </nav>
    </div>
  </header>

  <main class="page-content">
    <div class="wrapper home">
      <h1 class="page-heading">Posts</h1>
      <ul class="post-list">
EOF

  while IFS=$'\t' read -r slug title display_date _rfc; do
    cat <<EOF
        <li>
          <span class="post-meta">${display_date}</span>
          <h2><a class="post-link" href="/${slug}.html">${title}</a></h2>
        </li>
EOF
  done < "$TMP_DIR/post_meta.tsv"

  cat <<'EOF'
      </ul>

      <p class="rss-subscribe">Subscribe <a href="/feed.xml">via RSS</a></p>
      <p class="rss-subscribe">New writing lives at <a href="/articles/">/articles/</a>.</p>
    </div>
  </main>

  <footer class="site-footer">
    <div class="wrapper">
      <p>Jimmy Sambuo · <a href="mailto:jimmy@sambuo.com">jimmy@sambuo.com</a></p>
      <p>
        <a href="https://github.com/jsambuo">GitHub</a> ·
        <a href="https://www.linkedin.com/in/jsambuo">LinkedIn</a> ·
        <a href="https://twitter.com/jsambuo">Twitter</a>
      </p>
    </div>
  </footer>
</body>
</html>
EOF
} > "$ROOT_DIR/index.html"

# About page directory route.
mkdir -p "$ROOT_DIR/about"
cat > "$ROOT_DIR/about/index.html" <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>About | Random Thoughts of Jimmy</title>
  <meta name="description" content="About Jimmy Sambuo.">
  <link rel="stylesheet" href="/css/main.css">
  <link rel="canonical" href="https://www.sambuo.com/about/">
  <link rel="alternate" type="application/rss+xml" title="Random Thoughts of Jimmy" href="https://www.sambuo.com/feed.xml">
</head>
<body>
  <header class="site-header">
    <div class="wrapper">
      <a class="site-title" href="/">Random Thoughts of Jimmy</a>
      <nav class="site-nav">
        <a class="page-link" href="/about/">About</a>
        <a class="page-link" href="/articles/">Articles</a>
      </nav>
    </div>
  </header>

  <main class="page-content">
    <div class="wrapper post">
      <header class="post-header">
        <h1 class="post-title">About</h1>
      </header>
      <div class="post-content">
        <p>I'm a software engineer. I enjoy building web apps, mobile apps, and games.</p>
        <p>I'm currently revamping this site while keeping legacy links working.</p>
      </div>
    </div>
  </main>

  <footer class="site-footer">
    <div class="wrapper">
      <p>Jimmy Sambuo · <a href="mailto:jimmy@sambuo.com">jimmy@sambuo.com</a></p>
      <p>
        <a href="https://github.com/jsambuo">GitHub</a> ·
        <a href="https://www.linkedin.com/in/jsambuo">LinkedIn</a> ·
        <a href="https://twitter.com/jsambuo">Twitter</a>
      </p>
    </div>
  </footer>
</body>
</html>
EOF

# New writing path.
mkdir -p "$ROOT_DIR/articles"
cat > "$ROOT_DIR/articles/index.html" <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>Articles | Random Thoughts of Jimmy</title>
  <meta name="description" content="New long-form writing by Jimmy Sambuo.">
  <link rel="stylesheet" href="/css/main.css">
  <link rel="canonical" href="https://www.sambuo.com/articles/">
  <link rel="alternate" type="application/rss+xml" title="Random Thoughts of Jimmy" href="https://www.sambuo.com/feed.xml">
</head>
<body>
  <header class="site-header">
    <div class="wrapper">
      <a class="site-title" href="/">Random Thoughts of Jimmy</a>
      <nav class="site-nav">
        <a class="page-link" href="/about/">About</a>
        <a class="page-link" href="/articles/">Articles</a>
      </nav>
    </div>
  </header>

  <main class="page-content">
    <div class="wrapper post">
      <header class="post-header">
        <h1 class="post-title">Articles</h1>
      </header>
      <div class="post-content">
        <p>This is the new path for future writing.</p>
        <p>Legacy posts remain available at their historical URLs.</p>
        <p>To publish a new article today, add an HTML file in <code>/articles/</code> and link it from this page.</p>
      </div>
    </div>
  </main>

  <footer class="site-footer">
    <div class="wrapper">
      <p>Jimmy Sambuo · <a href="mailto:jimmy@sambuo.com">jimmy@sambuo.com</a></p>
      <p>
        <a href="https://github.com/jsambuo">GitHub</a> ·
        <a href="https://www.linkedin.com/in/jsambuo">LinkedIn</a> ·
        <a href="https://twitter.com/jsambuo">Twitter</a>
      </p>
    </div>
  </footer>
</body>
</html>
EOF

# Static RSS feed based on existing legacy posts.
{
  cat <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Random Thoughts of Jimmy</title>
    <description>This is Jimmy Sambuo's website with essays on software, projects, and life.</description>
    <link>https://www.sambuo.com/</link>
    <atom:link href="https://www.sambuo.com/feed.xml" rel="self" type="application/rss+xml" />
    <generator>Static HTML</generator>
EOF

  while IFS=$'\t' read -r slug title _display_date rfc822_date; do
    cat <<EOF
    <item>
      <title>${title}</title>
      <link>https://www.sambuo.com/${slug}.html</link>
      <guid isPermaLink="true">https://www.sambuo.com/${slug}.html</guid>
      <pubDate>${rfc822_date}</pubDate>
      <description>Legacy post: ${title}</description>
    </item>
EOF
  done < "$TMP_DIR/post_meta.tsv"

  cat <<'EOF'
  </channel>
</rss>
EOF
} > "$ROOT_DIR/feed.xml"
