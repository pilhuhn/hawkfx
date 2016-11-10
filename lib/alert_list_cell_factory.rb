require 'jrubyfx'
require_relative 'hawk_helper'

class AlertListCellFactory < Java::javafx::scene::control::ListCell
  include JRubyFX::DSL

  def initialize
    super

    # Create a context menu to show the raw object
    cm = Java::javafx::scene::control::ContextMenu.new
    cmi = Java::javafx::scene::control::MenuItem.new 'Show Raw'
    cmi.on_action do
      item = list_view.selectionModel.selectedItem
      alert = item.alert

      stage = list_view.scene.window
      ::HawkHelper.show_raw_popup stage, 'Raw Alert', JSON.pretty_generate(alert.to_h)
    end

    cm.items.add cmi
    set_context_menu cm

    # Left click action
    set_on_mouse_clicked do |event|
      source = event.source

      list_view = source.listView
      scene = list_view.scene
      the_item = list_view.selectionModel.selectedItem
      alert = the_item.alert

      scene.lookup('#FXMLAlertId').text = alert.id
      scene.lookup('#FXMLAlertResource').text = alert.tags['resourceId'] unless alert.tags.nil?
      scene.lookup('#FXMLTags').text = alert.tags.to_s unless alert.tags.nil?
      scene.lookup('#FXMLText').text = alert.text
      scene.lookup('#FXMLSeverity').text = alert.severity
      scene.lookup('#FXMLContext').text = alert.context.to_s
      scene.lookup('#FXMLCategory').text = alert.category
      scene.lookup('#FXMLTime').text = Time.at(alert.ctime / 1000).to_s # Hawkular has ms
    end
  end

  # Create the content for the row in the list.
  # rubocop: disable Style/AccessorMethodName
  def get_string
    get_item ? get_item.alert.id : ''
  end
  # rubocop: enable Style/AccessorMethodName

  # Does the real display
  # rubocop: disable Style/MethodName
  def updateItem(item, empty)
    super item, empty

    if empty
      set_text nil
    else
      set_text get_string
    end
  end
  # rubocop: enable Style/MethodName
end
