require 'net/http'
require 'uri'
require "pry"


current_valuation_usd = 0
current_valuation_clp = 0

SCHEDULER.every '5m', :first_in => 1 do
  currencyservice_url = "http://10.142.0.3:10000"
  usd_in_clp = JSON.parse(RestClient.get "#{currencyservice_url}/convert/usd/clp?api_key=#{ENV['CURRENCY_CONVERTER_API_KEY']}")["result"].to_f
  usd_in_cop = JSON.parse(RestClient.get "#{currencyservice_url}/convert/usd/cop?api_key=#{ENV['CURRENCY_CONVERTER_API_KEY']}")["result"].to_f

  # Go get the prices from bitstamp open api
  uri = URI.parse('https://www.bitstamp.net/api/ticker/')
  http = Net::HTTP.new(uri.host, uri.port)
  if uri.scheme == "https"
    http.use_ssl=true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  # Parse the resulting json from bitstamp's response
  obj = JSON.parse(response.body)

  # Prepare the event information
  current_valuation_usd = obj['last'].to_i
  current_valuation_clp = (current_valuation_usd * usd_in_clp).to_i
  current_valuation_cop = (current_valuation_usd * usd_in_cop).to_i
  # Send the event
  send_event('bitstamp_price_usd', { current: current_valuation_usd })
  send_event('bitstamp_price_clp', { current: current_valuation_clp })
  send_event('bitstamp_price_cop', { current: current_valuation_cop })

end
