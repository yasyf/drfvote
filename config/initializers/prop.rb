if Rails.application.vcwiz?
  require 'prop/middleware'

  Prop.cache = Rails.application.redis_prop_cache

  Prop.before_throttle do |handle, key, threshold, interval|
    ActiveSupport::Notifications.instrument('throttle.prop', handle: handle, key: key, threshold: threshold, interval: interval)
  end

  Prop.configure(:api_request_by_user, threshold: 100, interval: 10.seconds, description: 'too many API requests for this user')
  Prop.configure(:api_request_by_ip, threshold: 100, interval: 10.seconds, description: 'too many API requests for this address')
  Prop.configure(:api_request, threshold: 10000, interval: 1.hour, description: 'too many API requests for this hour')

  Rails.application.config.middleware.use Prop::Middleware
end