class TicketCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ticket
  before_action :check_comment_permission

  def create
    @comment = @ticket.comments.new(comment_params)
    @comment.author = current_user

    if @comment.save
      redirect_to @ticket, notice: "Comment added successfully."
    else
      @comments = @ticket.comments.includes(:author).order(created_at: :desc)
      render "ticket/show", status: :unprocessable_entity
    end
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def check_comment_permission
    return if can_comment_ticket?(@ticket)
    redirect_to @ticket, alert: "You are not authorized to comment on this ticket."
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
