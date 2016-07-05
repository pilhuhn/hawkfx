require 'jrubyfx'

class EventInsertController
  include JRubyFX::Controller
  fxml 'fx_event_enter.fxml'

  def initialize
    now = Time.now.to_i
    find('#FXMLAlertId').text = "event-#{now}"

  end

  def submit
=begin
Example
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

    id = find('#FXMLAlertId').text
    t = find('#FXMLTags').text
    tags = JSON.parse(t) unless t.empty?
    text = find('#FXMLText').text
    t = find('#FXMLContext').text
    context = JSON.parse(t) unless t.empty?
    category = find('#FXMLCategory').text

    $alerts_client.create_event(id, category, text, context: context, tags: tags)
  end
end