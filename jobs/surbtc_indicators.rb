require 'net/http'
require 'uri'
require 'rest-client'

SCHEDULER.every '1m', :first_in => 5 do
  ["cop","clp"].each do |market|
    uri = "https://www.surbtc.com/api/v1/markets/btc-#{market}/indicators.json"
    # Go get the prices from yahoo open api
    indicators = JSON.parse(RestClient.get uri)["indicators"]

    last_price = indicators[0]["value"].to_f/1e2
    max_bid = indicators[1]["value"].to_f/1e2
    min_ask = indicators[2]["value"].to_f/1e2

    last_spread = min_ask - max_bid

    # Prepare the event information
    current_valuation = last_price
    current_spread_val = last_spread

    # Send the event
    send_event('surbtc_price_' + market, { current: current_valuation })
    send_event('surbtc_spread_' + market, { current: current_spread_val.round(2) })
    send_event('surbtc_max_bid_' + market, { current: max_bid })
    send_event('surbtc_min_ask_' + market, { current: min_ask })
  end
end
