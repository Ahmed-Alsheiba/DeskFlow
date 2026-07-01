# DeskFlow

DeskFlow is a Rails-based ticketing system for hotel and operations teams. It helps staff report issues, track tickets, and gives admins and managers a central place to review users and requests.

## Features

- User authentication with Devise
- Role-based access for `admin`, `manager`, and `staff`
- Public landing page
- Ticket creation and ticket listing
- Ticket filtering by search, status, priority, and category
- Admin dashboard for viewing all users and all tickets
- Preloaded sample users for local development
- Tailwind-powered UI

## Who can do what

| Role | Access |
| --- | --- |
| Staff | Sign in, create tickets, and view ticket listings |
| Manager | Everything staff can do, plus access to the admin dashboard |
| Admin | Everything manager can do, plus access to the admin dashboard |

## Tech stack

- Ruby 3.4.6
- Rails 8.0.4
- PostgreSQL
- Devise for authentication
- Pagy for pagination
- Tailwind CSS

## Key screens

- **Landing page**: public marketing and overview page
- **Tickets page**: list and filter tickets
- **New ticket page**: submit a new helpdesk issue
- **Admin dashboard**: view all users and tickets in one place

## Data model overview

- **Users**: first name, last name, email, role, job title, and sector
- **Tickets**: title, description, status, category, priority, location, submitter, and assignee
- **Comments**: ticket discussion and history

## Getting started

### Prerequisites

- Ruby 3.4.6
- Bundler
- PostgreSQL

### Setup

```bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### Run the app

```bash
bin/dev
```

Then open the app in your browser.

## Seeded accounts

The seed file creates sample users for testing different roles. All seeded users use:

- **Password**: `password`

The seed data includes at least:

- one admin user
- multiple manager users
- many staff users

## Ticket capabilities

The ticket system currently supports:

- creating new tickets
- viewing the ticket list
- searching tickets by text
- filtering by status, priority, and category
- assigning tickets to users
- tracking ticket submitter and assignee

## Admin dashboard capabilities

The admin dashboard currently provides:

- a complete list of users
- a complete list of tickets
- role-aware access control
- quick operational visibility for admins and managers

## Development notes

- The app uses Tailwind CSS for styling.
- Authentication is handled with Devise.
- Dashboard access is restricted to admins and managers.

## Testing

```bash
bin/rails test
```

## License

This project does not currently define a license.
