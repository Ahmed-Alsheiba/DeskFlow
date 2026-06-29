# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

users_data = [
  { first_name: "Alice", last_name: "Johnson", email: "alice.johnson@example.com", role: "manager", job_title: "Operations Manager", sector: "Operations" },
  { first_name: "Bob", last_name: "Smith", email: "bob.smith@example.com", role: "staff", job_title: "POS Technician", sector: "Bar/Food Service" },
  { first_name: "Carlos", last_name: "Rivera", email: "carlos.rivera@example.com", role: "staff", job_title: "IT Support", sector: "IT/Operations" },
  { first_name: "Dana", last_name: "Lee", email: "dana.lee@example.com", role: "staff", job_title: "Network Administrator", sector: "IT/Operations" },
  { first_name: "Eva", last_name: "Brown", email: "eva.brown@example.com", role: "staff", job_title: "Front Desk Staff", sector: "Reception" },
  { first_name: "Frank", last_name: "White", email: "frank.white@example.com", role: "staff", job_title: "Reception Manager", sector: "Reception" },
  { first_name: "Grace", last_name: "Kim", email: "grace.kim@example.com", role: "staff", job_title: "System Administrator", sector: "IT/Operations" },
  { first_name: "Hana", last_name: "Patel", email: "hana.patel@example.com", role: "staff", job_title: "Admin Office Staff", sector: "Administration" },
  { first_name: "Ivan", last_name: "Cruz", email: "ivan.cruz@example.com", role: "staff", job_title: "IT Support", sector: "IT/Operations" },
  { first_name: "Julia", last_name: "Nguyen", email: "julia.nguyen@example.com", role: "staff", job_title: "Housekeeping Manager", sector: "Housekeeping" },
  { first_name: "Kevin", last_name: "Marsh", email: "kevin.marsh@example.com", role: "staff", job_title: "Reception Staff", sector: "Reception" },
  { first_name: "Lily", last_name: "Tan", email: "lily.tan@example.com", role: "staff", job_title: "Hardware Technician", sector: "IT/Operations" },
  { first_name: "Mike", last_name: "Osei", email: "mike.osei@example.com", role: "staff", job_title: "IT Room Technician", sector: "IT/Operations" },
  { first_name: "Nancy", last_name: "Ford", email: "nancy.ford@example.com", role: "manager", job_title: "IT Manager", sector: "IT/Operations" },
  { first_name: "Olivia", last_name: "Chen", email: "olivia.chen@example.com", role: "staff", job_title: "Bar Manager", sector: "Bar/Food Service" },
  { first_name: "Peter", last_name: "Davis", email: "peter.davis@example.com", role: "staff", job_title: "POS Technician", sector: "Bar/Food Service" },
  { first_name: "Quinn", last_name: "Adams", email: "quinn.adams@example.com", role: "staff", job_title: "Guest Services", sector: "Operations" },
  { first_name: "Rachel", last_name: "Green", email: "rachel.green@example.com", role: "staff", job_title: "Hardware Technician", sector: "IT/Operations" },
  { first_name: "Sam", last_name: "Torres", email: "sam.torres@example.com", role: "staff", job_title: "Remote Support", sector: "IT/Operations" },
  { first_name: "Tina", last_name: "Wallis", email: "tina.wallis@example.com", role: "staff", job_title: "Network Administrator", sector: "IT/Operations" },
  { first_name: "Uma", last_name: "Singh", email: "uma.singh@example.com", role: "staff", job_title: "Housekeeping Manager", sector: "Housekeeping" },
  { first_name: "Victor", last_name: "Bell", email: "victor.bell@example.com", role: "staff", job_title: "System Administrator", sector: "IT/Operations" },
  { first_name: "Wendy", last_name: "Frost", email: "wendy.frost@example.com", role: "staff", job_title: "Admin Office Staff", sector: "Administration" },
  { first_name: "Xavier", last_name: "Ho", email: "xavier.ho@example.com", role: "staff", job_title: "IT Support", sector: "IT/Operations" },
  { first_name: "Yara", last_name: "Malik", email: "yara.malik@example.com", role: "staff", job_title: "Checkout Staff", sector: "Bar/Food Service" },
  { first_name: "Zoe", last_name: "Clarke", email: "zoe.clarke@example.com", role: "admin", job_title: "IT Director", sector: "IT/Operations" },
]

