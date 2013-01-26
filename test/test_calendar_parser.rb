#!ruby

$:.unshift('..')
require 'test/unit'
require 'racc/parser'
require 'singleton_logger'
require 'errors'
require 'utils'
require 'parser/calendar'
require 'parser/calendar_parser82'
require 'parser/calendar_parser_core82'
require 'scanner/generic_scanner'

class TestCalendarParser < Test::Unit::TestCase
  def setup
    @parser = Composer::Parser::CalendarParser.new
		@parser.racc_debug(false)
		logger=Composer::SingletonLogger.instance
		logger.level=Logger::INFO
  end

	# sample01 on reference(testdata/0001)
  def test_parse_calendar_0001
		infile="./testdata/calendar_parser.in.0001"
		result=@parser.parse(infile)[:calendars]
		# calendar‚Í2ŒÂ’è‹`‚³‚ê‚Ä‚¢‚éB
    assert_equal(2, result.size)

		calendar=result.shift
    assert_equal('monthend', calendar.name)
		assert_equal('"Month end dates 1st half \'99"', calendar.description)
    assert_equal(%w( 01/31/99 02/28/99 03/31/99 04/30/99 05/31/99 06/30/99 ), calendar.date)
    assert_equal(6, calendar.date_internal.size)

		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,1,31) , idate)
		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,2,28) , idate)
		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,3,31) , idate)
		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,4,30) , idate)
		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,5,31) , idate)
		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,6,30) , idate)

		calendar=result.shift
    assert_equal('paydays', calendar.name)
    assert_equal(%w( 01/15/99 02/15/99 03/15/99 04/15/99 05/14/99 06/15/99 ), calendar.date)
    assert_equal(6, calendar.date_internal.size)

		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,1,15) , idate)
		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,2,15) , idate)
		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,3,15) , idate)
		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,4,15) , idate)
		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,5,14) , idate)
		idate=calendar.date_internal.shift
		assert_equal(Date.new(1999,6,15) , idate)
  end

end
