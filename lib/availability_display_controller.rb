require 'jrubyfx'

class AvailabilityDisplayController
  include JRubyFX::Controller
  fxml 'fxavailability.fxml'

  def show_availability(id, time_range)

    # Add a stylesheet for our data
    @scene.stylesheets.add 'assets/avail_chart.css'

    ends = Time.now.to_i * 1000
    starts = ends - time_range

    data = $metric_client.avail.get_data id, ends: ends, starts: starts, order: 'ASC', distinct: true

    series = xy_chart_series(name: id)

    first = true
    vals = {}
    previous = starts

    data.each do |item|
      unless item.nil? || item['empty']
        ts = item['timestamp'] / 1000
        time = Time.at(ts).to_s.split(' ')[1]
        value = item['value']
        series.data.add xy_chart_data time, value

        # now compute time per value
        unless first
          t_diff = ts - previous
          vals[value] ||= 0
          vals[value] += t_diff
        end
        if first
          previous = ts
          first = false
        end

      end
    end

    # Show the line chart
    categories = observable_array_list %w(down admin unknown up)
    @line_chart.getYAxis.categories=categories
    @line_chart.data.setAll series


    bucket_data = $metric_client.avail.get_data id, ends: ends, starts: starts, buckets: 1
    the_vals = bucket_data[0]['durationMap']

    the_vals.each do |k,v|
      puts "#{k} -> #{v}"
    end

    two_percent = time_range / 50

    pie_chart_d = []
    tmp_hash = {}
    the_vals.each do |k, v|
      val = v < two_percent ? two_percent : v
      key = k.sub(/.*text=/,'').sub(/}/,'')
      tmp_hash.store key,val
    end

    categories.each do |k,v|
      if tmp_hash.key? k
        val = tmp_hash.fetch k
      else
        val = 0
      end
        pcd = Java::javafx.scene.chart.PieChart::Data.new k, val
        pie_chart_d << pcd
    end
    o_list = observable_array_list pie_chart_d
    @pie_chart.data= o_list

  end
end