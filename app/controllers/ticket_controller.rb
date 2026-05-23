class TicketController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ticket, only: [:show, :edit, :update, :claim, :close]
  before_action :check_edit_permission, only: [:edit, :update, :close]

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

  def show
    @comment = Comment.new
    @comments = @ticket.comments.includes(:author).order(created_at: :desc)
  end

  def new
    @ticket = Ticket.new
    @users = User.order(:first_name, :last_name, :email)
  end

  def create
    @ticket = Ticket.new(ticket_params)
    @ticket.submitter = current_user
    if @ticket.save
      redirect_to @ticket, notice: "Ticket was successfully created."
    else
      @users = User.order(:first_name, :last_name, :email)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.order(:first_name, :last_name, :email)
  end

  def update
    if @ticket.update(ticket_params)
      redirect_to @ticket, notice: "Ticket was successfully updated."
    else
      @users = User.order(:first_name, :last_name, :email)
      render :edit, status: :unprocessable_entity
    end
  end

  def claim
    if @ticket.assigned_to_id.present?
      redirect_to @ticket, alert: "This ticket is already assigned."
    else
      @ticket.update(assigned_to_id: current_user.id)
      redirect_to @ticket, notice: "You have claimed this ticket."
    end
  end

  def close
    if @ticket.status.to_s.strip.casecmp("closed").zero?
      redirect_to @ticket, alert: "This ticket is already closed."
      return
    end

    content = params.dig(:comment, :content).to_s.strip
    if content.blank?
      redirect_to @ticket, alert: "Please add a closing comment."
      return
    end

    Ticket.transaction do
      @ticket.update!(status: "Closed")
      @ticket.comments.create!(content: content, author: current_user)
    end

    redirect_to @ticket, notice: "Ticket was closed."
  rescue ActiveRecord::RecordInvalid
    @comment = Comment.new(content: content)
    @comments = @ticket.comments.includes(:author).order(created_at: :desc)
    flash.now[:alert] = "Unable to close this ticket."
    render :show, status: :unprocessable_entity
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
  end

  def check_edit_permission
    return if can_edit_ticket?(@ticket)
    redirect_to @ticket, alert: "You are not authorized to edit this ticket."
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :category, :priority, :location, :assigned_to_id)
  end
end
