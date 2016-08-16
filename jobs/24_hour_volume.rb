require "active_support"
require "active_support/core_ext"

require 'logger'

current_valuation = 0

SCHEDULER.every "1m", :first_in => 5 do
  last_valuation = current_valuation
#	spread / puntas / 24hrs
  exchange = Exchange::Api.new
  stats = exchange.get_stats(Time.now - 24.hours,Time.now);
  current_valuation = stats.transacted_amount.to_i
  change = current_valuation - last_valuation
  send_event('24hrs_volume', { current: current_valuation })
  send_event('24hrs_volume_cop', { current: current_valuation })

end