def find_user_by_name!(full_name)
  first_name, last_name = full_name.split(" ", 2)
  User.find_by!(first_name: first_name, last_name: last_name)
end

# Returns a weekday-weighted datetime within the last ~90 days. Seeding records with varied
# created_at keeps the dashboard "Tickets Reported" (by day of week) chart realistic instead
# of every record landing on the single day the seed was run. Deterministic per +seed+.
def realistic_created_at(seed)
  rng = Random.new(seed)
  date = Date.current - rng.rand(0..89)
  # Reduce weekends: re-pick once (75% of the time) so Mon–Fri dominate without a single spike.
  date = Date.current - rng.rand(0..89) if [ 0, 6 ].include?(date.wday) && rng.rand < 0.75
  Time.zone.local(date.year, date.month, date.day, rng.rand(8..18), rng.rand(0..59), rng.rand(0..59))
end

Comment.delete_all
Ticket.delete_all
User.delete_all

users_data.each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(attrs.merge(password: "password", password_confirmation: "password"))
  user.save!
end

# Read-only preview/demo account used by the "Live Demo" entry point. It can browse the
# app but never mutate anything (see ApplicationController#block_preview_writes). The
# password is random/unused — visitors enter via POST /preview, not by logging in.
preview_password = ENV.fetch("PREVIEW_PASSWORD") { SecureRandom.base58(32) }
preview_user = User.find_or_initialize_by(email: "demo@preview.local")
preview_user.assign_attributes(
  first_name: "Demo",
  last_name: "Visitor",
  role: "preview",
  job_title: "Guest",
  sector: "General",
  password: preview_password,
  password_confirmation: preview_password
)
preview_user.save!

def find_ticket_by_title!(title)
  Ticket.find_by!(title: title)
end

