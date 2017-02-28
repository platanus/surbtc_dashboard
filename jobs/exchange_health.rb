require 'redis'
require 'json'
require 'pry'

REDIS_CLIENT = Redis.new(:host => "10.142.0.2", :port => 6800)
#pry.binding 

#=> {"indices"=>
#  {"indice salud libro ventas"=>[0.019391562021384492, 0.028424405995982796, 0.45030146019650025],
#   "volumen promedio transaccion venta"=>0.08457726789473684,
#   "spread relativo"=>0.020392270413794596,
#   "volumen promedio transaccion compra"=>0.19668056740740741,
#   "indice salud libro compras"=>[5.28677630773884e-18, 0.007945196266723159, 0.03450268015850241],
#   "spread"=>16339.09350358881},
# "timestamp"=>1488229775.9188848,
# "exchange"=>"surbtc"}


SCHEDULER.every '1m', :first_in => 1 do
  redis = REDIS_CLIENT

  result = JSON.parse(redis.zrange("surbtc",-1,-1).first)
  # Send the events
  send_event('surbtc_hindex_relative_spread', { current: (result["indices"]["spread relativo"]*100).round(2) })

  send_event('surbtc_hindex_bids0', { current: (result["indices"]["indice salud libro compras"][0]*100).round(2) })
  send_event('surbtc_hindex_bids1', { current: (result["indices"]["indice salud libro compras"][1]*100).round(2) })
  send_event('surbtc_hindex_bids2', { current: (result["indices"]["indice salud libro compras"][2]*100).round(2) })
  send_event('surbtc_hindex_asks0', { current: (result["indices"]["indice salud libro ventas"][0]*100).round(2) })
  send_event('surbtc_hindex_asks1', { current: (result["indices"]["indice salud libro ventas"][1]*100).round(2) })
  send_event('surbtc_hindex_asks2', { current: (result["indices"]["indice salud libro ventas"][2]*100).round(2) })

end
