#!ruby

$:.unshift('..')
require 'test/unit'
require 'racc/parser'
require 'singleton_logger'
require 'errors'
require 'utils'
require 'parser/parameter'
require 'parser/parameter_parser82'
require 'parser/parameter_parser_core82'
require 'scanner/generic_scanner'

class TestParameterParser < Test::Unit::TestCase
  def setup
    @parser = Composer::Parser::ParameterParser.new
		@parser.racc_debug(false)
		logger=Composer::SingletonLogger.instance
		logger.level=Logger::INFO
  end

	# sample01 on reference(testdata/0001)
  def test_parse_parameter_0001
		infile="./testdata/parameter_parser.in.0001"
		result=@parser.parse(infile)[:parameters]
		# parameter‚Í2ŒÂ’è‹`‚³‚ê‚Ä‚¢‚éB
    assert_equal(2, result.size)

		parameter=result.shift
    assert_equal('glpath', parameter.name)
    assert_equal('"/glfiles/daily"', parameter.value)

		parameter=result.shift
    assert_equal('gllogon', parameter.name)
    assert_equal('"gluser"', parameter.value)
  end

end
