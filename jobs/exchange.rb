require "active_support"
require "active_support/core_ext"

require 'logger'

$logger = Logger.new(STDERR)

SCHEDULER.every "5m", :first_in => 0 do
  
  trade_series = Hash.new
  trade_series_clp = Hash.new
  trade_series_cop = Hash.new
  new_users_series = Hash.new
  new_users_series_clp = Hash.new
  new_users_series_cop = Hash.new
  active_users_series = Hash.new
  active_users_series_clp = Hash.new
  active_users_series_cop = Hash.new

  # Generate series
  total = 12
  
  data = []
  data_clp = []
  data_cop = []
  data_users = []
  data_users_clp = []
  data_users_cop = []
  data_active_users = []
  data_active_users_clp = []
  data_active_users_cop = []

  current_time = (Time.now - (total-1).months).beginning_of_month

  total.times do |i|
    exchange = Exchange::Api.new
    t = current_time.beginning_of_month
    t2 = current_time.end_of_month
    current_time = t2 + 1.day
    step_stats = exchange.get_stats(t, t2);

    datapoint = { x: t.to_i, y: step_stats.transacted_amount.to_i}
    $logger.info "datapoint transacted_amount  #{datapoint}"
    datapoint_clp = { x: t.to_i, y: step_stats.transacted_amount_clp.to_i}
    $logger.info "datapoint_clp transacted_amount_clp  #{datapoint_clp}"
    datapoint_cop = { x: t.to_i, y: step_stats.transacted_amount_cop.to_i}
    $logger.info "datapoint_cop transacted_amount_cop  #{datapoint_cop}"

    data.push datapoint
    data_clp.push datapoint_clp
    data_cop.push datapoint_cop

    datapoint = { x: t.to_i, y: step_stats.registered_users_count }
    datapoint_clp = { x: t.to_i, y: step_stats.registered_users_count_clp }
    datapoint_cop = { x: t.to_i, y: step_stats.registered_users_count_cop }
    $logger.info "datapoint_cop registered_users_count_cop  #{datapoint_cop}"

    data_users.push datapoint
    data_users_clp.push datapoint_clp
    data_users_cop.push datapoint_cop

    datapoint = { x: t.to_i, y: step_stats.active_users_count }
    datapoint_clp = { x: t.to_i, y: step_stats.active_users_count_clp }
    datapoint_cop = { x: t.to_i, y: step_stats.active_users_count_cop }

    data_active_users.push datapoint
    data_active_users_clp.push datapoint_clp
    data_active_users_cop.push datapoint_cop
  end

  trade_series[:data] = data
  trade_series_clp[:data] = data_clp
  trade_series_cop[:data] = data_cop

  new_users_series[:data] = data_users
  new_users_series_clp[:data] = data_users_clp
  new_users_series_cop[:data] = data_users_cop
  
  active_users_series[:data] = data_active_users
  active_users_series_clp[:data] = data_active_users_clp
  active_users_series_cop[:data] = data_active_users_cop

  send_event("monthly_trade", series: [ trade_series ] )
  send_event("monthly_trade_clp", series: [ trade_series_clp ] )
  send_event("monthly_trade_cop", series: [ trade_series_cop ] )
  
  send_event("monthly_users", series: [ new_users_series ] )
  send_event("monthly_users_clp", series: [ new_users_series_clp ] )
  send_event("monthly_users_cop", series: [ new_users_series_cop ] )

  send_event("monthly_active_users", series: [ active_users_series ] )
  send_event("monthly_active_users_clp", series: [ active_users_series_clp ] )
  send_event("monthly_active_users_cop", series: [ active_users_series_cop ] )

  current_growth = calculate_current_growth(trade_series[:data])
  current_growth_clp = calculate_current_growth(trade_series_clp[:data])
  current_growth_cop = calculate_current_growth(trade_series_cop[:data])

  last_growth = calculate_last_growth(trade_series[:data])
  last_growth_clp = calculate_last_growth(trade_series_clp[:data])
  last_growth_cop = calculate_last_growth(trade_series_cop[:data])

  avg_growth = calculate_avg_growth(trade_series[:data])
  avg_growth_clp = calculate_avg_growth(trade_series_clp[:data])
  avg_growth_cop = calculate_avg_growth(trade_series_cop[:data])

  send_event('growth_prev_month', { current: last_growth.round(2) })
  send_event('growth_prev_month_clp', { current: last_growth_clp.round(2) })
  send_event('growth_prev_month_cop', { current: last_growth_cop.round(2) })

  send_event('growth_current_month', { current: current_growth.round(2) })
  send_event('growth_current_month_clp', { current: current_growth_clp.round(2) })
  send_event('growth_current_month_cop', { current: current_growth_cop.round(2) })

  send_event('growth_avg_3_months', { current: avg_growth.round(2) })
  send_event('growth_avg_3_months_clp', { current: avg_growth_clp.round(2) })
  send_event('growth_avg_3_months_cop', { current: avg_growth_cop.round(2) })
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
  $logger.info "calculate_avg_growth calc start #{Time.now}"
  (1..10).each do |i|
    last_traded = trade_series_data[i][:y]
    prev_last_traded = trade_series_data[i-1][:y]
    v = (100 * (last_traded - prev_last_traded).to_f / prev_last_traded)
    $logger.info "#{i} value = #{v}"
    growths << v
  end
  $logger.info "calculate_avg_growth calc end #{Time.now}"
  growths.inject{ |sum, el| sum + el }.to_f / growths.size # average
end
