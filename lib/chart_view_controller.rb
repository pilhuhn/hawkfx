require 'jrubyfx'
require 'set'
require_relative 'metric_expression_parser'

class ChartViewController < Java::javafx::scene::layout::VBox
  include JRubyFX::Controller

  fxml 'ChartView.fxml'

  def initialize
    @chart_items = Set.new
    @chosen_range = 12 * 3600 * 1000
    @FXMLChart.axis_sorting_policy = LineChart::SortingPolicy::X_AXIS
  end

  # Add item when it is not yet there, remove otherwise
  # refresh the chart afterwards.
  def add_remove_item(item)
    if @chart_items.include? item
      @chart_items.delete(item)
    else
      @chart_items << item
    end
    refresh_charts
  end

  def clear
    @chart_items = Set.new
    refresh_charts
  end

  def change_time(start_time_ms)
    @chosen_range = start_time_ms
    refresh_charts
  end

  # do the real drawing
  def refresh_charts
    if @chart_items.empty?
      @FXMLChart.visible = false
      return
    end

    ends = Time.now.to_i * 1000
    starts = ends - @chosen_range
    the_chart = @FXMLChart
    the_chart.visible = true

    series_array = []

    @chart_items.each do |metric|
      series = xy_chart_series(name: metric.name)

      if metric.type == 'SYNTHETIC'
        # metric is a hawkular inventory Metric object

        data = compute metric, starts, ends

      else

          # if there is a metric-id property, use that as the ID, otherwise, use the instance ID itself
        id = "#{metric.properties['hawkular-metric-id']}"
        if id.to_s == ''
          puts 'Assuming the metric ID is the same as the inventory ID'
          id = metric.id
        end
        puts "Using ID [#{id}] for metric [#{metric.name}]"

        ep = ::HawkHelper.metric_endpoint metric
        data = ep.get_data id, buckets: 120, ends: ends, starts: starts
        h_metric_def = ep.get id

        puts "Metric [#{id}] tags: #{h_metric_def.tags}"
      end

      # if our data has holes, check if it is only the first one
      # and if so copy its value from the 2nd
      if data[0]['empty'] && !data[1]['empty']
        previous_value = data[1]['max']
      else
        previous_value = 0
      end


      data.each do |item|
        next if item.nil?

        # If the item is empty, just use the previous value
        # This can happen when there are more buckets than
        # raw data items for a time span (e.g. bucket is 30s long)
        # but we collect only every minute
        # Or when 7 days of data is requested and only 1 is recorded
        if item['empty']
          item['max'] = previous_value
        else
          previous_value = item['max']
        end


        ts = item['start'] / 1000 # buckets -> start || timestamp for raw
        time = Time.at(ts).to_s
        val = item['max'] # buckets -> avg(?) || value for raw
        series.data.add xy_chart_data time, val
      end

      series_array << series
    end

    the_chart.data.setAll series_array
  end


  def compute(inventory_metric, starts, ends)

    env = {}
    env[:start] = starts
    env[:end] = ends
    MetricExpressionParser.parse(inventory_metric.id, env)

  end

end

# Helper called from the parser
module MetricNode
  def get_metric_data(mid, aggr, starttime, endtime)
    data = Hawk.metrics.gauges.get_data mid, buckets: 120, starts: starttime, ends: endtime

    # Map the requested aggregate onto avg, as this is what is used later to graph
    data.each {|dp| dp['avg'] = dp[aggr]}
  end
end

