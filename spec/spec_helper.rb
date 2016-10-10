require 'rspec/core'
require 'rspec/matchers'

module MetricNode
  def get_metric_data(id, aggr, starts, ends)
  ret = []
  diff = (ends-starts) / 120

  120.times do |i|
    dp = { start: starts + i*diff,
           end: starts + (i+1)*diff,
           avg: aggr == 'min' ? 7 : 42}
    ret << dp
  end
  ret
end
end