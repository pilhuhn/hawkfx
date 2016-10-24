require 'json'
require_relative 'hawk'

class OnClickCellFactory < Java::javafx::scene::control::TreeCell
  include JRubyFX::DSL

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
      when :feed, :resource

        # Show info in the bottom text field
        text = the_tree_item.kind != :feed ? the_tree_item.raw_item.path : the_tree_item.value
        set_result_text(tree_view, text)

        break if the_tree_item.is_done
        the_tree_item.is_done = true

        if the_tree_item.kind == :feed
          resources = Hawk.inventory.list_resources_for_feed source.item
        else
          resources = Hawk.inventory.list_child_resources the_tree_item.raw_item.path
        end

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
      new_item.path = res.path
      new_item.kind = :resource
      new_item.raw_item = res
      # (res
      # .name) ## works on the source item
      name = res.name.dup
      name = name.start_with?(res.feed) ? name.sub(res.feed, '') : name
      new_item.value = name

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
    metrics = Hawk.inventory.list_metrics_for_resource the_tree_item.raw_item.path
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
    operations = Hawk.inventory.list_operation_definitions_for_resource the_tree_item.raw_item.path
    operations.each do |name, op|
      new_operation = build(::HTreeItem)
      new_operation.kind = :operation
      new_operation.value = name
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
      ::HawkHelper.show_raw_popup stage, text
    end
    cmi
  end

  def run_operation_menu_item
    cmi = Java::javafx::scene::control::MenuItem.new 'Run...'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      stage = tree_view.scene.window
      ::HawkHelper.run_ops_popup stage, item.raw_item, item.parent.raw_item.path
    end
    cmi
  end

  def create_metric_alert_item
    cmi = Java::javafx::scene::control::MenuItem.new 'New trigger...'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      stage = tree_view.scene.window

      type = item.raw_item.type.downcase
      id = item.raw_item.hawkular_metric_id
      if type != 'availability'
        text = "define trigger \"trigger-#{id}\"\n (threshold #{type} \"#{id}\" \n > XXX )"
      else
        text = "define trigger \"trigger-#{id}\"\n (availability  \"#{id}\" \n is XXX )"
      end

      ::HawkHelper.run_synth_metric_popup stage, :TRIGGER, text
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
        response = Hawk.inventory.get_config_data_for_resource item.raw_item.path
        text = JSON.pretty_generate(response.to_h) unless response.nil?
      else
        text = "- unknown kind #{item.kind}, value = #{item.value}"
      end

      stage = tree_view.scene.window
      ::HawkHelper.show_raw_popup stage, text
    end
    cmi
  end

  def create_metric_tag_menu_item
    cmi = Java::javafx::scene::control::MenuItem.new 'Tag metric definition'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      if item.kind == :metric

        inv_metric = item.raw_item # metric def in inventory.

        # get md from hawkular-metrics now
        ep = ::HawkHelper.metric_endpoint inv_metric
        m_metric = ep.get inv_metric.id # TODO: add this new mazz-magic (?)
        text = JSON.pretty_generate(m_metric.tags.to_h)
        puts text

        stage = tree_view.scene.window
        ::HawkHelper.show_kv_editor stage, self, :add_tag_callback, m_metric, ep

      end
    end
    cmi
  end

  # Callback method from create_metric_tag_menu_item
  def add_tag_callback(kv_pair, metric_def, endpoint)
    return if kv_pair.nil?

    tag = { kv_pair.fetch(:key) => kv_pair.fetch(:value) }

    metric_def.tags ||= {}
    metric_def.tags.merge!(tag)

    endpoint.update_tags(metric_def)
  end

  def show_metric_tag_menu_item
    cmi = Java::javafx::scene::control::MenuItem.new 'Show Tags'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      if item.kind == :metric

        inv_metric = item.raw_item # metric def in inventory.

        # get md from hawkular-metrics now
        ep = ::HawkHelper.metric_endpoint inv_metric
        m_metric = ep.get inv_metric.id
        text = JSON.pretty_generate(m_metric.tags.to_h)
        puts text

        ::HawkHelper.show_raw_popup stage, text
      end
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
