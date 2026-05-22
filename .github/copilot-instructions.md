# Copilot Instructions

## Build, test, lint

- Install deps: `bundle install`
- Database setup: `bin/rails db:create db:migrate db:seed`
- Run app (dev): `bin/dev`
- Tests (all): `bin/rails test`
- Single test file: `bin/rails test test/models/user_test.rb`
- Lint: `bin/rubocop -f github`
- Security scans used in CI: `bin/brakeman --no-pager`, `bin/importmap audit`

## High-level architecture

- Rails 8 MVC app with ERB views, Tailwind via `tailwindcss-rails`, and Hotwire (Turbo/Stimulus) enabled by default.
- Authentication is handled by Devise (`User` model), with role-based access for `admin`, `manager`, and `staff`.
- Tickets are the core domain object; `TicketController` drives the list/create flow and paginates with Pagy (`ApplicationController` includes Pagy helpers).
- Admin dashboard is under the `admin` namespace and guarded by `require_admin_or_manager!`.

## Key conventions

- Tickets use a singular controller name (`TicketController`), while routes are defined with plural resources using `controller: "ticket"`.
- Role checks use `User#admin?`, `#manager?`, `#staff?`, and access control is centralized in `ApplicationController#require_admin_or_manager!`.
- Ticket filtering is implemented as model scopes (`search`, `by_status`, `by_priority`, `by_category`) and the allowed options live in `Ticket::STATUSES`, `PRIORITIES`, and `CATEGORIES`.
- Ticket associations use `submitter` (`submitter_id`) and `assignee` (`assigned_to_id`) naming; controllers set `submitter` from `current_user`.
