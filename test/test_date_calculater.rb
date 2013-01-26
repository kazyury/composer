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
require 'parser/job'
require 'parser/job_parser82'
require 'parser/job_parser_core82'
require 'parser/resource'
require 'parser/resource_parser82'
require 'parser/resource_parser_core82'
require 'parser/schedule'
require 'parser/schedule_parser82'
require 'parser/schedule_parser_core82'
require 'scanner/generic_scanner'
require 'scanner/mode_switchable_scanner'

class TestDateCalculater < Test::Unit::TestCase
  def setup
    @sparser = Composer::Parser::ScheduleParser.new
		@sparser.racc_debug(false)
    @cparser = Composer::Parser::CalendarParser.new
		@cparser.racc_debug(false)
		logger=Composer::SingletonLogger.instance
		logger.level=Logger::INFO
  end

	#mm/dd/yy 単数指定
  def test_date_calc0001
		infile="./testdata/date_calc.sch.in.0001"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([Date.new(2007,4,3)],calc.calculate)
	end

	#mm/dd/yy 複数指定
  def test_date_calc0002
		infile="./testdata/date_calc.sch.in.0002"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([Date.new(2007,4,3),Date.new(2007,4,4),Date.new(2007,4,5),Date.new(2007,4,6)],calc.calculate)
	end
	
	#mm/dd/yy 複数指定(EXCEPT)
  def test_date_calc0003
		infile="./testdata/date_calc.sch.in.0003"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([Date.new(2007,4,3),Date.new(2007,4,6)],calc.calculate)
	end

	#リテラル指定(SU)
  def test_date_calc0004
		infile="./testdata/date_calc.sch.in.0004"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([Date.new(2007,4,1),Date.new(2007,4,6),Date.new(2007,4,8),Date.new(2007,4,15),Date.new(2007,4,22),Date.new(2007,4,29)],calc.calculate)
	end

	#リテラル指定(MO)
  def test_date_calc0005
		infile="./testdata/date_calc.sch.in.0005"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([Date.new(2007,4,2),Date.new(2007,4,6),Date.new(2007,4,9),Date.new(2007,4,16),Date.new(2007,4,23),Date.new(2007,4,30)],calc.calculate)
	end

	#リテラル指定(TU)
  def test_date_calc0006
		infile="./testdata/date_calc.sch.in.0006"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([Date.new(2007,4,3),Date.new(2007,4,4),Date.new(2007,4,10),Date.new(2007,4,11),Date.new(2007,4,17),Date.new(2007,4,18),Date.new(2007,4,24),Date.new(2007,4,25),Date.new(2007,5,1)],calc.calculate)
	end

	#リテラル指定(WE,TH,FR,SA)
  def test_date_calc0007
		infile="./testdata/date_calc.sch.in.0007"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([Date.new(2007,3,31),
								 Date.new(2007,4,1),
								 Date.new(2007,4,2),
								 Date.new(2007,4,3),
								 Date.new(2007,4,4),
								 Date.new(2007,4,5),
								 Date.new(2007,4,6),
								 Date.new(2007,4,7),
								 Date.new(2007,4,15),
								 Date.new(2007,4,16),
								 Date.new(2007,4,17),
								 Date.new(2007,4,18),
								 Date.new(2007,4,19),
								 Date.new(2007,4,20),
								 Date.new(2007,4,21),
								 Date.new(2007,4,29),
								 Date.new(2007,4,30),
								 Date.new(2007,5,1) ],calc.calculate)
	end

	#リテラル指定(EVERYDAY)
  def test_date_calc0008
		infile="./testdata/date_calc.sch.in.0008"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([Date.new(2007,3,31),
								 Date.new(2007,4,1),
								 Date.new(2007,4,2),
								 Date.new(2007,4,3),
								 Date.new(2007,4,4),
								 Date.new(2007,4,5),
								 Date.new(2007,4,6),
								 Date.new(2007,4,7),
								 Date.new(2007,4,15),
								 Date.new(2007,4,16),
								 Date.new(2007,4,17),
								 Date.new(2007,4,18),
								 Date.new(2007,4,19),
								 Date.new(2007,4,20),
								 Date.new(2007,4,21),
								 Date.new(2007,4,29),
								 Date.new(2007,4,30),
								 Date.new(2007,5,1) ],calc.calculate)
	end

	#リテラル指定(WEEKDAYS)
  def test_date_calc0009
		infile="./testdata/date_calc.sch.in.0009"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([ Date.new(2007,4,2),
								 Date.new(2007,4,3),
								 Date.new(2007,4,4),
								 Date.new(2007,4,5),
								 Date.new(2007,4,6),
								 Date.new(2007,4,16),
								 Date.new(2007,4,17),
								 Date.new(2007,4,18),
								 Date.new(2007,4,19),
								 Date.new(2007,4,20),
								 Date.new(2007,4,30),
								 Date.new(2007,5,1) ],calc.calculate)
	end

	#リテラル指定(WORKDAYS - FREEDAYS指定なし。)
  def test_date_calc0010
		infile="./testdata/date_calc.sch.in.0010"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([ Date.new(2007,4,2),
								 Date.new(2007,4,3),
								 Date.new(2007,4,4),
								 Date.new(2007,4,5),
								 Date.new(2007,4,6),
								 Date.new(2007,4,16),
								 Date.new(2007,4,17),
								 Date.new(2007,4,18),
								 Date.new(2007,4,19),
								 Date.new(2007,4,20),
								 Date.new(2007,5,1) ],calc.calculate)
	end

	#リテラル指定(WORKDAYS - FREEDAYS指定有り。オプションなし。)
  def test_date_calc0011
		infile="./testdata/date_calc.sch.in.0011"
		schedules=@sparser.parse(infile)[:schedules]
		infile="./testdata/date_calc.cal.in.0001"
		calendars=@cparser.parse(infile)[:calendars]
		calc=Composer::DateCalculater.new(schedules.first,Date.new(2007,3,31),Date.new(2007,5,1),calendars)
		assert_equal([ Date.new(2007,4,2),
								 Date.new(2007,4,3),
								 Date.new(2007,4,4),
								 Date.new(2007,4,5),
								 Date.new(2007,4,6),
								 Date.new(2007,4,16),
								 Date.new(2007,4,17),
								 Date.new(2007,4,18),
								 Date.new(2007,4,19),
								 Date.new(2007,4,20),
								 Date.new(2007,4,30),
								 Date.new(2007,5,1) ],calc.calculate)
	end
end
