require 'jrubyfx'

# Time picker widget that can be reused to select
# a time range. Clicking on a button will invoke
# a callback to pass the selected time range
# to come other controller
class TimePicker < Java::javafx::scene::layout::HBox
  include JRubyFX::Controller

  fxml 'TimePicker.fxml'

  def initialize(caller, callback)

    #load_fxml 'TimePicker.fxml'
    @caller = caller
    @callback = callback

    call_back 12*3600*1000 # 12h is default
  end

  def selectTime (event)

    button = event.source
    text = button.text

    case text
      when '1h'
        offset = 1
      when '8h'
        offset = 8
      when '12h'
        offset = 12
      when '1d'
        offset = 24
      when '7d'
        offset = 144
      when '1mo'
        offset = 30*24
    end
    offset_in_ms = offset * 3600 * 1000
    call_back(offset_in_ms)

  end

  def call_back(offset_in_ms)
    if @caller.respond_to?(@callback)
      op = @caller.public_method @callback
      op.call offset_in_ms
    end
  end
end