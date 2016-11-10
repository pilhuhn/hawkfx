module MetricTagMixin
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

        ::HawkHelper.show_raw_popup stage, 'Tags', text
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
end
