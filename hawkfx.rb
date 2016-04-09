require 'jrubyfx'

require_relative 'lib/hawk_fx_controller'

fxml_root File.dirname(__FILE__) + '/assets/'

class HawkFx < JRubyFX::Application

  def start(stage)
    with(stage, title: 'Hawk FX!', width: 800, height: 600) do
      fxml ::HawkFxController
      show
    end

    stage.show()
  end
end

HawkFx.launch