require 'jrubyfx'
require 'hawkular_all'

class AlertListItem < Java::javafx::scene::control::ListCell

  attr_accessor :alert

end