tickets = [
  { title: "Front desk POS not syncing payments", description: "Card payments are approved but the front desk POS is not syncing receipts to the PMS.", category: "POS", priority: "High", status: "In Progress", location: "Front Desk", submitter_name: "Alice Johnson", assigned_to: "Bob Smith" },
  { title: "Lobby Wi-Fi keeps disconnecting", description: "Guest devices lose connection every few minutes in the lobby seating area.", category: "Network", priority: "High", status: "In Progress", location: "Lobby", submitter_name: "Carlos Rivera", assigned_to: "Dana Lee" },
  { title: "Conference room printer offline", description: "The printer used for meeting packets is showing an offline status after a power cycle.", category: "Hardware", priority: "Medium", status: "Open", location: "Conference Room B", submitter_name: "Eva Brown", assigned_to: nil },
  { title: "PMS check-in records not syncing", description: "New guest check-ins are not appearing in the property management system dashboard.", category: "PMS", priority: "High", status: "In Progress", location: "Reception", submitter_name: "Frank White", assigned_to: "Grace Kim" },
  { title: "Housekeeping tablet app crashing", description: "The housekeeping app closes as soon as room status updates are submitted.", category: "Software", priority: "Medium", status: "In Progress", location: "Housekeeping Office", submitter_name: "Hana Patel", assigned_to: "Ivan Cruz" },
  { title: "Guest room internet speed slow", description: "Rooms on the second floor are reporting slow browsing and streaming performance.", category: "Network", priority: "Medium", status: "Open", location: "Floor 2", submitter_name: "Julia Nguyen", assigned_to: nil },
  { title: "Reception keyboard missing keys", description: "Several keys on the front desk keyboard are sticking and missing inputs.", category: "Hardware", priority: "Low", status: "Closed", location: "Reception", submitter_name: "Kevin Marsh", assigned_to: "Lily Tan" },
  { title: "Back office workstation reboot loop", description: "Workstation 4 in the admin office is stuck restarting during updates.", category: "Software", priority: "High", status: "In Progress", location: "Admin Office", submitter_name: "Mike Osei", assigned_to: "Nancy Ford" },
  { title: "Bar card reader rejecting AMEX", description: "American Express cards are being declined at the bar terminal.", category: "POS", priority: "Medium", status: "In Progress", location: "Bar", submitter_name: "Olivia Chen", assigned_to: "Peter Davis" },
  { title: "Room 305 TV remote not working", description: "The smart TV remote in room 305 still does not respond after fresh batteries.", category: "Hardware", priority: "Low", status: "Closed", location: "Room 305", submitter_name: "Quinn Adams", assigned_to: "Rachel Green" },
  { title: "VPN blocked for remote staff", description: "Remote users cannot connect to the corporate VPN after the firewall update.", category: "Network", priority: "High", status: "In Progress", location: "Remote Support", submitter_name: "Sam Torres", assigned_to: "Tina Wallis" },
  { title: "PMS room status not refreshing", description: "Cleaned rooms are still displaying as occupied in the PMS queue.", category: "PMS", priority: "Medium", status: "In Progress", location: "Housekeeping", submitter_name: "Uma Singh", assigned_to: "Victor Bell" },
  { title: "Antivirus signatures outdated", description: "Multiple hotel workstations are more than a month behind on virus definitions.", category: "Software", priority: "Low", status: "Closed", location: "IT Office", submitter_name: "Wendy Frost", assigned_to: "Xavier Ho" },
  { title: "Checkout receipt printer jammed", description: "The receipt printer at checkout jams after the first page during busy periods.", category: "POS", priority: "Medium", status: "Open", location: "Checkout", submitter_name: "Yara Malik", assigned_to: nil },
  { title: "Boardroom projector audio missing", description: "The boardroom projector shows video but no sound during guest presentations.", category: "Hardware", priority: "Low", status: "In Progress", location: "Boardroom", submitter_name: "Zoe Clarke", assigned_to: "Alice Johnson" },
  { title: "Spa booking console frozen", description: "The spa reception console freezes whenever staff try to confirm appointments.", category: "Software", priority: "Medium", status: "Open", location: "Spa Reception", submitter_name: "Alice Johnson", assigned_to: "Grace Kim" },
  { title: "Pool area access point down", description: "The Wi-Fi access point near the pool is not broadcasting a network signal.", category: "Network", priority: "High", status: "In Progress", location: "Pool Deck", submitter_name: "Carlos Rivera", assigned_to: "Tina Wallis" },
  { title: "Laundry barcode scanner failing", description: "The barcode scanner used for linen tracking is not reading labels consistently.", category: "Hardware", priority: "Medium", status: "Open", location: "Laundry Room", submitter_name: "Eva Brown", assigned_to: "Lily Tan" },
  { title: "PMS folio charges duplicating", description: "Guest folios are showing duplicate minibar charges after checkout.", category: "PMS", priority: "High", status: "In Progress", location: "Front Desk", submitter_name: "Frank White", assigned_to: "Nancy Ford" },
  { title: "Digital signage schedule not updating", description: "Lobby digital signage is still displaying yesterday's promotions.", category: "Software", priority: "Low", status: "Closed", location: "Lobby", submitter_name: "Hana Patel", assigned_to: "Victor Bell" },
  { title: "Key card encoder error", description: "The front desk key card encoder returns an error whenever new cards are issued.", category: "POS", priority: "High", status: "In Progress", location: "Front Desk", submitter_name: "Kevin Marsh", assigned_to: "Peter Davis" },
  { title: "Meeting room HDMI cable damaged", description: "The HDMI cable in meeting room A has visible wear and causes flickering.", category: "Hardware", priority: "Low", status: "Closed", location: "Meeting Room A", submitter_name: "Mike Osei", assigned_to: "Rachel Green" },
  { title: "Guest portal page timing out", description: "Guests cannot access the booking portal because the page times out after login.", category: "Software", priority: "Medium", status: "Open", location: "Guest Portal", submitter_name: "Olivia Chen", assigned_to: "Xavier Ho" },
  { title: "Housekeeping room-status app lagging", description: "Room clean and dirty updates are delayed in the housekeeping app after submission.", category: "Software", priority: "Medium", status: "In Progress", location: "Housekeeping Office", submitter_name: "Julia Nguyen", assigned_to: "Ivan Cruz" },
  { title: "Guest safe keypad battery low", description: "Several in-room safes are reporting low battery warnings and intermittent keypad response.", category: "Hardware", priority: "Medium", status: "Open", location: "Guest Rooms", submitter_name: "Quinn Adams", assigned_to: "Lily Tan" },
  { title: "Dining room receipt reprints missing tax line", description: "Reprinted receipts from the restaurant POS are missing the tax breakdown line.", category: "POS", priority: "Low", status: "Closed", location: "Restaurant", submitter_name: "Olivia Chen", assigned_to: "Peter Davis" },
  { title: "Night audit export failing", description: "The night audit summary will not export to PDF after the latest PMS update.", category: "PMS", priority: "High", status: "In Progress", location: "Front Office", submitter_name: "Frank White", assigned_to: "Nancy Ford" },
  { title: "Main entrance camera feed dropping", description: "The main entrance camera feed cuts out every few minutes during live monitoring.", category: "Hardware", priority: "Medium", status: "Open", location: "Entrance", submitter_name: "Wendy Frost", assigned_to: "Rachel Green" },
  { title: "Banquet team Wi-Fi access request", description: "Banquet staff need reliable Wi-Fi credentials for handheld order tablets.", category: "Network", priority: "Low", status: "Closed", location: "Banquet Hall", submitter_name: "Carlos Rivera", assigned_to: "Dana Lee" },
  { title: "Minibar stock counts not saving", description: "Counts entered on the minibar inventory tablet disappear after the save button is pressed.", category: "Software", priority: "Medium", status: "In Progress", location: "Stock Room", submitter_name: "Yara Malik", assigned_to: "Xavier Ho" },
  { title: "Elevator lobby display frozen", description: "The lobby display near the elevators is frozen on yesterday's promotion slide.", category: "Hardware", priority: "Low", status: "Closed", location: "Lobby", submitter_name: "Hana Patel", assigned_to: "Victor Bell" },
  { title: "Room service order screen stuck", description: "The room service order screen stops responding when items are added to a ticket.", category: "Software", priority: "High", status: "In Progress", location: "Room Service", submitter_name: "Kevin Marsh", assigned_to: "Grace Kim" },
  { title: "Conference hall access point overheating", description: "The conference hall access point is warm to the touch and disconnecting guests.", category: "Network", priority: "High", status: "In Progress", location: "Conference Hall", submitter_name: "Sam Torres", assigned_to: "Tina Wallis" },
  { title: "Passport scanner not reading IDs", description: "The front desk passport scanner intermittently fails to detect guest travel documents.", category: "Hardware", priority: "Medium", status: "Closed", location: "Front Desk", submitter_name: "Eva Brown", assigned_to: "Bob Smith" },
  { title: "Minibar fridge temperature sensor alert", description: "The minibar fridge in the executive wing keeps reporting a temperature sensor warning.", category: "Hardware", priority: "Medium", status: "In Progress", location: "Executive Wing", submitter_name: "Wendy Frost", assigned_to: "Rachel Green" },
  { title: "Laundry dryer control panel rebooting", description: "The laundry dryer control panel reboots after every cycle selection.", category: "Hardware", priority: "Low", status: "Closed", location: "Laundry Room", submitter_name: "Uma Singh", assigned_to: "Lily Tan" },
  { title: "Guest portal payment gateway timeout", description: "Guests reach a timeout error when paying deposits on the booking portal.", category: "Software", priority: "High", status: "In Progress", location: "Guest Portal", submitter_name: "Olivia Chen", assigned_to: "Xavier Ho" },
  { title: "Kitchen printer queue delayed", description: "Room service tickets are arriving late at the kitchen printer during breakfast rush.", category: "POS", priority: "Medium", status: "Open", location: "Kitchen", submitter_name: "Quinn Adams", assigned_to: "Peter Davis" },
  { title: "Security gate access log not exporting", description: "The staff entrance access log will not export for the weekly audit report.", category: "Software", priority: "Low", status: "In Progress", location: "Security Office", submitter_name: "Zoe Clarke", assigned_to: "Nancy Ford" },
  { title: "Spa appointment tablets out of sync", description: "The spa tablets show conflicting appointment availability after a recent update.", category: "Software", priority: "Medium", status: "Closed", location: "Spa Reception", submitter_name: "Alice Johnson", assigned_to: "Grace Kim" },
]

