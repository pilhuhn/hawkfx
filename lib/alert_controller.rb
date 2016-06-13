require 'hawkular/hawkular_client'

require_relative 'alert_list_cell_factory'
require_relative 'alert_list_item'
require_relative 'time_picker'

class AlertController
  include JRubyFX::Controller
  fxml 'fxalerts.fxml'

  def initialize
    box = find '#alertEventTopBox'
    box.children.add time_picker(self, :set_time_range)

    @FXMLalertList.cell_factory = proc { ::AlertListCellFactory.new }

    display_items
  end

  # Callback from Alert/Event toggle
  def switchAlertEvent
    # TODO clean out selected item details
    display_items
  end

  # Callback from time picker
  def set_time_range(time_in_ms)
    @start_offset = time_in_ms
    display_items
  end

  private

  def display_items
    start = Time.now.to_i * 1000 - @start_offset
    alerts_selected = @FXMLAlertEventSelector.selected

    if alerts_selected
      alerts = $alerts_client.list_alerts 'startTime' => start
    else
      alerts = $alerts_client.list_events 'startTime' => start
    end

    the_list = observable_array_list []
    alerts.each do |alert|
      item = AlertListItem.new
      item.alert = alert
      the_list.add item

    end
    @FXMLalertList.items=the_list
  end


end