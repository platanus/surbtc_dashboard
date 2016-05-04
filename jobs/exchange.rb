require "active_support"
require "active_support/core_ext"

require 'logger'

SCHEDULER.every "1h", :first_in => 0 do
  
  trade_series = Hash.new
  new_users_series = Hash.new
  active_users_series = Hash.new

  # Generate series
  total = 12
  
  #trade_series[:name] = "Transado CLP"
  #new_users_series[:name] = "Registrados"
  #active_users_series[:name] = nil
  data = []
  data_users = []
  data_active_users = []

  current_time = (Time.now - (total-1).months).beginning_of_month

  last_step_data = nil

  total.times do |i|
    exchange = Exchange::Api.new
    t = current_time.beginning_of_month
    t2 = current_time.end_of_month
    current_time = t2 + 1.day
    step_stats = exchange.get_stats(t, t2);
    datapoint = { x: t.to_i, y: step_stats.transacted_amount.to_i}
    data.push datapoint
    datapoint = { x: t.to_i, y: step_stats.registered_users_count }
    data_users.push datapoint
    datapoint = { x: t.to_i, y: step_stats.active_users_count }
    data_active_users.push datapoint
    last_step_data = step_stats
    sleep 1
  end

  trade_series[:data] = data
  new_users_series[:data] = data_users
  active_users_series[:data] = data_active_users

  send_event("monthly_trade", series: [ trade_series ] )
  send_event("monthly_users", series: [ new_users_series ] )
  send_event("monthly_active_users", series: [ active_users_series ] )
  send_event("best_users", items: last_step_data.top_payers, unordered: false)
end
