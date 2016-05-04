require 'jrubyfx'
require 'jrubyfx-fxmlloader'
require 'hawkular_all'

require_relative 'hawk_helper'
require_relative 'h_tree_item'
require_relative 'alert_controller'
require_relative 'on_click_cell_factory'
require_relative 'time_picker'
require_relative 'chart_view_controller'

class HawkMainController
  include JRubyFX::Controller
  fxml 'fxmain.fxml'


  def show_initial_tree(feeds)

    # First load the chart custom control
    chart_anchor = @FXMLtreeView.scene.lookup('#FXMLChartAnchor')
    chart_anchor.children.add chart_view_controller # TODO rename back to chart_view?

    # Then load the time picker custom control
    # This needs to go after the chart as it will immediately call back
    hbox = @FXMLtreeView.scene.lookup('#FXMLTopBox')
    hbox.children.add time_picker(self, :set_time_range)

    @FXMLtreeView.setCellFactory proc { ::OnClickCellFactory.new }

    tree_root = tree_item('Feeds')
    feeds.each do |feed|
      iv = ::HawkHelper.create_icon 'F'

      new_feed = build(::HTreeItem)
      new_feed.kind = :feed
      new_feed.value = feed
      new_feed.graphic = iv

      tree_root.children.add new_feed
      puts new_feed.to_s
    end
    # bind to the view from fxml
    @FXMLtreeView.setRoot(tree_root)

    tree_root.expanded=true
  end

  # Load the alerts window
  def show_alerts
    popup_stage = Stage.new
    ::AlertController.load_into popup_stage
    popup_stage.title='Alerts & Definitions'
    popup_stage.init_modality=:none
    popup_stage.init_owner(@FXMLtreeView.scene.window)
    popup_stage.show
  end

  # Callback from time picker
  def set_time_range(time_in_ms)
    cv = find('#myChartView')
    cv.change_time time_in_ms
  end
end