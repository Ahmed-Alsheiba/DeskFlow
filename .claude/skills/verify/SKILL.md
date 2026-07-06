---
name: verify
description: Build, run, and drive DeskFlow to verify changes end-to-end (Rails 8 + Tailwind v4 + Pagy 43).
---

# Verifying DeskFlow changes

## Launch

```bash
bin/rails server -p 3000        # plain CSS/Ruby changes; Propshaft serves app/assets as-is
bin/dev                         # use instead when Tailwind utility classes changed (runs tailwindcss:watch)
curl -s http://localhost:3000/up   # health check returns 200 when ready
```

## Authenticated pages without credentials

Devise guards most pages. Use the read-only preview account (POST /preview needs a CSRF token):

```bash
JAR=cookies.txt
TOKEN=$(curl -s -c $JAR http://localhost:3000/ | grep -o 'name="csrf-token" content="[^"]*"' | sed 's/.*content="//;s/"//')
curl -s -b $JAR -c $JAR --data-urlencode "authenticity_token=$TOKEN" http://localhost:3000/preview   # 302 → /tickets
curl -s -b $JAR http://localhost:3000/tickets    # signed in
```

The session cookie is `_desk_flow_session`. Preview mode blocks all writes — use a seeded real user if verifying mutations (see db/seeds.rb).

## Screenshots (visual changes)

No Playwright in the repo, but `npm i playwright-core` in a scratch dir + system Google Chrome works with no browser download:

```js
const browser = await chromium.launch({ channel: 'chrome', headless: true });
// inject the _desk_flow_session cookie value from the curl jar via ctx.addCookies
// (domain 'localhost', path '/', httpOnly true)
```

Screenshot targets: `nav.series-nav` for pagination, full page for layout.

## Gotchas

- Pagy is **v43** (`@pagy.series_nav`, `include Pagy::Method`) — pagy 4.x helpers/extras don't exist.
- `stylesheet_link_tag :app` globs every CSS file under app/assets (Propshaft), so both
  `app/assets/stylesheets/application.css` and the Tailwind build load; no manifest to edit.
- `app/assets/stylesheets/application.css` is NOT processed by Tailwind — plain CSS only, no `@apply`.
- Views live in `app/views/ticket/` (singular), routes are `resources :tickets` (plural).
