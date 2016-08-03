module Hawk
  class << self
    attr_accessor :client, :mode

    def metrics=(metrics_client)
      @metrics = metrics_client
    end

    def metrics
      @mode == :hawkular ? @client.metrics : @metrics
    end

    def inventory
      @client.inventory
    end

    def alerts
      @client.alerts
    end

    def operations
      @client.operations
    end
  end
end
