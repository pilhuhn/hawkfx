require 'json'
require_relative 'hawk'
require_relative 'parsers/alert_definition_parser'

class AddTriggerController
  include JRubyFX::Controller
  fxml 'synthetic_metric.fxml'

  def initialize
    @name.disable = true
    @title.text = 'Add a trigger definition'
  end

  def parent= (parent)
    @my_parent = parent
  end

  def text= (msg)
    return if msg.nil? || msg.empty?
    @formula.text = msg
  end

  def submit

    env = AlertDefinitionParser.parse(@formula.text)

    begin
      Hawk.alerts.delete_trigger t.id
    rescue
      puts 'Trigger did not yet exist'
    end

    begin
      env[:actionDefs].each do |acdef|
        Hawk.alerts.create_action acdef[:plugin], acdef[:id], 'to' => acdef[:to]
      end

      Hawk.alerts.create_trigger env[:trigger], env[:conditions], nil, env[:actions]
      puts 'Trigger created'
    rescue Exception => e
      puts 'Trigger creation failed : ' + e.to_s
      raise e
    end


    @stage.close
  end

  def parse

    formula = @formula.text

    begin
      AlertDefinitionParser.parse(formula)
    rescue Exception => e
      @errors.text = e.to_s
      @submit_button.disable=true
      return
    end

    @errors.text = ''
    @submit_button.disable=false
  end
end
