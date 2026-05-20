class TicketController < ApplicationController
  before_action :authenticate_user!
  # Tickets list page (requires authentication)
  def index
    query = Ticket.includes(:submitter, :assignee)
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
    @users = User.order(:first_name, :last_name, :email)
  end
  def create
    @ticket = Ticket.new(ticket_params)
    @ticket.submitter = current_user
    if @ticket.save
      redirect_to tickets_path, notice: "Ticket was successfully created."
    else
      @users = User.order(:first_name, :last_name, :email)
      render :new, status: :unprocessable_entity
    end
  end

  private
  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :category, :priority, :location, :assigned_to_id)
  end
end
