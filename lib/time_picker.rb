require 'jrubyfx'

# Time picker widget that can be reused to select
# a time range. Clicking on a button will invoke
# a callback to pass the selected time range
# to come other controller
class TimePicker < Java::javafx::scene::layout::HBox
  include JRubyFX::Controller

  fxml 'TimePicker.fxml'

  def initialize(caller, callback)
    @caller = caller
    @callback = callback

    call_back 12 * 3600 * 1000 # 12h is default
  end

  # Callback from JavaFX when one of the buttons is pressed
  def select_time(event)
    button = event.source
    text = button.text

    case text
    when '30min'
      offset = 1
    when '1h'
      offset = 2
    when '8h'
      offset = 16
    when '12h'
      offset = 24
    when '1d'
      offset = 48
    when '7d'
      offset = 288
    when '1mo'
      offset = 60 * 24
    else
      offset = 24 # this is the default
    end
    offset_in_ms = offset * 1800 * 1000
    call_back(offset_in_ms)
  end

  def call_back(offset_in_ms)
    return unless @caller.respond_to?(@callback)
    op = @caller.public_method @callback
    op.call offset_in_ms
  end
end
