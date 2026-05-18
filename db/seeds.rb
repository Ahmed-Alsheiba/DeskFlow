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

users_data.each do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.first_name = attrs[:first_name]
    u.last_name = attrs[:last_name]
    u.role = attrs[:role]
    u.password = "password"
    u.password_confirmation = "password"
    u.sector = attrs[:sector]
    u.job_title = attrs[:job_title]
  end
end

# tickets = [
#   { title: "POS terminal not responding", description: "The POS terminal at front desk freezes after each transaction.", category: "POS", priority: "High", status: "Open", location: "Front Desk", submitter_name: "Alice Johnson", assigned_to: "Bob Smith" },
#   { title: "Wi-Fi dropping in lobby", description: "Guests are reporting intermittent Wi-Fi disconnections in the lobby.", category: "Network", priority: "High", status: "In Progress", location: "Lobby", submitter_name: "Carlos Rivera", assigned_to: "Dana Lee" },
#   { title: "Printer offline in conference room", description: "The HP LaserJet in conference room B shows offline status.", category: "Hardware", priority: "Medium", status: "Open", location: "Conference Room B", submitter_name: "Eva Brown", assigned_to: nil },
#   { title: "PMS check-in sync failure", description: "Guest check-ins are not syncing to the property management system.", category: "PMS", priority: "High", status: "Open", location: "Reception", submitter_name: "Frank White", assigned_to: "Grace Kim" },
#   { title: "Email client not launching", description: "Outlook crashes immediately on startup for two staff members.", category: "Software", priority: "Medium", status: "In Progress", location: "Admin Office", submitter_name: "Hana Patel", assigned_to: "Ivan Cruz" },
#   { title: "Slow internet in rooms 201-210", description: "Guests in rooms 201-210 are complaining about very slow internet speeds.", category: "Network", priority: "Medium", status: "Open", location: "Floor 2", submitter_name: "Julia Nguyen", assigned_to: nil },
#   { title: "Broken keyboard at reception", description: "Several keys on the reception keyboard are stuck.", category: "Hardware", priority: "Low", status: "Closed", location: "Reception", submitter_name: "Kevin Marsh", assigned_to: "Lily Tan" },
#   { title: "Windows update loop on workstation 4", description: "Workstation 4 is stuck in a Windows update reboot loop.", category: "Software", priority: "High", status: "In Progress", location: "IT Room", submitter_name: "Mike Osei", assigned_to: "Nancy Ford" },
#   { title: "Card reader not accepting AMEX", description: "AMEX cards are being declined at the bar POS terminal.", category: "POS", priority: "Medium", status: "Open", location: "Bar", submitter_name: "Olivia Chen", assigned_to: "Peter Davis" },
#   { title: "Room 305 TV remote unresponsive", description: "The smart TV remote in room 305 is not working after battery replacement.", category: "Hardware", priority: "Low", status: "Closed", location: "Room 305", submitter_name: "Quinn Adams", assigned_to: "Rachel Green" },
#   { title: "VPN access issue for remote staff", description: "Remote staff cannot connect to VPN since the last firewall update.", category: "Network", priority: "High", status: "Open", location: "Remote", submitter_name: "Sam Torres", assigned_to: "Tina Wallis" },
#   { title: "PMS room availability not updating", description: "Rooms marked as cleaned are still showing occupied in the PMS.", category: "PMS", priority: "Medium", status: "In Progress", location: "Housekeeping", submitter_name: "Uma Singh", assigned_to: "Victor Bell" },
#   { title: "Antivirus definitions out of date", description: "Three workstations show antivirus definitions over 30 days old.", category: "Software", priority: "Low", status: "Closed", location: "Admin Office", submitter_name: "Wendy Frost", assigned_to: "Xavier Ho" },
#   { title: "Receipt printer paper jam", description: "The receipt printer at checkout keeps jamming mid-print.", category: "POS", priority: "Medium", status: "Open", location: "Checkout", submitter_name: "Yara Malik", assigned_to: nil },
#   { title: "No audio on boardroom projector", description: "The projector in the boardroom displays video but has no audio output.", category: "Hardware", priority: "Low", status: "Open", location: "Boardroom", submitter_name: "Zoe Clarke", assigned_to: "Alice Johnson" },
# ]

# tickets.each do |attrs|
#   Ticket.find_or_create_by!(title: attrs[:title]) do |t|
#     t.assign_attributes(attrs)
#   end
# end
