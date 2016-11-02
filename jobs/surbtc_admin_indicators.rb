require 'net/http'
require 'uri'
require 'rest-client'

SCHEDULER.every '1m', :first_in => 3 do
  exchange = Exchange::Api.new

  now = exchange.get_admin_stats

  # Send the event
#  send_event('btc_dep_pend', { current: now.pending_deposits[0]["BTC"] })
#  send_event('btc_ret_pend', { current: now.pending_withdrawals[0]["BTC"] })
  deposits_clp = (now.pending_deposits[1]["CLP"] || 0)
  withdrawals_clp = (now.pending_withdrawals[1]["CLP"] || 0)
  deposits_cop = (now.pending_deposits[1]["COP"] || 0)
  withdrawals_cop = (now.pending_withdrawals[1]["COP"] || 0)
  send_event('dep_pend', { current: deposits_clp + deposits_cop })
  send_event('ret_pend', { current: withdrawals_clp + withdrawals_cop })
  send_event('dep_pend_clp', { current: deposits_clp })
  send_event('ret_pend_clp', { current: withdrawals_clp })
  send_event('dep_pend_cop', { current: deposits_cop })
  send_event('ret_pend_cop', { current: withdrawals_cop })
  send_event('ver_ident', { current: now.pending_confirmation_attempts })

end
