module TicketHelper
  def ticket_status_badge_class(status)
    case normalize_ticket_value(status)
    when "closed"
      "bg-green-100 text-green-800 ring-green-200"
    when "in_progress"
      "bg-blue-100 text-blue-800 ring-blue-200"
    else
      "bg-amber-100 text-amber-800 ring-amber-200"
    end
  end

  def ticket_priority_badge_class(priority)
    case normalize_ticket_value(priority)
    when "high"
      "bg-red-100 text-red-800 ring-red-200"
    when "low"
      "bg-slate-100 text-slate-800 ring-slate-200"
    else
      "bg-orange-100 text-orange-800 ring-orange-200"
    end
  end

  def ticket_priority_accent_class(priority)
    case normalize_ticket_value(priority)
    when "high"
      "border-l-red-400"
    when "low"
      "border-l-slate-300"
    else
      "border-l-orange-300"
    end
  end

  def format_ticket_label(value)
    value.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
  end

  private

  def normalize_ticket_value(value)
    value.to_s.strip.downcase.tr(" ", "_")
  end
end
