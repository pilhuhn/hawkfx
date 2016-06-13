require 'jrubyfx'
require 'jrubyfx-fxmlloader'
require 'hawkular/hawkular_client'
require 'uri'

require_relative 'hawk_helper'
require_relative 'hawk_main_controller'

  class HawkLoginController
    include JRubyFX::Controller
    fxml 'fxlogin.fxml'

    def login # callback from the login button
      creds = {:username => @FXMLLoginField.text,
               :password => @FXMLPasswordField.text}

      hash = {}
      hash[:entrypoint] = URI(@FXMLUrlField.text)
      hash[:credentials] = creds
      hash[:options] = { :tenant => @FXMLTenantField.text}

      $hawkular = ::Hawkular::Client.new(hash)

      $inventory_client = $hawkular.inventory
      $metric_client = $hawkular.metrics
      $alerts_client = $hawkular.alerts

      begin
        # @tenant = $inventory_client.get_tenant
        @FXMLtextArea.text = "Tenant: #{@tenant}"

        show_main_pane

      rescue Exception => e
        @FXMLtextArea.text = "Error: #{e.to_s}"
        @tenant = 'hawkular'
        raise e
      end
    end

    # Now after login we can show the main app
    def show_main_pane
      dir = File.dirname(__FILE__).sub('/lib','/assets/')

      #FXMLLoginPane is the root, so get the stage from it
      stage = @FXMLLoginField.scene.window

      # Create a Main controller, which will load fxml
      # into the passed stage
      main_controller = ::HawkMainController.load_into stage, {:width => 1000,
                                                               :height => 850,
                                                               :root_dir => dir }

      stage.min_width = 1000
      stage.min_height = 800
      stage.size_to_scene

      mode = @FXMLModeButton.selected ? :hawkular : :metrics
      tenant = @FXMLTenantField.text

      main_controller.show_initial_tree mode, tenant
    end

  end