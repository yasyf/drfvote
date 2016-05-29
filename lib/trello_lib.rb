class TrelloLib
  def sync
    Trello::Board.find(ENV['TRELLO_BOARD']).cards.each do |card|
      yield parse(card)
    end
  end

  private

  class DateTimeNotFound < StandardError
    def log!(card)
      usernames = card.members.map { |mem| mem.email.split('@').first }
      LoggedError.log! :datetime_not_found, card, usernames, card.list.name, card.name, card.url
    end
  end

  def parse(card)
    pitch_on = begin
      parse_pitch_on(card) if card.list_id == ENV['TRELLO_LIST']
    rescue DateTimeNotFound => dtnf
      dtnf.log! card
      nil
    end
    { trello_id: card.id, name: card.name, pitch_on: pitch_on }
  end

  def parse_pitch_on(card)
    index = card.name.index /\d/
    raise DateTimeNotFound, card.name unless index.present?
    datestring = card.name[index..-1]
    date = Chronic.parse(datestring)
    raise DateTimeNotFound, datestring unless date.present?
    date
  end
end
