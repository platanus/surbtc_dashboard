module Exchange
  class StatsCollection
    attr_accessor :operations_count, :transacted_amount, :transacted_amount_btc, :earned_fee, :registered_users_count,
      :active_users_count, :top_payers, :deposited_volume, :withdrawn_volume, :funnel

    def top_payers
      (@top_payers || []).map do |payer_hash|
        { label: payer_hash["name"], value: payer_hash["total"] }
      end
    end
  end
end