tickets.each_with_index do |attrs, i|
  submitter = find_user_by_name!(attrs[:submitter_name])
  assignee = attrs[:assigned_to].present? ? find_user_by_name!(attrs[:assigned_to]) : nil

  ticket = Ticket.find_or_initialize_by(title: attrs[:title])
  ticket.assign_attributes(attrs.except(:submitter_name, :assigned_to))
  ticket.submitter = submitter
  ticket.submitter_name = submitter.display_name
  ticket.assignee = assignee
  ticket.assigned_to = assignee&.display_name
  # Explicit timestamps are honored by ActiveRecord (it only auto-fills blank ones).
  created = realistic_created_at(20260629 + i)
  ticket.created_at = created
  ticket.updated_at = created
  ticket.save!
end

comments = [
  { ticket_title: "Front desk POS not syncing payments", author_name: "Bob Smith", content: "Confirmed the payment bridge is back online and receipt sync is moving again." },
  { ticket_title: "PMS check-in records not syncing", author_name: "Grace Kim", content: "Cleared the sync queue and reprocessed the pending arrivals." },
  { ticket_title: "Reception keyboard missing keys", author_name: "Lily Tan", content: "Replacement keyboard installed at reception and old unit removed." },
  { ticket_title: "Bar card reader rejecting AMEX", author_name: "Peter Davis", content: "Terminal firmware updated and AMEX test transaction completed successfully." },
  { ticket_title: "VPN blocked for remote staff", author_name: "Tina Wallis", content: "Firewall rule adjusted; remote users can reconnect now." },
  { ticket_title: "PMS folio charges duplicating", author_name: "Nancy Ford", content: "Duplicate posting was traced to the minibar batch job and corrected." },
  { ticket_title: "Digital signage schedule not updating", author_name: "Victor Bell", content: "Signage schedule pushed manually and the display is now current." },
  { ticket_title: "Boardroom projector audio missing", author_name: "Alice Johnson", content: "Audio amplifier cable reseated and the sound test passed." },
  { ticket_title: "Housekeeping room-status app lagging", author_name: "Ivan Cruz", content: "Investigating app latency with the vendor; initial logs are uploaded." },
  { ticket_title: "Dining room receipt reprints missing tax line", author_name: "Peter Davis", content: "Receipt template corrected and reprints now show the full tax breakdown." },
  { ticket_title: "Night audit export failing", author_name: "Nancy Ford", content: "Export issue reproduced and a fix is queued for the next PMS restart." },
  { ticket_title: "Banquet team Wi-Fi access request", author_name: "Dana Lee", content: "Banquet credentials issued and tested on the event tablets." },
]

comments.each_with_index do |attrs, i|
  ticket = find_ticket_by_title!(attrs[:ticket_title])
  author = find_user_by_name!(attrs[:author_name])

  comment = Comment.find_or_initialize_by(ticket: ticket, author: author, content: attrs[:content])
  comment.author_name = author.display_name
  # Place the comment somewhere between its ticket's creation and now, so the activity
  # timeline stays coherent (a comment never predates its ticket).
  rng = Random.new(777 + i)
  span = [ (Time.current - ticket.created_at).to_i, 0 ].max
  created = ticket.created_at + (span.positive? ? rng.rand(0..span) : 0)
  comment.created_at = created
  comment.updated_at = created
  comment.save!
end
