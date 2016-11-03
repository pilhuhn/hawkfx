module Hawk
  class << self
    attr_accessor :client, :mode, :remote_info

    def metrics=(metrics_client)
      @metrics = metrics_client
    end

    def metrics
      @mode == :hawkular ? @client.metrics : @metrics
    end

    def inventory
      @client.inventory
    end

    def alerts=(alerts_client)
      @alerts = alerts_client
    end

    def alerts
      @mode == :hawkular ? @client.alerts : @alerts
    end

    def operations
      @client.operations
    end
  end
end
