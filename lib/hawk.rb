module Hawk
  class << self
    attr_accessor :client

    def metrics
      @client.metrics
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
