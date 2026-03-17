class TicketController < ApplicationController
  def home
    @pagy, @tickets = pagy(Ticket.all, limit: 6)
  end
  def new
    @ticket = Ticket.new
  end
  def create
    @ticket = Ticket.new(ticket_params)
    if @ticket.save
      redirect_to root_path, notice: "Ticket was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :category, :priority, :location, :submitter_name, :assigned_to)
  end
end
