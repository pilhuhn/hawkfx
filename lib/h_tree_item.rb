require 'jrubyfx'

class HTreeItem < Java::javafx::scene::control::TreeItem
  attr_accessor :kind, :id, :raw_item, :resources
  attr_accessor :is_leaf, :is_done

  def initialize
    @is_leaf = false
    @is_done = false
  end
end
