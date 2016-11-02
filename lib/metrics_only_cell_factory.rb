require 'json'
require_relative 'create_trigger_menu_mixin'
require_relative 'metric_tag_mixin'

class MetricsOnlyCellFactory < Java::javafx::scene::control::TreeCell
  include JRubyFX::DSL
  include CreateTriggerMenuMixin
  include MetricTagMixin

  def initialize
    super

    # Create a context menu to show the raw object

    cm = Java::javafx::scene::control::ContextMenu.new
    cmi = Java::javafx::scene::control::MenuItem.new 'Show Raw'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      text = JSON.pretty_generate(item.raw_item.to_h)

      stage = tree_view.scene.window
      ::HawkHelper.show_raw_popup stage, text
    end
    cm.items.add cmi

    # Context menu to add alert triggers
    cmi = create_metric_alert_item
    cm.items.add cmi

    # Context menu to add tags on metrics
    cmi = create_metric_tag_menu_item
    cm.items.add cmi

    # Context menu to show tags on metrics
    cmi = show_metric_tag_menu_item
    cm.items.add cmi

    set_context_menu cm

    # Left-click action
    set_on_mouse_clicked do |event|
      source = event.source

      tree_view = source.treeView
      the_tree_item = tree_view.selectionModel.selectedItem

      puts "Selected #{the_tree_item.value} -> #{the_tree_item.kind}"
      break unless the_tree_item.kind == :metric

      # Write path (=ID in metrics only mode) in lower text field
      metric_def = the_tree_item.raw_item
      text = metric_def.id
      tree_view.scene.lookup('#FXMLtextArea').text = text

      # Also write this in the ID field
      tree_view.scene.lookup('#FXMLidField').text = text

      # Add to items to be charted
      chart_control = tree_view.scene.lookup('#myChartView')
      chart_control.add_remove_item metric_def
    end
  end

  # rubocop: disable Style/AccessorMethodName
  def get_string
    get_item ? get_item.to_s : ''
  end

  def get_graphic
    get_item ? get_item.graphic : nil
  end
  # rubocop: enable Style/AccessorMethodName

  # Does the actual cell rendering
  # rubocop: disable Style/MethodName
  def updateItem(item, empty)
    super item, empty

    if empty
      set_text nil
      set_graphic nil
    else
      set_text get_string
      set_graphic tree_item.graphic
    end
  end
  # rubocop: enable Style/MethodName
end
