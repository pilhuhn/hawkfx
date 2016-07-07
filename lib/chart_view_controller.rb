require 'jrubyfx'
require 'set'

class ChartViewController < Java::javafx::scene::layout::VBox
  include JRubyFX::Controller

  fxml 'ChartView.fxml'


  def initialize
    @chart_items = Set.new
    @chosen_range = 12 * 3600 * 1000
  end

  def add_item(item)
    @chart_items << item
    refreshCharts
  end

  def clear
    @chart_items = Set.new
    refreshCharts
  end

  def change_time(start_time_ms)
    @chosen_range = start_time_ms
    refreshCharts
  end

  # do the real drawing
  def refreshCharts

    if @chart_items.empty?
      @FXMLChart.visible = false
      return
    end

    ends = Time.now.to_i * 1000
    starts = ends-@chosen_range
    the_chart = @FXMLChart
    the_chart.visible = true

    series_array = []

    @chart_items.each do |metric|
      series = xy_chart_series(name: metric.name)
      type = metric.type

      # if there is a metric-id property, use that as the ID, otherwise, use the instance ID itself
      id = "#{metric.properties['metric-id']}"
      if id.to_s == ''
         puts "Assuming the metric ID is the same as the inventory ID"
         id = metric.id
      end
      puts "Using ID [#{id}] for metric [#{metric.name}]"

      case type
        when 'GAUGE'
          data = $metric_client.gauges.get_data id, buckets: 120, ends: ends, starts: starts
        when 'COUNTER'
          data = $metric_client.counters.get_data id, buckets: 120, ends: ends, starts: starts
        else
          puts "Data Type #{type} is not known"
          return
      end

      data.each do |item|
        unless item.nil? || item['empty']
          ts = item['start'] / 1000 # buckets -> start || timestamp for raw
          time = Time.at(ts).to_s
          val = item['avg'] # buckets -> avg(?) || value for raw
          series.data.add xy_chart_data time, val
        end
      end

      # the_chart.data.remove series # TODO don't re-add existing - rather replace
      # the_chart.data.add series # TODO don't re-add existing - rather replace
      series_array << series

    end

    the_chart.data.setAll series_array
  end

end
