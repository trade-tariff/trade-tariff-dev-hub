class ErrorsController < ApplicationController
  def not_found
    message = "If you typed the web address, check it is correct."
    render_error(status: :not_found, header: "Page not found", message:, json_error: "Resource not found")
  end

  def unprocessable_content
    message = "We're sorry, but we cannot process your request at this time.<br>
               Please contact support for assistance or try a different request.".html_safe
    render_error(status: :unprocessable_content, message:)
  end

  def internal_server_error
    message = "We are experiencing technical difficulties"
    render_error(status: :internal_server_error, header: "We are experiencing technical difficulties", message: message, json_error: "Internal server error")
  end

  def bad_request
    message = "The request you made is not valid.<br>
               Please contact support for assistance or try a different request.".html_safe
    render_error(status: :bad_request, message:)
  end

  def method_not_allowed
    message = "We're sorry, but this request method is not supported.<br>
               Please contact support for assistance or try a different request.".html_safe
    render_error(status: :method_not_allowed, message:)
  end

  def not_acceptable
    message = "Unfortunately, we cannot fulfill your request as it is not in a format we can accept.<br>
               Please contact support for assistance or try a different request.".html_safe
    render_error(status: :not_acceptable, message:)
  end

  def not_implemented
    message = 'We\'re sorry, but the requested action is not supported by our server at this time.<br>
               Please contact support for assistance or try a different request.'.html_safe
    render_error(status: :not_implemented, message:)
  end

  def maintenance
    message = "We are currently undergoing maintenance. Please try again later."
    render_error(status: :service_unavailable, header: "Maintenance mode", message:)
  end

  def too_many_requests
    message = "You have made too many requests. Please try again later."
    render_error(status: :too_many_requests, message:)
  end

private

  def render_error(status:, message:, header: status.to_s.humanize, json_error: header)
    respond_to do |format|
      format.html { render "error", status: status, locals: { header: header, message: message } }
      format.json { render json: { error: json_error }, status: status }
      format.all { render status: status, plain: json_error }
    end
  end
end
