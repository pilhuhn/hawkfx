require 'jrubyfx'

class AvailabilityDisplayController
  include JRubyFX::Controller
  fxml 'fxavailability.fxml'

  def show_availability(id, time_range)

    ends = Time.now.to_i * 1000
    starts = ends - time_range

    data = $metric_client.avail.get_data id, ends: ends, starts: starts, order: 'ASC'

    series = xy_chart_series(name: id)

    first = true
    vals = {}
    previous = starts

    data.each do |item|
      unless item.nil? || item['empty']
        ts = item['timestamp'] / 1000
        time = Time.at(ts).to_s.split(' ')[1]
        tmp = item['value']
        val = case tmp
                when 'up'
                  3
                when 'unknown'
                  2
                when 'admin'
                  1
                when 'down'
                  0
                else
                  puts 'Unknown availability ' + tmp
                  5
              end
        series.data.add xy_chart_data time, val

        # now compute time per value
        unless first
          t_diff = ts - previous
          vals[tmp] ||= 0
          vals[tmp] += t_diff
        end
        if first
          previous = ts
          first = false
        end

      end
    end
    @line_chart.data.setAll series

    vals.each{|k, v| puts "#{k} -> #{v}" }

    pie_chart_d = []
    vals.each do |k, v|
      pcd = Java::javafx.scene.chart.PieChart::Data.new k, v
      pie_chart_d << pcd
    end
    o_list = observable_array_list pie_chart_d
    @pie_chart.data= o_list

  end
end