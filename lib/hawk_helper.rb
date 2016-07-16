require 'jrubyfx'
require_relative 'availability_display_controller'
require_relative 'key_value_editor'
require_relative 'raw_display_controller'
require_relative 'run_operation_controller'

class HawkHelper

  def self.create_icon(letter)
    dir = File.dirname(__FILE__).sub('/lib','/assets/')
    file = "file://#{dir}#{letter}.png"

    img = Java::JavafxSceneImage::Image.new(file)
    iv = Java::JavafxSceneImage::ImageView.new(img)
    iv.setFitWidth(20)
    iv.setPreserveRatio(true)
    iv.setSmooth(true)
    iv.setCache(true)
    iv
  end

  def self.show_raw_popup(parent_stage, text) # TODO allow to set title
    popup_stage = ::Java::JavafxStage::Stage.new
    raw_display = ::RawDisplayController.load_into popup_stage
    raw_display.show_text(text)
    popup_stage.init_modality = :application
    popup_stage.init_owner parent_stage
    popup_stage.show
  end

  def self.show_avail_popup(parent_stage, id)
    popup_stage = ::Java::JavafxStage::Stage.new
    raw_display = ::AvailabilityDisplayController.load_into popup_stage
    raw_display.show_availability(id)
    popup_stage.init_modality = :application
    popup_stage.init_owner parent_stage
    popup_stage.show
  end


  def self.metric_endpoint(inv_metric)
    case inv_metric.type
      when 'GAUGE'
        $metric_client.gauges
      when 'COUNTER'
        $metric_client.counters
      when 'AVAILABILITY'
        $metric_client.avail
      else
        raise "Unknown type #{inv_metric.type} for #{inv_metric.to_s}"
    end
  end


  def self.show_kv_editor(parent_stage, caller, callback, *other_stuff)
    popup_stage = ::Java::JavafxStage::Stage.new
    kv_editor = ::KeyValueEditor.load_into popup_stage
    kv_editor.setup caller, callback, *other_stuff
    popup_stage.init_modality = :none
    popup_stage.init_owner parent_stage
    popup_stage.show

    kv_editor
  end

  def self.run_ops_popup(parent_stage, operation, parent_path)
    popup_stage = ::Java::JavafxStage::Stage.new
    ops_contol = ::RunOperationController.load_into popup_stage
    ops_contol.setup operation, parent_path
    popup_stage.init_modality = :none
    popup_stage.init_owner parent_stage
    popup_stage.show

    ops_contol
  end
end
