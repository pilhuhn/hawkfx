require 'jrubyfx'

require_relative 'lib/hawk_login_controller'

fxml_root File.dirname(__FILE__) + '/assets/'

class HawkFx < JRubyFX::Application
  def start(stage)
    with(stage, title: 'Hawk FX!') do
      fxml ::HawkLoginController
      show
    end

    stage.show
  end
end

HawkFx.launch
