require 'json'
require_relative 'hawk'

class RunOperationController
  include JRubyFX::Controller
  fxml 'run_operation.fxml'

  def initialize
    @fields = {}
  end

  def setup(operation, resource_path)
    return if operation.nil?

    @operation_name = operation.name
    @params = operation.params
    @resource_path = resource_path

    row = 0
    @params.each do |p|
      name = p[0]
      param = p[1]
      type = param['type']
      descr = param['description']
      default_val = param['defaultValue'] || param['default-value'] # TODO: this will change in the agent

      label = create_label(name, param)
      @the_grid.add label, 0, row

      unless descr.nil? || descr.empty?
        label = label descr
        @the_grid.add label, 2, row
      end

      field = create_input_field(default_val, type)

      @fields[name] = field
      @the_grid.add field, 1, row
      row += 1
    end
  end

  def create_label(name, param)
    label_text = "#{name}"
    required = param['required']
    label_text << ' (required)' if required unless required.nil?

    label label_text
  end

  def create_input_field(default_val, type)
    case type
    when 'number', 'string', 'int', 'float'
      field = text_field # TODO: add validation binding
      field.text = default_val unless default_val.nil?
    when 'bool'
      field = check_box
      field.selected = (default_val == 'false') unless default_val.nil?
    else
      fail 'Unknown type'
    end
    field
  end

  def cancel
    @stage.close
  end

  def submit
    ps = {}

    @fields.each do |name, field|
      param = @params[name]
      val = case param['type']
            when 'int', 'number'
              field.text.to_i
            when 'float'
              field.text.to_f
            when 'string'
              field.text
            when 'bool'
              field.selected
            else
              fail "unknown type #{param[type]}"
            end
      ps[name] = val
    end

    the_operation = {
      :resourcePath => @resource_path,
      :operationName => @operation_name,
      :parameters => ps
    }

    Hawk.operations.invoke_generic_operation the_operation do |on|
      on.success do |data|
        msg = "Success on websocket-operation #{data}"
        puts msg
        @output_field.text = JSON.pretty_generate(data.to_h)
      end
      on.failure do |error|
        msg = 'error callback was called, reason: ' + error.to_s
        puts msg
        @output_field.text = msg
      end
    end
  end
end
