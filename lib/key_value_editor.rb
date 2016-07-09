require 'jrubyfx'

class KeyValueEditor
  include JRubyFX::Controller
  fxml 'KeyValueEnter.fxml'


  # @param [Object] caller The object that should be called back after submit. Ususally the caller
  # @param [Object] callback The callback method to be called on caller.
  # @param [Object] other_stuff Other stuff that will be passed to the callback as 2nd .. param
  def setup(caller, callback, *other_stuff)
    @caller = caller
    @callback = callback
    @other_stuff = other_stuff
    setup_validation
  end

  def setup_validation
    @key_field.text_property.add_change_listener do |obs, ovalue, newvalue|
      validate_input
    end

    @value_field.text_property.add_change_listener do |obs, ovalue, newvalue|
      validate_input
    end
  end

  def validate_input
    if @key_field.text.empty? || @value_field.text.empty?
      @submit_button.disabled = true
    else
      @submit_button.disabled = false
    end
  end


  def submit
    key = @key_field.text
    value = @value_field.text

    ret = { :key => key,
            :value => value}

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