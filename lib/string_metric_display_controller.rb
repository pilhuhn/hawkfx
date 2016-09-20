require 'jrubyfx'
require_relative 'time_picker'

class StringMetricDisplayController
  include JRubyFX::Controller
  fxml 'fx_string_list.fxml'

  def initialize
    # box = @timePickerBox
    # box.children.add time_picker(self, :update_time_range)

    @start_offset = 86400*1000 if @start_offset.nil?
  end

  def show_string(id)
    @id = id
    display_items
  end

  def display_items
    return if @id.nil?

    ends = Time.now.to_i * 1000
    starts = ends - @start_offset

    # [ { timestamp, value} ]
    data = Hawk.metrics.strings.get_data @id, ends: ends, starts: starts, order: 'ASC'



    item_list = observable_array_list []
    data.each do |item|
      ts = item['timestamp'] / 1000
      time = Time.at(ts).to_s
      line = time + ' : ' + item['value']
      item_list.add line
    end
    @FXList.items = item_list
  end

  # Callback from time picker
  def update_time_range(time_in_ms)
    @start_offset = time_in_ms
    display_items unless @id.nil?
  end
end
