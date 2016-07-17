require 'jrubyfx'

class HTreeItem < Java::javafx::scene::control::TreeItem
  attr_accessor :kind, :path, :raw_item
  attr_accessor :is_leaf, :is_done

  def initialize
    @is_leaf = false
    @is_done = false
  end
end
