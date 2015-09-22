module Exchange
  class StatsCollection
    attr_accessor :operations_count, :transacted_amount, :earned_fee, :registered_users_count,
      :active_users_count, :top_payers

    def top_payers
      (@top_payers || []).map do |payer_hash|
        { label: payer_hash["name"], value: payer_hash["total"] }
      end
    end
  end
end
