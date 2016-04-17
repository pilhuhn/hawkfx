require 'jrubyfx'
require 'jrubyfx-fxmlloader'
require 'hawkular_all'
require 'uri'

require_relative 'hawk_helper'
require_relative 'hawk_fx_controller'

  class HawkLoginController
    include JRubyFX::Controller
    fxml 'fxlogin.fxml'

    def login # callback from the login button
      creds = {:username => @FXMLLoginField.text,
               :password => @FXMLPasswordField.text}
      base_url = @FXMLUrlField.text
      url = "#{base_url}/hawkular/inventory"
      $inventory_client = ::Hawkular::Inventory::InventoryClient.new(url, creds)
      url = "#{base_url}/hawkular/metrics"
      $metric_client = ::Hawkular::Metrics::Client.new(url, creds)

      begin
        @tenant = $inventory_client.get_tenant
        @FXMLtextArea.text = "Tenant: #{@tenant}"
        feeds = $inventory_client.list_feeds

        show_main_pane feeds

      rescue Exception => e
        @FXMLtextArea.text = "Connection failed: #{e.to_s}"
        raise e
      end
    end

    # Now after login we can show the main app
    def show_main_pane(feeds)
      dir = File.dirname(__FILE__).sub('/lib','/assets/')

      #FXMLLoginPane is the root, so get the stage from it
      stage = @FXMLLoginField.scene.window

      stage.min_width = 1000
      stage.min_height = 800


      # Create a Main controller, which will load fxml
      # into the passed stage
      main_controller = ::HawkFxController.load_into stage, {:feeds => feeds,
        :width => 1000, :height => 800, :root_dir => dir }

      stage.size_to_scene

      main_controller.show_initial_tree feeds
    end

  end