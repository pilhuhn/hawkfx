require "#{File.dirname(__FILE__)}/spec_helper"
require 'alert_definition_parser'


describe 'Basic Parsing' do

  it 'should parse basic' do
    text = <<-EOT
define trigger "MyTrigger"
( threshold "myvalue" > 3 )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].name).to eq 'MyTrigger'
  end

  it 'should parse basic with id' do
    text = <<-EOT
define trigger "MyTrigger"
 id  "bla"
 ( threshold "myvalue" > 3 )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].id).to eq 'bla'
  end

  it 'should parse basic enabled' do
    text = <<-EOT
define trigger "MyTrigger"
 enabled
 ( availability "myvalue" is DOWN )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].enabled).to be_truthy
  end

  it 'should parse basic enabled, auto-disable' do
    text = <<-EOT
define trigger "MyTrigger"
 enabled
 ( threshold "myvalue" > 3 )
 auto-disable
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].enabled).to be_truthy
    expect(t[:trigger].auto_disable).to be_truthy
    expect(t[:trigger].id).to be_nil
  end

end

describe 'Condition Parsing' do
  it 'should parse threshold' do
    text = <<-EOT
define trigger "MyTrigger"
( threshold "myvalue" > 3 )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].name).to eq 'MyTrigger'
    expect(t[:conditions].length).to eq 1
    c = t[:conditions].first
    expect(c).not_to be_nil
    expect(c.trigger_mode).to be :FIRING
    expect(c.type).to be :THRESHOLD
    expect(c.data_id).to eq 'myvalue'
    expect(c.threshold).to eq 3
    expect(c.operator).to be :GT
  end

  it 'should parse availability' do
    text = <<-EOT
define trigger "MyTrigger"
  enabled
  ( availability "mymetric" is DOWN )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].name).to eq 'MyTrigger'
    expect(t[:conditions].length).to eq 1
    c = t[:conditions].first
    expect(c).not_to be_nil
    expect(c.trigger_mode).to be :FIRING
    expect(c.type).to be :AVAILABILITY
    expect(c.data_id).to eq 'mymetric'
    expect(c.operator).to eq 'DOWN'
  end

end
