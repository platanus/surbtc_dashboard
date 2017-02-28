require 'net/http'
require 'uri'
require 'rest-client'

current_valuation = 0

SCHEDULER.every '1m', :first_in => 1 do
  currencyservice_url = "http://10.142.0.3:10000"
  usd_in_clp = JSON.parse(RestClient.get "#{currencyservice_url}/convert/usd/clp?api_key=#{ENV['CURRENCY_CONVERTER_API_KEY']}")["result"].to_f
  usd_in_cop = JSON.parse(RestClient.get "#{currencyservice_url}/convert/usd/cop?api_key=#{ENV['CURRENCY_CONVERTER_API_KEY']}")["result"].to_f

  # Send the event
  send_event('usd_in_clp', { current: usd_in_clp })
  send_event('usd_in_cop', { current: usd_in_cop })

end
