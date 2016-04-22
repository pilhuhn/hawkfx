class AlertListCellFactory < Java::javafx::scene::control::ListCell
  include JRubyFX::DSL

  def initialize
    super

    set_on_mouse_clicked do |event|

      puts "Got #{event.to_s}"
      source = event.source

      list_view = source.listView
      the_item = list_view.selectionModel.selectedItem

      alert = the_item.alert
      list_view.scene.lookup('#FXMLAlertId').text = alert.id
      list_view.scene.lookup('#FXMLAlertResource').text = alert.tags['resourceId']
      list_view.scene.lookup('#FXMLText').text = alert.text

    end
  end

  # Create the content for the row in the list.
  def get_string
    get_item ? get_item.alert.id : ''
  end


  # Does the real display
  def updateItem(item, empty)
    super item, empty

    if empty
      set_text nil
    else
      set_text get_string
    end
  end
end