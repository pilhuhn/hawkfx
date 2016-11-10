require 'jrubyfx'

class RawDisplayController
  include JRubyFX::Controller
  fxml 'RawDisplay.fxml'

  def show_text(text)
    @FXMLTheText.text = text
  end

  def show_title(text)
    @Title.text = text
  end
end
