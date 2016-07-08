require 'json'

class OnClickCellFactory < Java::javafx::scene::control::TreeCell
  include JRubyFX::DSL

  def initialize
    super

    # Create a context menu to show the raw object
    cm = Java::javafx::scene::control::ContextMenu.new
    cmi = show_raw_menu_item
    cm.items.add cmi

    # Context menu to show properties.
    # TODO: do not show for non-resources
    cmi = create_properties_menu_item
    cm.items.add cmi

    set_context_menu cm


    # Left-click action
    set_on_mouse_clicked do |event|
      puts "Got #{event.to_s}"
      source = event.source

      tree_view = source.treeView
      the_tree_item = tree_view.selectionModel.selectedItem
      children = the_tree_item.children

      puts "Selected #{the_tree_item.value} kind: #{the_tree_item.kind}"

      case the_tree_item.kind
        when :feed, :resource

          # Show info in the bottom text field
          text = the_tree_item.kind != :feed ? the_tree_item.resource.path : the_tree_item.value
          tree_view.scene.lookup('#FXMLtextArea').text = text

          break if the_tree_item.is_done
          the_tree_item.is_done = true

          text = source.item
          if the_tree_item.kind == :feed
            resources = $inventory_client.list_resources_for_feed text
          else
            resources = $inventory_client.list_child_resources the_tree_item.resource.path
          end

          if the_tree_item.kind == :resource
            the_tree_item.is_done = true
            metrics = $inventory_client.list_metrics_for_resource the_tree_item.resource.path
            metrics.each do |m|
              new_metric = build(::HTreeItem)
              new_metric.kind = :metric
              new_metric.value = m.name
              new_metric.metric = m
              iv = ::HawkHelper.create_icon m.type == 'AVAILABILITY' ? 'A' : 'M'
              new_metric.graphic = iv
              puts "Adding metric #{new_metric.to_s}"
              children.add new_metric # TODO add or replaceF
              the_tree_item.expanded=true
            end

            operations = $inventory_client.list_operation_definitions_for_resource the_tree_item.resource.path
            operations.each do |op|
              new_operation = build(::HTreeItem)
              new_operation.kind = :operation
              new_operation.value = op
              iv = ::HawkHelper.create_icon 'O'
              new_operation.graphic = iv
              children.add new_operation
              the_tree_item.expanded=true
            end
          end

          unless resources.empty?
            ascend_sort = ->(r1, r2) { r1.name <=> r2.name }
            resources.sort(&ascend_sort).each do |res|
              new_item = build(::HTreeItem) #res  # name  #
              new_item.path = res.path
              new_item.kind = :resource
              new_item.resource = res
              # (res
              # .name) ## works on the source item
              name = res.name.dup
              name = name.start_with?(res.feed) ? name.sub(res.feed, '') : name
              new_item.value = name

              iv = ::HawkHelper.create_icon 'R'
              new_item.graphic = iv

              puts "Adding resource #{new_item.to_s}"
              children.add new_item
              the_tree_item.expanded=true
            end
            # TODO pull in operations for this node
          end
        when :metric
          # Write path in lower text field
          text = the_tree_item.metric.path
          tree_view.scene.lookup('#FXMLtextArea').text = text

          # Add the metric to the charting component
          if the_tree_item.metric.type == 'AVAILABILITY'
            stage = tree_view.scene.window

            id = "#{the_tree_item.metric.properties['metric-id']}"
            if id.to_s == ''
              puts "Assuming the avail ID is the same as the inventory ID"
              id = the_tree_item.metric.id
            end
            puts "Using ID [#{id}] for metric [#{the_tree_item.metric.name}]"

            ::HawkHelper.show_avail_popup stage, id
          else
            chart_control = tree_view.scene.lookup('#myChartView')
            chart_control.add_item the_tree_item.metric
          end
        when :operation
          text = the_tree_item.value
          tree_view.scene.lookup('#FXMLtextArea').text = text

      end
    end
  end

  def show_raw_menu_item
    cmi = Java::javafx::scene::control::MenuItem.new 'Show Raw'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      case item.kind
        when :feed
          text = item.value
        when :resource
          text = JSON.pretty_generate(item.resource.to_h)
        when :metric
          text = JSON.pretty_generate(item.metric.to_h)
        else
          text = "- unknown kind #{item.kind}, value = #{item.value}"
      end
      stage = tree_view.scene.window
      ::HawkHelper.show_raw_popup stage, text
    end
    cmi
  end

  def create_properties_menu_item
    cmi = Java::javafx::scene::control::MenuItem.new 'Show Properties'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      case item.kind
        when :resource
          response = $inventory_client.get_config_data_for_resource item.resource.path
          text = JSON.pretty_generate(response.to_h) unless response.nil?
        else
          text = "- unknown kind #{item.kind}, value = #{item.value}"
      end

      stage = tree_view.scene.window
      ::HawkHelper.show_raw_popup stage, text
    end
    cmi
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
