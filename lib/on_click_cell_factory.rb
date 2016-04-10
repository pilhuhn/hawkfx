
  class OnClickCellFactory < Java::javafx::scene::control::TreeCell
    include JRubyFX::DSL

    def initialize
      super

      set_on_mouse_clicked do |event|
        puts "Got #{event.to_s}"
        source = event.source

        tree_view = source.treeView
        the_tree_item = tree_view.selectionModel.selectedItem
        children = the_tree_item.children

        puts "Selected #{the_tree_item.value} kind: #{the_tree_item.kind}"

        case the_tree_item.kind
          when :feed, :resource
            text = source.item
            resources = $inventory_client.list_resources_for_feed text
            if resources.empty?
              the_tree_item.is_leaf = true
              metrics = $inventory_client.list_metrics_for_resource the_tree_item.resource
              metrics.each do |m|
                new_metric = build(::HTreeItem)
                new_metric.kind = :metric
                new_metric.value = m.name
                new_metric.metric = m
                iv = ::HawkHelper.create_icon 'M'
                new_metric.graphic = iv
                puts "Adding metric #{new_metric.to_s}"
                children.add new_metric # TODO add or replaceF
                the_tree_item.setExpanded true

              end
            else
              resources.each do |res|
                # new_item = build(Java::javafx::scene::control::TreeItem)  #res  # name  #
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
                the_tree_item.setExpanded true
              end
            end
          when :metric
            id = the_tree_item.metric.id
            type = the_tree_item.metric.type
            puts "Getting metric data for #{path}"
            case type
              when 'GAUGE'
                data = $metric_client.gauges.get_data id
              when 'COUNTER'
                data = $metric_client.counters.get_data id
            end
            the_chart = $FXMLChart
            series = xy_chart_series(name: id)
            now = Time.now.to_i * 1000
            data.each do |item|
              ts = (item['timestamp']-now) / (1000*60) # Time in 'minutes ago'
              series.data.add xy_chart_data ts, item['value']
            end

            the_chart.data.clear if $FXMLSingleChart.selected
            the_chart.data.add series
        end
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

      return if empty

      set_text get_string
      set_graphic tree_item.graphic
    end
  end