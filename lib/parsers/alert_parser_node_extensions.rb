require 'hawkular/hawkular_client'

module DefineNode

  def value(env = {})
    t = Hawkular::Alerts::Trigger.new({})
    t.name = name.value env
    t.id = t.id = "trigger_#{Time.now.to_i}"
    t.enabled = true if disabled.empty?
    t.id = id.value env unless id.empty?
    t.auto_disable = true unless ad.empty?
    t.auto_enable = true unless ae.empty?
    t.severity = sev.empty? ? 'MEDIUM' : (sev.value env)

    env[:trigger] = t
    env[:conditions] = []
    env[:actions] = []
    env[:actionDefs] = []
    env[:tid] = t.id

    # Evaluate conditions
    conditions.value env

    # And actions
    act.value env unless act.empty?


  end
end

module ConditionsNode
  def value(env = {})
    puts 'Conditions'
    conds.value env
  end
end

module  AndConditionNode
  def value(env = {})
    puts "And"
    first.value env
    more.elements.each {|elem| elem.condition.value env}
    env[:trigger].firing_match = :ALL
  end
end

module  OrConditionNode
  def value(env = {})
    puts 'OrNode'
    first.value env
    more.elements.each {|elem| elem.condition.value env}
    env[:trigger].firing_match = :ANY
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
    prefix = mt.empty? ? 'hm_g' : (mt.value env)
    cond.data_id = "#{prefix}_#{metric.value env}"
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
    cond.data_id = "hm_a_#{metric.value env}"
    cond.operator = ref.text_value
  end
end

module StringConditionNode
  def value(env = {}, cond)
    cond.type = :STRING
    cond.data_id = "hm_s_#{metric.value env}"
    cond.operator = case comp.text_value
                    when 'equals'
                      :EQUAL
                    when 'notEquals'
                      :NOT_EQUAL
                    when 'startsWith'
                      :STARTS_WITH
                    when 'endsWith'
                      :ENDS_WITH
                    when 'contains'
                      :CONTAINS
                    when 'matches'
                      :MATCH
                    end
    cond.threshold = ref.value env # TODO what is the correct field?
  end
end

module MetricTypeNode
  # The prefixes are:
  #
  # hm_a: availability
  # hm_c: counter
  # hm_cr: counter rate
  # hm_g: gauge
  # hm_gr: gauge rate
  # hm_s: string
  def value(env = {})
    case text_value
    when 'gauge'
      'hm_g'
    when 'counter'
      'hm_c'
    when 'gauge rate'
      'hm_gr'
    when 'counter rate'
      'hm_cr'
    when 'string'
      'hm_s'
    when 'avail'
      'hm_a'
    end
  end
end

module ActionNode
  def value(env = {} )
    a = Hawkular::Alerts::Trigger::Action.new({})

    act.value env, a

    env[:actions] << a
  end

end

module EmailNode
  def value(env={}, action)

    env[:actionDefs] <<
      {
        :plugin => :email,
        :to => rec.value(env),
        :id => "action-email-#{env[:tid]}"

      }
    action.action_plugin = :email
    action.action_id = "action-email-#{env[:tid]}"
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
