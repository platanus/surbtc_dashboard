module Exchange
  class StatsFactory
    def initialize(single_stats, stats_collection = StatsCollection.new)
      self.single_stats = single_stats
      self.stats_collection = stats_collection
    end

    def build_collection
      single_stats.each do |stat|
        setter = "#{stat.id}="
        if stats_collection.respond_to?(setter)
          stats_collection.public_send(setter, stat.value)
        end
      end
      stats_collection
    end

    private

    attr_accessor :single_stats, :stats_collection
  end
end
