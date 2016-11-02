require 'net/http'
require 'uri'
require 'rest-client'

current_valuation = 0

SCHEDULER.every '1m', :first_in => 1 do
  usd_in_clp = JSON.parse(RestClient.get "http://currencyconverter.services.surbtc.com/convert/usd/clp?api_key=#{ENV['CURRENCY_CONVERTER_API_KEY']}")["result"].to_f
  usd_in_cop = JSON.parse(RestClient.get "http://currencyconverter.services.surbtc.com/convert/usd/cop?api_key=r9f6UELXQxVKhPXoqTfrodgjckwygENJrureaKibJ9CuCaCosW")["result"].to_f

  # Send the event
  send_event('usd_in_clp', { current: usd_in_clp })
  send_event('usd_in_cop', { current: usd_in_cop })

end
