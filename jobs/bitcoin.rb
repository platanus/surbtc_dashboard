require 'net/http'
require 'uri'

current_valuation_usd = 0
current_valuation_clp = 0

SCHEDULER.every '2m', :first_in => 1 do

  usd_in_clp = JSON.parse(RestClient.get "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USDCLP%22)&env=store://datatables.org/alltableswithkeys&format=json")["query"]["results"]["rate"]["Rate"].to_f

  last_valuation_usd = current_valuation_usd
  last_valuation_clp = current_valuation_clp
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
  change_usd = current_valuation_usd - last_valuation_usd
  change_clp = current_valuation_clp - last_valuation_clp

  # Send the event
  send_event('bitstamp_price_usd', { current: current_valuation_usd, difference: change_usd.abs, last: last_valuation_usd })
  send_event('bitstamp_price_clp', { current: current_valuation_clp, difference: change_clp.abs, last: last_valuation_clp })

end
