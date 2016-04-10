require 'jrubyfx'
require 'jrubyfx-fxmlloader'
require 'hawkular_all'

require_relative 'hawk_helper'
require_relative 'h_tree_item'
require_relative 'on_click_cell_factory'

  class HawkFxController
    include JRubyFX::Controller
    fxml 'fxmain.fxml'

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

        show_initial_tree(feeds)
      rescue Exception => e
        @FXMLtextArea.text = "Connection failed: #{e.to_s}"
        raise e
      end
    end

    def show_initial_tree(feeds)

      @FXMLtreeView.setCellFactory proc { ::OnClickCellFactory.new }

      tree_root = tree_item('Feeds')
      feeds.each do |feed|
        iv = ::HawkHelper.create_icon 'F'

        new_feed = build(::HTreeItem)
        new_feed.kind = :feed
        new_feed.value = feed
        new_feed.graphic = iv

        tree_root.children.add new_feed
        puts new_feed.to_s
      end
      # bind to the view from fxml
      @FXMLtreeView.setRoot(tree_root)
      $FXMLChart = @FXMLChart
      $FXMLSingleChart = @FXMLSingleChart

      tree_root.setExpanded true
    end
  end