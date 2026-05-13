class TicketController < ApplicationController
  before_action :authenticate_user!

  def home
    query = Ticket.all
    query = query.search(params[:search]) if params[:search].present?
    query = query.by_status(params[:status]) if params[:status].present?
    query = query.by_priority(params[:priority]) if params[:priority].present?
    query = query.by_category(params[:category]) if params[:category].present?

    @pagy, @tickets = pagy(query, limit: 6)
    @statuses = Ticket.status_options
    @priorities = Ticket.priority_options
    @categories = Ticket.category_options
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
