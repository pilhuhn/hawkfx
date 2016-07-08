require 'hawkular/hawkular_client'


class InsertMetricsController
  include JRubyFX::Controller
  fxml 'insert_metrics.fxml'


  def submit_metric_value
    tg = @insert_mode_group
    name = @name_field.text
    value = @value_field.text
    type_sym = tg.selectedToggle.id.to_sym

    unless @tag_key_field.text.empty?
      tag = {@tag_key_field.text => @tag_value_field.text}
    end

    val = [
        { :id => name,
          :data => [
            {:value => value,
             :timestamp => Time.now().to_i*1000
            }
          ],
          :tags => tag
        }
    ]

    $metric_client.push_data type_sym => val

  end

end