require 'json'

class MetricsOnlyCellFactory < Java::javafx::scene::control::TreeCell
  include JRubyFX::DSL

  def initialize
    super

    # Create a context menu to show the raw object

    cm = Java::javafx::scene::control::ContextMenu.new
    cmi = Java::javafx::scene::control::MenuItem.new 'Show Raw'
    cmi.on_action do

      if item.respond_to? 'metric'

        item = tree_view.selectionModel.selectedItem
        text = JSON.pretty_generate(item.metric.to_h)

        stage = tree_view.scene.window
        ::HawkHelper.show_raw_popup stage, text
      end
    end
    cm.items.add cmi
    set_context_menu cm


    # Left-click action
    set_on_mouse_clicked do |event|
      puts "Got #{event.to_s}"
      source = event.source

      tree_view = source.treeView
      the_tree_item = tree_view.selectionModel.selectedItem

      puts "Selected #{the_tree_item.value}"
      break unless the_tree_item.respond_to? 'metric'

      # Write path in lower text field
      metric_def = the_tree_item.metric
      text = metric_def.id
      tree_view.scene.lookup('#FXMLtextArea').text = text

      # Add to items to be charted
      chart_control = tree_view.scene.lookup('#myChartView')
      chart_control.add_item metric_def
    end
  end

  def get_string
    get_item ? get_item.to_s : ''
  end

  def get_graphic
    get_item ? get_item.graphic : nil
  end

  # Does the actual cell rendering
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
end