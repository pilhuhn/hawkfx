require 'jrubyfx'

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
end
