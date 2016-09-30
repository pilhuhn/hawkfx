require "#{File.dirname(__FILE__)}/spec_helper"
require 'metric_expression_parser'


describe 'Basic Parsing' do

  it 'should parse basic' do
    expect(MetricExpressionParser.parse('42')).to eq 42
    expect(MetricExpressionParser.parse('(42)')).to be 42
    expect(MetricExpressionParser.parse('(+ 1 2)')).to be 3
    expect(MetricExpressionParser.parse('(+
                                            1
                                            2)')).to be 3
    expect(MetricExpressionParser.parse('(+ 12 42)')).to be 54
    expect(MetricExpressionParser.parse('(+ 1 (* 2 3))')).to be 7
    expect(MetricExpressionParser.parse('(- 10 6')).to be 4
  end

  it 'Should parse float'  do
    expect(MetricExpressionParser.parse('1.2')).to eq 1.2
    expect(MetricExpressionParser.parse('(+ 1.2 2.3)')).to eq 3.5
    expect(MetricExpressionParser.parse('(+ 1 2.3)')).to eq 3.3
    expect(MetricExpressionParser.parse('(+ 1.2 2)')).to eq 3.2
  end

  it 'Should create numbers array' do
    res = MetricExpressionParser.parse('(toa( 33))')
    expect(res.size).to be 120
    expect(res[0][:avg]).to eq 33
    expect(res[119][:avg]).to eq 33
  end

  it 'should parse simple metric' do
    res = MetricExpressionParser.parse('metric("bla", "avg")')
    expect(res.size).to be 120
    expect(res[0][:avg]).to be 42
  end

  it 'should parse list_scalar arithmetic' do
    res = MetricExpressionParser.parse('(- 1000 metric("bla", "avg"))')
    expect(res.size).to be 120
    expect(res[0][:avg]).to eq 958

    res = MetricExpressionParser.parse('(+ metric("bla", "avg") 2000)')
    expect(res.size).to be 120
    expect(res[0][:avg]).to eq 2042

    res = MetricExpressionParser.parse('(/ 420 metric("bla", "avg"))')
    expect(res.size).to be 120
    expect(res[0][:avg]).to be 10
  end

  it 'should parse list_list arithmetic' do
    res = MetricExpressionParser.parse('(+ metric("bla","max") metric("bla", "min"))')
    expect(res.size).to be 120
    expect(res[0][:avg]).to be 49
  end

  it 'should parse with newlines' do
    text = '(+ metric( "MI~R~[516ecc12-cbb6-40c9-baeb-a2c97474e77b/Local~~]~MT~WildFly Memory Metrics~Heap Used" , "max")
                   metric( "MI~R~[516ecc12-cbb6-40c9-baeb-a2c97474e77b/Local~~]~MT~WildFly Memory Metrics~NonHeap Used", "max"))'

    MetricExpressionParser.parse(text)
  end

  it 'should parse with newlines2', :skip=>true do
    text = '(+
  metric( "metric1" , "max")
  metric( "metric2", "max")
)'

    MetricExpressionParser.parse(text)
  end

  it 'should sum up' do
    text = '(sumup(metric( "MI~R~[516ecc12-cbb6-40c9-baeb-a2c97474e77b/Local~~]~MT~WildFly Memory Metrics~Heap Used" , "max")))'
    res = MetricExpressionParser.parse(text)
    expect(res).to be 42*120

    res = MetricExpressionParser.parse('(sumup( toa( 33)))')
    expect(res).to be 33*120
  end

  it 'should parse var'  do
    env = {}
    MetricExpressionParser.parse('var $a = "bla"', env)
    expect(env).not_to be nil
    expect(env.size).to eq 3
    expect(env.key? :vars).to be_truthy
    expect(env[:vars].key? '$a').to be true
    expect(env[:vars]['$a']).to eq 'bla'
  end

  it 'should parse two vars', :skip => true  do
    env = {}
    MetricExpressionParser.parse(
        'var $a = "bla"
         var $b = "foo"
', env)
    expect(env).not_to be nil
    expect(env.size).to eq 3
    expect(env.key? :vars).to be_truthy
    expect(env[:vars].key? '$a').to be true
    expect(env[:vars]['$a']).to eq 'bla'
    expect(env[:vars].key? '$b').to be true
    expect(env[:vars]['$b']).to eq 'foo'
  end

  it 'should parse varRef' do
    text = 'var $a = "bla"
            metric($a, "max")'
    res = MetricExpressionParser.parse(text)
    expect(res.size).to be 120
  end

end
