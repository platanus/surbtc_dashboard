require "active_support"
require "active_support/core_ext"

require 'logger'

SCHEDULER.every "10s", :first_in => 0 do
  
  trade_series = Hash.new
  new_users_series = Hash.new
  active_users_series = Hash.new

  # Generate series
  total = 12
  
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
  end

  trade_series[:data] = data
  new_users_series[:data] = data_users
  active_users_series[:data] = data_active_users

  send_event("monthly_trade", series: [ trade_series ] )
  send_event("monthly_users", series: [ new_users_series ] )
  send_event("monthly_active_users", series: [ active_users_series ] )
  #send_event("best_users", items: last_step_data.top_payers, unordered: false)

  current_growth = calculate_current_growth(trade_series[:data])
  last_growth = calculate_last_growth(trade_series[:data])
  avg_growth = calculate_avg_growth(trade_series[:data])

  send_event('growth_prev_month', { current: last_growth.round(2) })
  send_event('growth_current_month', { current: current_growth.round(2) })
  send_event('growth_avg_3_months', { current: avg_growth.round(2) })
end

def calculate_current_growth trade_series_data
  current_traded = trade_series_data[11][:y]
  last_traded = trade_series_data[10][:y]
  prop_traded = last_traded * (Time.now.to_i - Time.now.beginning_of_month.to_i).to_f /
    (Time.now.end_of_month.to_i - Time.now.beginning_of_month.to_i)
  100 * (current_traded - prop_traded).to_f / prop_traded
end

def calculate_last_growth trade_series_data
  last_traded = trade_series_data[10][:y]
  prev_last_traded = trade_series_data[9][:y]
  100 * (last_traded - prev_last_traded).to_f / prev_last_traded
end

def calculate_avg_growth trade_series_data
  growths = []
  (1..10).each do |i|
    last_traded = trade_series_data[i][:y]
    prev_last_traded = trade_series_data[i-1][:y]
    growths << (100 * (last_traded - prev_last_traded).to_f / prev_last_traded)
  end
  growths.inject{ |sum, el| sum + el }.to_f / growths.size # average
end
