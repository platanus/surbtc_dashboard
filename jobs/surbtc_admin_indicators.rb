require 'net/http'
require 'uri'
require 'rest-client'

SCHEDULER.every '1m', :first_in => 3 do
  exchange = Exchange::Api.new

  now = exchange.get_admin_stats

  # Send the event
  send_event('btc_dep_pend', { current: now.pending_deposits[0]["BTC"] })
  send_event('btc_ret_pend', { current: now.pending_withdrawals[0]["BTC"] })
  send_event('clp_dep_pend', { current: now.pending_deposits[1]["CLP"] })
  send_event('clp_ret_pend', { current: now.pending_withdrawals[1]["CLP"] })
  send_event('ver_ident', { current: now.pending_confirmation_attempts })

end
