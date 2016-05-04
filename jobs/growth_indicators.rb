require 'net/http'
require 'uri'
require 'rest-client'

current_growth = 0
current_ttb = 10000

SCHEDULER.every '10m', :first_in => 5 do
  last_growth = current_growth
  last_ttb = current_ttb

  stats = Exchange::Api.new.get_growth_stats

  last = (stats.current_growth.to_f * 100).round(2)
  prev = (stats.prev_growth.to_f * 100).round(2)
  avg = (stats.average_growth.to_f * 100).round(2)
  ttb = ((Time.parse(stats.time_of_breakeven) - Time.now) / (60*60*24) ).ceil

  current_growth = last
  change = current_growth - last_growth
  
  current_ttb = ttb
  change_ttb = current_ttb - last_ttb

  # Send the events
  send_event('growth_prev_month', { current: prev })
  send_event('growth_current_month', { current: current_growth, difference: change.abs, last: last_growth })
  send_event('growth_avg_3_months', { current: avg })
  send_event('time_to_breakeven', { current: current_ttb, difference: change_ttb, last: last_ttb })

end
