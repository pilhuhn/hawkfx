require 'hawkular/hawkular_client'

module DefineNode

  def value(env = {})
    t = Hawkular::Alerts::Trigger.new({})
    t.name = name.value env
    t.id = t.id = "trigger_#{Time.now.to_i}"
    t.enabled = !enabled.empty?
    t.id = id.value env unless id.empty?
    t.auto_disable = true unless ad.empty?
    t.auto_enable = true unless ae.empty?

    env[:trigger] = t
    env[:conditions] = []

    # Evaluate conditions
    cond.value env


  end
end

module ConditionNode
  def value(env = {})
    c = Hawkular::Alerts::Trigger::Condition.new({})
    c.trigger_mode = :FIRING # default

    mode.value env, c

    env[:conditions] << c
  end
end

module ThresholdNode
  def value(env = {}, cond)
    puts 'TH'
    cond.type = :THRESHOLD
    cond.data_id = metric.value env
    cond.operator =
        case comp.text_value
        when '<'
          :LT
        when '>'
          :GT
        when '='
          :EQ
        when '<>'
          :NE
        when '<='
          :LE
        when '=>'
          :GE
        end
    cond.threshold = ref.value(env)
  end
end

module AvailabilityNode
  def value(env = {}, cond)
    puts 'AV'
    cond.type = :AVAILABILITY
    cond.data_id = metric.value env
    cond.operator = ref.text_value
  end

end

module IntegerLiteral
  def value(_env)
    elements[1].text_value.to_i
  end
end

module FloatLiteral
  def value(_env)
    elements[1].text_value.to_f + elements[2].text_value.to_f
  end
end
