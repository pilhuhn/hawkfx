require 'jrubyfx'
require 'jrubyfx-fxmlloader'
require 'uri'
require_relative 'hawk'

require_relative 'hawk_helper'

class HawkLoginController
  include JRubyFX::Controller
  fxml 'fxlogin.fxml'

  def login # callback from the login button
    creds = { :username => @FXMLLoginField.text,
              :password => @FXMLPasswordField.text }

    enable_logging

    # We need to require those after potentially enable logging
    # as otherwise the requiring will aready set the logging
    # of the restclient.
    require 'hawkular/hawkular_client'
    require 'hawkular/metrics/metrics_client.rb'
    require_relative 'hawk_main_controller'


    hash = {}
    hash[:entrypoint] = URI(@FXMLUrlField.text).to_s # TODO: see https://github.com/hawkular/hawkular-client-ruby/issues/116
    hash[:credentials] = creds
    hash[:options] = { :tenant => @FXMLTenantField.text }

    begin
      if @FXMLModeButton.selected
        Hawk.client = ::Hawkular::Client.new(hash)
        Hawk.mode = :hawkular
      else # Metrics only mode
        Hawk.mode = :metrics
        mc = ::Hawkular::Metrics::Client.new("#{hash[:entrypoint]}/hawkular/metrics",
                            hash[:credentials],
                            hash[:options])
        Hawk.metrics = mc

        ac = ::Hawkular::Alerts::AlertsClient.new("#{hash[:entrypoint]}/hawkular/alerts",
                                                      hash[:credentials],
                                                      hash[:options])
        Hawk.alerts = ac
      end

      # @tenant = $inventory_client.get_tenant
      @FXMLtextArea.text = "Tenant: #{@tenant}"

      show_main_pane

    rescue StandardError => e
      @FXMLtextArea.text = "Error: #{e}"
      @tenant = 'hawkular'
      raise e
    end
  end

  def enable_logging
    verbose = @logging_enabled.selected
    if verbose
      ENV['RESTCLIENT_LOG'] = 'stdout'
      ENV['HAWKULARCLIENT_LOG_RESPONSE'] = '1'
    end
  end

  # Now after login we can show the main app
  def show_main_pane
    dir = File.dirname(__FILE__).sub('/lib', '/assets/')

    # FXMLLoginPane is the root, so get the stage from it
    stage = @FXMLLoginField.scene.window

    # Create a Main controller, which will load fxml
    # into the passed stage
    main_controller = ::HawkMainController.load_into stage, :width => 1000,
                                                            :height => 850,
                                                            :root_dir => dir

    stage.min_width = 1000
    stage.min_height = 800
    stage.size_to_scene

    main_controller.show_initial_tree Hawk.mode
  end
end
