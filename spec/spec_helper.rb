require 'rspec/core'
require 'rspec/matchers'

module MetricNode
  def get_metric_data(id, aggr)
    ret = []
    120.times do |i|
      dp = { start: 12340000 + i, avg: aggr == 'min' ? 7 : 42}
      ret << dp
    end
    ret
  end
end