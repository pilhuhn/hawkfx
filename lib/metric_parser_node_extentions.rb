  module IntegerLiteral
    def value
      elements[1].text_value.to_i
    end
  end

  module StringLiteral
  end

  module FloatLiteral
    def value
      elements[1].text_value.to_f + elements[2].text_value.to_f
    end
  end

  module ExpressionNode
    def value
      elements[1].value
    end
  end

  module BodyNode
    def value
      # elements.each do |exp|
      #   ret = exp.value
      # end
      # ret
      elements[2].value
    end
  end


  module ArithmeticNode
    def value
      operator = elements[0].text_value
      op1 = oper1.value
      op2 = oper2.value

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
    def value
      sum = 0
      value = operand.value
      value.each {|dp| sum += dp[:avg]}
      sum
    end
  end

  module ToANode
    def value
      val = operand.value
      ret = []
      120.times do |i|
        dp = { start: 12340000 + i, avg: val } # TODO timestamps
        ret << dp
      end
      ret

    end
  end

  module MetricNode
    def value
      mid = metric_id.value
      aggr = aggregate.value

      get_metric_data(mid, aggr)
    end


  end