require 'net/http'
require 'uri'
require 'rest-client'

current_valuation = 0
current_spread_val = 0

SCHEDULER.every '1m', :first_in => 5 do
  last_valuation = current_valuation
  last_spread_val = current_spread_val
  uri = "https://www.surbtc.com/api/v1/markets/btc-clp/indicators.json"
  # Go get the prices from yahoo open api
  indicators = JSON.parse(RestClient.get uri)["indicators"]

  last_price = indicators[0]["value"].to_f/1e2
  max_bid = indicators[1]["value"].to_f/1e2
  min_ask = indicators[2]["value"].to_f/1e2

  last_spread = min_ask - max_bid

  # Prepare the event information
  current_valuation = last_price
  change = current_valuation - last_valuation
  
  current_spread_val = last_spread
  change_spread = current_spread_val - last_spread_val

  # Send the event
  send_event('surbtc_price', { current: current_valuation })
  send_event('surbtc_spread', { current: current_spread_val.round(2) })
  send_event('surbtc_max_bid', { current: max_bid })
  send_event('surbtc_min_ask', { current: min_ask })

end
