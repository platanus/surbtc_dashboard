require 'net/http'
require 'uri'
require 'rest-client'

SCHEDULER.every '1m', :first_in => 3 do
  exchange = Exchange::Api.new

  now = exchange.get_admin_stats

  # Send the event
  send_event('btc_dep_pend', { current: now.btc_dep_pend })
  send_event('btc_ret_pend', { current: now.btc_ret_pend })
  send_event('clp_dep_pend', { current: now.clp_dep_pend })
  send_event('clp_ret_pend', { current: now.clp_ret_pend })
  send_event('ver_ident', { current: now.ver_ident })

end
