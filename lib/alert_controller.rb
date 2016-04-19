require 'hawkular_all'

require_relative 'alert_list_cell_factory'
require_relative 'alert_list_item'

class AlertController
  include JRubyFX::Controller
  fxml 'fxalerts.fxml'

  def initialize

    @FXMLalertList.cell_factory = proc { ::AlertListCellFactory.new }

    start = (Time.now.to_i  - 86400) *1000  # last day # TODO use ruby time artihmetic

    alerts = $alerts_client.list_alerts 'startTime' => start

    the_list = observable_array_list []
    alerts.each do |alert|
      item = AlertListItem.new
      item.alert = alert
      the_list.add item

    end
    @FXMLalertList.items=the_list
  end
end