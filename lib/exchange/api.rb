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
    def get_admin_stats
      stats = api_caller.get("exchange_stats/admin").transform_to_many(
        Exchange::SingleStat, root: "admin_stats"
      )
      Exchange::StatsFactory.new(stats, AdminStatsCollection.new).build_collection
    end
    def get_users_stats
      stats = api_caller.get("exchange_stats/users").transform_to_many(
        Exchange::SingleStat, root: "users_stats"
      )
      Exchange::StatsFactory.new(stats, UsersStatsCollection.new).build_collection
    end
    def get_growth_stats
      stats = api_caller.get("exchange_stats/growth").transform_to_many(
        Exchange::SingleStat, root: "growth_stats"
      )
      Exchange::StatsFactory.new(stats, GrowthStatsCollection.new).build_collection 
    end
  end
end
