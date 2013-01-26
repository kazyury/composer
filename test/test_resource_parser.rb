#!ruby

$:.unshift('..')
require 'test/unit'
require 'racc/parser'
require 'singleton_logger'
require 'errors'
require 'utils'
require 'parser/resource'
require 'parser/resource_parser82'
require 'parser/resource_parser_core82'
require 'scanner/generic_scanner'

class TestResourceParser < Test::Unit::TestCase
  def setup
    @parser = Composer::Parser::ResourceParser.new
		@parser.racc_debug(false)
		logger=Composer::SingletonLogger.instance
		logger.level=Logger::INFO
  end

	# sample01 on reference(testdata/0001)
  def test_parse_resource_0001
		infile="./testdata/resource_parser.in.0001"
		result=@parser.parse(infile)[:resources]
		# resource‚Í4ŒÂ’è‹`‚³‚ê‚Ä‚¢‚éB
    assert_equal(4, result.size)

		resource=result.shift
    assert_equal('ux1', resource.wkstation)
    assert_equal('tapes', resource.name)
    assert_equal('3', resource.units)
    assert_equal('"tape units"', resource.description)

		resource=result.shift
    assert_equal('ux1', resource.wkstation)
    assert_equal('jobslots', resource.name)
    assert_equal('24', resource.units)
    assert_equal('"job slots"', resource.description)

		resource=result.shift
    assert_equal('ux2', resource.wkstation)
    assert_equal('tapes', resource.name)
    assert_equal('2', resource.units)
    assert_nil(resource.description)

		resource=result.shift
    assert_equal('ux2', resource.wkstation)
    assert_equal('jobslots', resource.name)
    assert_equal('16', resource.units)
    assert_equal('"job slots"', resource.description)

  end

end
