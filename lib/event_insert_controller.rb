require 'jrubyfx'
require_relative 'hawk_helper'
require_relative 'key_value'

class EventInsertController
  include JRubyFX::Controller
  fxml 'fx_event_enter.fxml'

  def initialize
    now = Time.now.to_i
    @FXMLAlertId.text = "event-#{now}"

    @tag_data = @FXMLTags.items
    @context_data = @FXMLContext.items

    category_binding = @FXMLCategory.text_property.is_empty
    @submit_button.disable_property.bind category_binding
    @cat_required_label.disable_property.bind category_binding.not

  end

  def add_tag_button
    ::HawkHelper.show_kv_editor @scene.window, self, :add_tag_callback
  end

  def add_context_button
    ::HawkHelper.show_kv_editor @scene.window, self, :add_context_callback
  end

  def add_tag_callback val
    kv = KeyValue.new(val[:key], val[:value])
    @tag_data.add kv
  end

  def add_context_callback val
    kv = KeyValue.new(val[:key], val[:value])
    @context_data.add kv
  end


=begin
Example event to insert
    {"id":"ems-hawkular-event-4",
     "ctime":"1467733170000",    -- supplied by the hawkular gem
     "tags":{"miq.event_type":"hawkular_event.critical"},
     "category":"Hawkular Deployment",
     "text":"Error",
     "context":{
         "message":"This is a mock deployment event"
     }
    }
=end

  def submit
    id = @FXMLAlertId.text

    tags = table_data_to_hash @tag_data
    context = table_data_to_hash @context_data

    text = @FXMLText.text
    category = @FXMLCategory.text

    extras = {}
    extras.store :tags, tags unless tags.nil?
    extras.store :context, context unless context.nil?

    $alerts_client.create_event(id, category, text, extras)

    @stage.close
  end

  def table_data_to_hash param
    unless param.empty?
      ret = {}
      param.each do |kv|
        k, v = kv.to_kv
        ret.store k, v
      end
    end
    ret
  end
end