require 'java'

class KeyValue
  include JRubyFX

  fxml_accessor :key, SimpleStringProperty
  fxml_accessor :value, SimpleStringProperty

  def initialize(key, value)
    self.key = key
    self.value = value
  end

  def to_kv
    return key, value
  end
end

KeyValue.become_java!
