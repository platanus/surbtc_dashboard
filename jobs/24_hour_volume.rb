require "active_support"
require "active_support/core_ext"

require 'logger'

current_valuation = 0

SCHEDULER.every "10s", :first_in => 5 do
  last_valuation = current_valuation
#	spread / puntas / 24hrs
  exchange = Exchange::Api.new
  stats = exchange.get_stats(Time.now - 24.hours,Time.now);
#  binding.pry
  send_event_for "BTC", stats
  send_event_for "BTC_CLP", stats
  send_event_for "BTC_COP", stats
  send_event_for "COP", stats
  send_event_for "CLP", stats
end

def send_event_for currency, stats
  current_valuation = stats.send("transacted_amount_"+currency.downcase)
  current_valuation = current_valuation.to_f.round(2)
  send_event('24hrs_volume_'+currency.downcase, { current: current_valuation })
end
