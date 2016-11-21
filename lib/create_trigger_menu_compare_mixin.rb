module CreateTriggerMenuCompareMixin
  def create_metric_compare_alert_item
    cmi = Java::javafx::scene::control::MenuItem.new 'New compare trigger...'
    cmi.on_action do
      item = tree_view.selectionModel.selectedItem
      stage = tree_view.scene.window

      type = item.raw_item.type.downcase
      id = item.raw_item.hawkular_metric_id
      id2 = "#{id.slice(0..(id.rindex(' ')))}XXX"
      if type == 'gauge'
        text = "define trigger \"trigger-#{id}\"\n (compare #{type} \"#{id}\" \n > XX% #{type} \"#{id2}\" )"
      else
        text = 'Invalid, Compare Conditions require gauge metrics.  Please cancel and try again.'
      end

      ::HawkHelper.run_synth_metric_popup stage, :TRIGGER, text
    end
    cmi
  end
end
