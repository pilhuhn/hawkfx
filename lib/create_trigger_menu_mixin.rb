module CreateTriggerMenuMixin
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
end
