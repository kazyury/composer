#!ruby

$:.unshift('..')
require 'test/unit'
require 'racc/parser'
require 'singleton_logger'
require 'errors'
require 'utils'
require 'parser/job'
require 'parser/job_parser82'
require 'parser/job_parser_core82'
require 'scanner/generic_scanner'

class TestJobParser < Test::Unit::TestCase
  def setup
    @parser = Composer::Parser::JobParser.new
		@parser.racc_debug(false)
		logger=Composer::SingletonLogger.instance
		logger.level=Logger::INFO
  end

	# sample01 on reference(testdata/0001)
  def test_parse_job_0001
		infile="./testdata/job_parser.in.0001"
		result=@parser.parse(infile)[:jobs]
		# jobは2個定義されている。
    assert_equal(2, result.size)

		job=result.shift
    assert_equal('cpu1', job.wkstation)
    assert_equal('gl1', job.name)
    assert_equal('"/usr/acct/scripts/gl1"', job.scriptname)
    assert_equal('acct', job.streamlogon)
    assert_equal('"general ledger job1"', job.description)

		job=result.shift
    assert_equal('bkup', job.name)
    assert_equal('"/usr/mis/scripts/bkup"', job.scriptname)
    assert_equal('"^mis^"', job.streamlogon)
    assert_equal('continue', job.recovery)
    assert_equal('recjob1', job.recovery_job_name)
  end

	# all directives in reference(testdata/full)
  def test_parse_job_full
		infile="./testdata/job_parser.in.full"
		result=@parser.parse(infile)[:jobs]
		# jobは2個定義されている。
    assert_equal(3, result.size)

		job=result.shift
    assert_equal('cpu1', job.wkstation)
    assert_equal('gl1', job.name)
    assert_equal('"/usr/acct/scripts/gl1"', job.scriptname)
    assert_equal('"C:\Hidemaru.exe %1"', job.docommand)
    assert_equal('acct', job.streamlogon)
    assert_equal('"general ledger job1"', job.description)
    assert_equal(true, job.interactive)
    assert_equal('"(RC=3) OR ((RC>=5) AND (RC<10))"', job.rccondsucc)
    assert_equal('stop', job.recovery)
		assert_equal('SomeHost',job.recovery_job_wkstation)
		assert_equal('SomeJob1',job.recovery_job_name)
		assert_equal('"! abended."',job.abendprompt)

		job=result.shift
    assert_equal('cpu2', job.wkstation)
    assert_equal('gl2', job.name)
    assert_equal('"/usr/acct/scripts/gl2"', job.scriptname)
    assert_equal('"C:\Hidemaru.exe %2"', job.docommand)
    assert_equal('acct', job.streamlogon)
    assert_equal('"general ledger job2"', job.description)
    assert_equal(true, job.interactive)
    assert_equal('"(RC=3) OR ((RC>=5) AND (RC<10))"', job.rccondsucc)
    assert_equal('continue', job.recovery)
		assert_equal('SomeHost',job.recovery_job_wkstation)
		assert_equal('SomeJob1',job.recovery_job_name)
		assert_equal('": abended."',job.abendprompt)

		job=result.shift
    assert_equal('cpu3', job.wkstation)
    assert_equal('gl3', job.name)
    assert_equal('"/usr/acct/scripts/gl3"', job.scriptname)
    assert_equal('"C:\Hidemaru.exe %3"', job.docommand)
    assert_equal('acct', job.streamlogon)
    assert_equal('"general ledger job3"', job.description)
    assert_equal(true, job.interactive)
    assert_equal('"(RC=3) OR ((RC>=5) AND (RC<10))"', job.rccondsucc)
    assert_equal('rerun', job.recovery)
		assert_equal('SomeHost',job.recovery_job_wkstation)
		assert_equal('SomeJob1',job.recovery_job_name)
		assert_equal('"abended."',job.abendprompt)
	end

end
