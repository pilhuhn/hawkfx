require 'json'
require_relative 'hawk'
require_relative 'chart_view_controller'
require_relative 'metric_expression_parser'

class AddSynthMetricController
  include JRubyFX::Controller
  fxml 'synthetic_metric.fxml'

  def initialize
  end

  def parent= (parent)
    @my_parent = parent
  end

  def submit

    name = @name.text

    s_m_hash = {
        'id' => @formula.text,
        'name' => name,
        'type' => {
            'type' => 'SYNTHETIC'
        }

    }
    s_m = ::Hawkular::Inventory::Metric.new s_m_hash

    chart_view = @my_parent.scene.lookup('#myChartView')
    chart_view.add_remove_item s_m

    @stage.close
  end

  def parse

    formula = @formula.text

    begin
      MetricExpressionParser.parse(formula)
    rescue Exception => e
      @errors.text = e.to_s
      @submit_button.disable=true
      return
    end

    @errors.text = ''
    @submit_button.disable=false
  end
end
