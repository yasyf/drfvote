class FounderEnhanceJob < ApplicationJob
  queue_as :now

  def perform(founder_id, augment: false)
    founder = Founder.find(founder_id)

    if augment
      update_location_info founder
      founder.save! if founder.changed?

      augment_with_clearbit founder
      update_location_info founder
      crawl_homepage! founder
    else
      update_location_info founder
    end

    founder.save! if founder.changed?
  end

  private

  def update_location_info(founder)
    founder.city = Http::Freegeoip.new(founder.ip_address).locate['city'] if founder.ip_address.present?
    founder.time_zone = Http::GoogleMaps.new.timezone(founder.city).name if founder.city.present?
  end

  def augment_with_clearbit(founder)
    response = Http::Clearbit.new(founder, founder.primary_company).enhance
    return unless response.person.present?

    founder.city ||= response.person.geo.city
    founder.time_zone ||= response.person.time_zone
    founder.bio ||= response.person.bio
    founder.homepage ||= response.person.site
    founder.facebook ||= response.person.facebook.handle
    founder.twitter ||= response.person.twitter.handle
    founder.linkedin ||= response.person.linkedin.handle
  rescue Http::Clearbit::Error
  end

  def crawl_homepage!(founder)
    body = Http::Fetch.get_one founder.homepage
    unless body.present?
      founder.homepage = nil
      return
    end
    founder.entities.concat Entity.from_html(body)
  end
end
