require 'json'
require_relative 'hawk'
require_relative 'create_trigger_menu_mixin'
require_relative 'create_trigger_menu_compare_mixin'
require_relative 'metric_tag_mixin'

class OnClickCellFactory < Java::javafx::scene::control::TreeCell
  include MetricTagMixin
  include JRubyFX::DSL
  include CreateTriggerMenuMixin
  include CreateTriggerMenuCompareMixin

  def initialize
    super

    # Create a context menu to show the raw object
    cm = setup_context_menu

    # Left+right-click action
    set_on_mouse_clicked do |event|
      puts "Got #{event}"
      source = event.source

      tree_view = source.treeView
      the_tree_item = tree_view.selectionModel.selectedItem
      children = the_tree_item.children

      puts "Selected #{the_tree_item.value} kind: #{the_tree_item.kind}"

      # Select / de-select menu-items
      button = event.button
      if button.to_s == 'SECONDARY'
        enable_disable_conext_menu_items(cm, the_tree_item)
        # right click was consumed so we are done.
        break
      end

      case the_tree_item.kind
      when :feed
        set_result_text(tree_view, the_tree_item.value)
        break if the_tree_item.is_done
        the_tree_item.is_done = true
        resources = the_tree_item.resources
        add_child_resources(children, resources, the_tree_item) unless resources.empty?
        the_tree_item.resources = nil
      when :resource

        # Show info in the bottom text field
        set_result_text(tree_view, the_tree_item.id)

        break if the_tree_item.is_done
        the_tree_item.is_done = true

        resources = Hawk.inventory_v4.children_resources the_tree_item.raw_item.id

        if the_tree_item.kind == :resource
          the_tree_item.is_done = true
          add_metrics(children, the_tree_item)
          add_operations(children, the_tree_item)
        end

        add_child_resources(children, resources, the_tree_item) unless resources.empty?
      when :metric
        # Write path in lower text field
        text = the_tree_item.raw_item.path
        set_result_text(tree_view, text)
        set_id_text(tree_view,  the_tree_item.raw_item.id)

        # Add the metric to the charting component
        if the_tree_item.raw_item.type == 'AVAILABILITY'
          show_avail_popup(the_tree_item, tree_view)
        elsif the_tree_item.raw_item.type == 'STRING'
          show_string_popup(the_tree_item, tree_view )
        else
          chart_control = tree_view.scene.lookup('#myChartView')
          chart_control.add_remove_item the_tree_item.raw_item
        end
      when :operation
        text = the_tree_item.value
        set_result_text(tree_view, text)
      end
    end
  end

  def set_result_text(tree_view, text)
    lower_text_area = tree_view.scene.lookup('#FXMLtextArea')
    lower_text_area.pref_row_count = 2
    lower_text_area.text = text
  end

  def set_id_text(tree_view, text)
    lower_text_area = tree_view.scene.lookup('#FXMLidField')
    lower_text_area.text = text
  end

  def add_child_resources(children, resources, the_tree_item)
    ascend_sort = ->(r1, r2) { r1.name <=> r2.name }
    resources.sort(&ascend_sort).each do |res|
      new_item = build(::HTreeItem)
      new_item.id = res.id
      new_item.kind = :resource
      new_item.raw_item = res
      # (res
      # .name) ## works on the source item
      new_item.value = res.name

      iv = ::HawkHelper.create_icon 'R'
      new_item.graphic = iv

      puts "Adding resource #{new_item}"
      children.add new_item
      the_tree_item.expanded = true
    end
  end

  def show_avail_popup(the_tree_item, tree_view)
    stage = tree_view.scene.window

    id = "#{the_tree_item.raw_item.properties['hawkular-metric-id']}"
    if id.to_s == ''
      puts 'Assuming the avail ID is the same as the inventory ID'
      id = the_tree_item.raw_item.id
    end
    puts "Using ID [#{id}] for metric [#{the_tree_item.raw_item.name}]"

    ::HawkHelper.show_avail_popup stage, id
  end

  def show_string_popup(the_tree_item, tree_view)
    stage = tree_view.scene.window

    id = "#{the_tree_item.raw_item.properties['hawkular-metric-id']}"
    if id.to_s == ''
      puts 'Assuming the string ID is the same as the inventory ID'
      id = the_tree_item.raw_item.id
    end
    puts "Using ID [#{id}] for metric [#{the_tree_item.raw_item.name}]"

    ::HawkHelper.show_string_popup stage, id
  end

  def add_metrics(children, the_tree_item)
    metrics = the_tree_item.raw_item.metrics
    metrics.each do |m|
      new_metric = build(::HTreeItem)
      new_metric.kind = :metric
      new_metric.value = m.name
      new_metric.raw_item = m
      icon = ::HawkHelper.metric_icon m.type
      iv = ::HawkHelper.create_icon icon
      new_metric.graphic = iv
      puts "Adding metric #{new_metric}"
      children.add new_metric
      the_tree_item.expanded = true
    end
  end

  def add_operations(children, the_tree_item)
    operations = the_tree_item.raw_item.type.operations
    operations.each do |op|
      new_operation = build(::HTreeItem)
      new_operation.kind = :operation
      new_operation.value = op.name
      new_operation.raw_item = op
      iv = ::HawkHelper.create_icon 'O'
      new_operation.graphic = iv
      children.add new_operation
      the_tree_item.expanded = true
    end
  end

  def enable_disable_conext_menu_items(cm, the_tree_item)
    cm.items.each do |menu_item|
      item_name = menu_item.text.to_s
      kind = the_tree_item.kind
      if item_name.include? 'Tag'
        menu_item.disable = ([:resource, :feed, :operation].include?(kind))
      elsif item_name.include? 'Prop'
        menu_item.disable = kind != :resource
      elsif item_name.include? 'Run'
        menu_item.disable = kind != :operation
      elsif item_name.include? 'Delete'
        menu_item.disable = kind != :feed
      elsif item_name.include? 'New trigger'
        menu_item.disable = ([:resource, :feed, :operation].include?(kind))
      elsif item_name.include? 'New compare trigger'
        menu_item.disable = ([:resource, :feed, :operation].include?(kind))
      end
    end
  end

  def setup_context_menu
    cm = Java::javafx::scene::control::ContextMenu.new
    cmi = show_raw_menu_item
    cm.items.add cmi

    # Context menu to show properties.
    cmi = create_properties_menu_item
    cm.items.add cmi

    # Context menu to add tags on metrics
    cmi = create_metric_tag_menu_item
    cm.items.add cmi

    # Context menu to add alert triggers
    cmi = create_metric_alert_item
    cm.items.add cmi

    # Context menu to add alert compare triggers
    cmi = create_metric_compare_alert_item
    cm.items.add cmi

    # Context menu to show tags on metrics
    cmi = show_metric_tag_menu_item
    cm.items.add cmi

    # Context menu to run operations
    cmi = run_operation_menu_item
    cm.items.add cmi

    # Context menu to delete
    cmi = show_delete_menu_item
    cm.items.add cmi

    set_context_menu cm
    cm
  end

  def show_raw_menu_item
    cmi = Java::javafx::scene::control::MenuItem.new 'Show Raw'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      case item.kind
      when :feed
        text = item.value
      when :resource, :metric, :operation
        text = JSON.pretty_generate(item.raw_item.to_h)
      else
        text = "- unknown kind #{item.kind}, value = #{item.value}"
      end
      stage = tree_view.scene.window
      ::HawkHelper.show_raw_popup stage, 'Raw data', text
    end
    cmi
  end

  def run_operation_menu_item
    cmi = Java::javafx::scene::control::MenuItem.new 'Run...'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      stage = tree_view.scene.window
      ::HawkHelper.run_ops_popup stage, item.raw_item, item.parent.raw_item.id
    end
    cmi
  end

  def show_delete_menu_item
    cmi = Java::javafx::scene::control::MenuItem.new 'Delete'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      # a confirmation dialog would be nice
      case item.kind
      when :feed
        Hawk.inventory.delete_feed(item.value)
        item.getParent().getChildren().remove(item)
      else
        raise 'Not implemented.'
      end
    end
    cmi
  end

  def create_properties_menu_item
    cmi = Java::javafx::scene::control::MenuItem.new 'Show Properties'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      if item.kind == :resource
        response = item.raw_item.properties
        text = JSON.pretty_generate(response.to_h) unless response.nil?
      else
        text = "- unknown kind #{item.kind}, value = #{item.value}"
      end

      stage = tree_view.scene.window
      ::HawkHelper.show_raw_popup stage, 'Properties',  text
    end
    cmi
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
