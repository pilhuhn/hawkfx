require 'jrubyfx'
require_relative 'raw_display_controller'

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

  def self.show_raw_popup(parent_stage, text)
    popup_stage = ::Java::JavafxStage::Stage.new
    raw_display = ::RawDisplayController.load_into popup_stage
    raw_display.show_text(text)
    popup_stage.init_modality = :application
    popup_stage.init_owner parent_stage
    popup_stage.show
  end
end
