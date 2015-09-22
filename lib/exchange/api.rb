require "dialers"
require_relative "./api_caller"

module Exchange
  class Api < Dialers::Wrapper
    api_caller { Exchange::ApiCaller.new }

    def get_stats(from, to)
      stats = api_caller.get("exchange_stats", from: from, to: to).transform_to_many(
        Exchange::SingleStat, root: "exchange_stats"
      )
      Exchange::StatsFactory.new(stats).build_collection
    end
  end
end
