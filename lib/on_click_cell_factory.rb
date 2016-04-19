
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

            break if the_tree_item.is_done
            the_tree_item.is_done = true

            text = source.item
            if the_tree_item.kind == :feed
              resources = $inventory_client.list_resources_for_feed text
            else
              resources = $inventory_client.list_child_resources the_tree_item.resource
            end

            if the_tree_item.kind == :resource
              the_tree_item.is_done = true
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
                the_tree_item.expanded=true

              end
            end

            unless resources.empty?
              resources.each do |res|
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
              # TODO pull in metrics for this node
            end
          when :metric
            show_chart(the_tree_item)
        end
      end
    end

    def show_chart(the_tree_item)
      id = the_tree_item.metric.id
      type = the_tree_item.metric.type
      puts "Getting metric data for #{path}"
      case type
        when 'GAUGE'
          data = $metric_client.gauges.get_data id, buckets: 120
        when 'COUNTER'
          data = $metric_client.counters.get_data id, buckets: 120
        else
          puts "Data Type #{type} is not known"
          return
      end

      the_chart = $FXMLChart
      series = xy_chart_series(name: id)
      data.each do |item|
        unless item.nil?
          ts = item['start'] / 1000 # buckets -> start || timestamp for raw
          time = Time.at(ts).to_s
          val = item['avg'] # buckets -> avg(?) || value for raw
          series.data.add xy_chart_data time, val
        end
      end

      the_chart.data.clear if $FXMLSingleChart.selected
      the_chart.data.add series
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