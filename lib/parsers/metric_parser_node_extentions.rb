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

  module ProgramNode
    def value(env)
      v.value env unless v.text_value.empty?
      e.value env unless e.text_value.empty?
    end
  end

  module ExpressionNode
    def value(env={})
      elements[1].value env
    end
  end

  module ArithmeticNode
    def value(env)
      operator = elements[0].text_value
      op1 = oper1.value env
      op2 = oper2.value env

      if op1.is_a? Array
        if op2.is_a? Array
          operate_arrays operator, op1, op2
        else
          operate_mixed operator, true, op1, op2
        end
      else # op1 is not an array
        if op2.is_a? Array
          operate_mixed operator, false, op1, op2
        else
          operate_scalar operator, op1, op2
        end
      end
    end

    def operate_mixed(operator, op2_is_scalar, op1, op2)
      return operate_mixed operator, true, op2, op1 unless op2_is_scalar

      ret = []
      (0..119).each { |i|
        dp = op1[i].dup
        dp[:avg] = operate_scalar operator, op2, dp[:avg]
        ret << dp
      }
      ret
    end

    def operate_arrays(operator, op1, op2)
      ret = []
      (0..119).each { |i|
        dp = op1[i].dup
        dp[:avg] = operate_scalar operator, dp[:avg], op2[i][:avg]
        ret << dp
      }
      ret
    end

    def operate_scalar(operator, op1, op2)

      return 0 unless op1 && op2 # TODO check for nil in both sides? Or skip empty buckets completely?

      case operator
      when '+'
        op1 + op2
      when '-'

        op1 - op2
      when '*'
        op1 * op2
      when '/'
        op1 / op2
      else
        raise Exception "Unknown operator #{operator}"
      end
    end
  end

  module SumUpNode
    def value(env)
      sum = 0
      value = operand.value env
      value.each {|dp| sum += dp[:avg]}
      sum
    end
  end

  module RateNode
    def value(env)
      previous = 0
      normalize = norm.text_value == 'true'
      value = operand.value env
      value.each do |dp|
        diff = dp[:avg] - previous
        previous = dp[:avg]
        t = normalize ? (dp[:end] - dp[:start])/1000 : 1
        dp[:avg] = diff / t
      end
      value
    end
  end

  module ToANode
    def value(env={})
      val = operand.value(env)
      ret = []
      diff = (env[:end]-env[:start]) / 120
      120.times do |i|
        dp = { start: env[:start] + i*diff, avg: val }
        ret << dp
      end
      ret

    end
  end

  module MetricNode
    def value(env={})
      m_val = metric_id.text_value
      mid = m_val.start_with?('$') ? metric_id.value(env) : metric_id.value
      aggr = aggregate.text_value

      get_metric_data(mid, aggr, env[:start], env[:end])
    end

  end

  module VarRef
    def value(env={})
      name = elements[1].text_value
      raise "Variable #{name} not found" if env.empty? || !env.key?(:vars) || !env[:vars].key?(name)
      env[:vars][name]
    end
  end


  module VarDefinition
    def value(env={})
      name = elements[1].text_value
      val = elements[5].value env
      env[:vars] ||= {}
      env[:vars][name] = val
    end
  end

  module VarsDefinition
    def value(env={})
      elements.each do |e|
        unless e.empty? || e.elements.first.text_value.strip.empty?
          if e.elements.first.terminal?
            e.value env
          else
            e.elements.first.elements.last.value env
          end
        end
      end
    end
  end