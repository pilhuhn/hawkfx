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
    expect(t[:trigger].enabled).to be_truthy
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
 disabled
 severity HIGH
 ( availability "myvalue" is DOWN )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].enabled).to be_falsey
    expect(t[:trigger].severity).to eq 'HIGH'
  end

  it 'should parse basic enabled, auto-disable' do
    text = <<-EOT
define trigger "MyTrigger"
 ( threshold "myvalue" > 3 )
 auto-disable
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].enabled).to be_truthy
    expect(t[:trigger].auto_disable).to be_truthy
    expect(t[:trigger].id).not_to be_nil
    expect(t[:trigger].severity).to eq 'MEDIUM'
  end

end

describe 'Condition Parsing' do
  it 'should parse threshold default gauge' do
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
    expect(c.data_id).to eq 'hm_g_myvalue'
    expect(c.threshold).to eq 3
    expect(c.operator).to be :GT
  end

  it 'should parse threshold explicit gauge' do
    text = <<-EOT
define trigger "MyTrigger"
( threshold gauge "myvalue" > 3 )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].name).to eq 'MyTrigger'
    expect(t[:conditions].length).to eq 1
    c = t[:conditions].first
    expect(c).not_to be_nil
    expect(c.trigger_mode).to be :FIRING
    expect(c.type).to be :THRESHOLD
    expect(c.data_id).to eq 'hm_g_myvalue'
    expect(c.threshold).to eq 3
    expect(c.operator).to be :GT
  end

  it 'should parse threshold explicit counter' do
    text = <<-EOT
define trigger "MyTrigger"
( threshold counter "myvalue" > 3 )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].name).to eq 'MyTrigger'
    expect(t[:conditions].length).to eq 1
    c = t[:conditions].first
    expect(c).not_to be_nil
    expect(c.trigger_mode).to be :FIRING
    expect(c.type).to be :THRESHOLD
    expect(c.data_id).to eq 'hm_c_myvalue'
    expect(c.threshold).to eq 3
    expect(c.operator).to be :GT
  end

  it 'should parse availability' do
    text = <<-EOT
define trigger "MyTrigger"
  ( availability "mymetric" is DOWN )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].name).to eq 'MyTrigger'
    expect(t[:conditions].length).to eq 1
    c = t[:conditions].first
    expect(c).not_to be_nil
    expect(c.trigger_mode).to be :FIRING
    expect(c.type).to be :AVAILABILITY
    expect(c.data_id).to eq 'hm_a_mymetric'
    expect(c.operator).to eq 'DOWN'
  end

  it 'should parse string' do
    text = <<-EOT
define trigger "MyTrigger"
  ( string "mymetric" CO "ERROR" )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].name).to eq 'MyTrigger'
    expect(t[:conditions].length).to eq 1
    c = t[:conditions].first
    expect(c).not_to be_nil
    expect(c.trigger_mode).to be :FIRING
    expect(c.type).to be :STRING
    expect(c.data_id).to eq 'hm_s_mymetric'
    expect(c.operator).to eq :CONTAINS
    expect(c.threshold).to eq 'ERROR' # TODO
  end

  it 'should parse threshold and string' do
    text = <<-EOT
define trigger "MyTrigger"
  AND(
    ( threshold counter "mycount" < 5 )
    ( string "mymetric" CO "ERROR" )
  )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].name).to eq 'MyTrigger'
    expect(t[:conditions].length).to eq 2
    c = t[:conditions].first
    expect(c).not_to be_nil
    expect(c.trigger_mode).to be :FIRING
    expect(c.type).to be :THRESHOLD
    expect(c.data_id).to eq 'hm_c_mycount'
    expect(c.operator).to eq :LT
    expect(c.threshold).to eq 5
  end

  it 'should parse threshold or availability' do
    text = <<-EOT
define trigger "MyTrigger"
  OR(
    ( threshold counter "mycount" < 5 )
    ( availability "mymetric" is NOT_UP )
  )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].name).to eq 'MyTrigger'
    expect(t[:conditions].length).to eq 2
    c = t[:conditions].first
    expect(c).not_to be_nil
    expect(c.trigger_mode).to be :FIRING
    expect(c.type).to be :THRESHOLD
    expect(c.data_id).to eq 'hm_c_mycount'
    expect(c.operator).to eq :LT
    expect(c.threshold).to eq 5
    c = t[:conditions].last
    expect(c).not_to be_nil
    expect(c.trigger_mode).to be :FIRING
    expect(c.type).to be :AVAILABILITY
  end

  it 'should parse threshold or availability or string' , :skip => true do
    text = <<-EOT
define trigger "MyTrigger"
  OR(
    ( threshold counter "mycount" < 5 )
    ( availability "mymetric" is NOT_UP )
    ( string "mystring" CO "HelloWorld" )
  )
    EOT
    t = AlertDefinitionParser.parse text
    expect(t[:trigger].name).to eq 'MyTrigger'
    expect(t[:conditions].length).to eq 3
  end

end

describe 'Action Parsing' do
  it 'should parse email' do
    text = <<-EOT
define trigger "MyTrigger"
( threshold "myvalue" > 3 )
send email to "hwr@bsd.de"
    EOT
    t = AlertDefinitionParser.parse text
    action = t[:actions].first
    expect(action).not_to be_nil
    id = action.action_id

    aDef = t[:actionDefs].first
    expect(aDef).not_to be_nil
    expect(aDef[:id]).to eq id
  end
end
