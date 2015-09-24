require "active_support"
require "active_support/core_ext"

SCHEDULER_TIME = ENV["SCHEDULER_TIME"] || "1h"

SCHEDULER.every SCHEDULER_TIME do
  exchange = Exchange::Api.new

  now = exchange.get_stats(1.month.ago, Time.now)
  last_month = exchange.get_stats(2.months.ago, 1.month.ago)

  send_event("header", text: "Last 30 Days")
  send_event("operations_count", value: now.operations_count)
  send_event("transacted_amount",
    current: now.transacted_amount,
    last: last_month.transacted_amount
  )
  send_event("earned_fee",
    current: now.earned_fee,
    last: last_month.earned_fee
  )
  send_event("users", items: [
    { label: "Registrados", value: now.registered_users_count },
    { label: "Activos", value: now.active_users_count }
  ], unordered: true)
  send_event("best_users", items: now.top_payers, unordered: false)
end
