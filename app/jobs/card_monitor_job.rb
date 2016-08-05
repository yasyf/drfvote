class CardMonitorJob < ActiveJob::Base
  include Concerns::Slackable

  queue_as :default

  def perform
    companies = Company.where(list: List.funnel).map do |company|
      move_event = LoggedEvent.for(company, :company_list_changed)
      if move_event && move_event.updated_at < 1.week.ago
        move_event.touch
        users = company.users.map { |user| "<@#{user.slack_id}>" }.join(', ')
        "#{users}: <#{company.trello_url}|#{company.name}> (#{company.list.name}, #{move_event.updated_at.to_date.to_s(:long)})"
      end
    end.compact.join("\n")

    if companies.present?
      message = "The following companies have been stuck in the same stage of the pipeline for over a week!\n#{companies}"
      slack_send! ENV['SLACK_CHANNEL'], message
    end
  end
end
