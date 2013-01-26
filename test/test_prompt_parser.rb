#!ruby

$:.unshift('..')
require 'test/unit'
require 'racc/parser'
require 'singleton_logger'
require 'errors'
require 'utils'
require 'parser/prompt'
require 'parser/prompt_parser82'
require 'parser/prompt_parser_core82'
require 'scanner/generic_scanner'

class TestPromptParser < Test::Unit::TestCase
  def setup
    @parser = Composer::Parser::PromptParser.new
		@parser.racc_debug(false)
		logger=Composer::SingletonLogger.instance
		logger.level=Logger::INFO
  end

	# sample01 on reference(testdata/0001)
  def test_parse_prompt_0001
		infile="./testdata/prompt_parser.in.0001"
		result=@parser.parse(infile)[:prompts]
		# prompt‚Í4ŒÂ’è‹`‚³‚ê‚Ä‚¢‚éB
    assert_equal(4, result.size)

		prompt=result.shift
    assert_equal('prmt1', prompt.name)
    assert_equal('"ready for job4? (y/n)"', prompt.value)

		prompt=result.shift
    assert_equal('prmt2', prompt.name)
    assert_equal('":job4 launched"', prompt.value)

		prompt=result.shift
    assert_equal('prmt3', prompt.name)
    assert_equal('"!continue?"', prompt.value)

		prompt=result.shift
    assert_equal('prmt4', prompt.name)
    assert_equal("\"this is multi line\nprompt.\nDo you understand?\"", prompt.value)
  end

end
