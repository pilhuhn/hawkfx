require 'jrubyfx'
require 'hawkular/hawkular_client'

class AlertListItem < Java::javafx::scene::control::ListCell

  attr_accessor :alert

end