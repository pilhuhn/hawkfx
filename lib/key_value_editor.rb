require 'jrubyfx'

class KeyValueEditor
  include JRubyFX::Controller
  fxml 'KeyValueEnter.fxml'

  def initialize
    key_field_empty = @key_field.text_property.is_empty
    value_field_empty = @value_field.text_property.is_empty
    input_invalid = key_field_empty.or(value_field_empty)
    @submit_button.disable_property.bind input_invalid
  end

  # @param [Object] caller The object that should be called back after submit. Ususally the caller
  # @param [Object] callback The callback method to be called on caller.
  # @param [Object] other_stuff Other stuff that will be passed to the callback as 2nd .. param
  def setup(caller, callback, *other_stuff)
    @caller = caller
    @callback = callback
    @other_stuff = other_stuff
  end

  def submit
    key = @key_field.text
    value = @value_field.text

    ret = { :key => key,
            :value => value
          }

    if @caller.respond_to?(@callback)
      op = @caller.public_method @callback
      op.call ret, *@other_stuff
    end

    @stage.close
  end

  def cancel
    @stage.close
  end
end
