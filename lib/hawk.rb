module Hawk
  class << self
    attr_accessor :client
    # TODO: can we deduct the following here from :client?
    attr_accessor :metrics, :inventory, :alerts, :operations
  end
end
