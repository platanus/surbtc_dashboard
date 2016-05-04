require 'net/http'
require 'uri'
require 'rest-client'

current_valuation = 0

SCHEDULER.every '1m', :first_in => 1 do
  last_valuation = current_valuation
  # Go get the prices from yahoo open api
  usd_in_clp = JSON.parse(RestClient.get "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USDCLP%22)&env=store://datatables.org/alltableswithkeys&format=json")["query"]["results"]["rate"]["Rate"].to_f

  # Prepare the event information
  current_valuation = usd_in_clp
  change = current_valuation - last_valuation

  # Send the event
  send_event('usd_in_clp', { current: current_valuation, difference: change.abs, last: last_valuation })

end
