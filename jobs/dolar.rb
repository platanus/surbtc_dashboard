require 'net/http'
require 'uri'
require 'rest-client'

current_valuation = 0

SCHEDULER.every '1m', :first_in => 1 do
  last_valuation = current_valuation
  usd_in_clp = JSON.parse(RestClient.get "http://currencyconverter.services.surbtc.com/convert/usd/clp?api_key=#{ENV['CURRENCY_CONVERTER_API_KEY']}")["result"].to_f

  # Prepare the event information
  current_valuation = usd_in_clp
  change = current_valuation - last_valuation

  # Send the event
  send_event('usd_in_clp', { current: current_valuation, difference: change.abs, last: last_valuation })

end
