#!ruby

$:.unshift('..')
require 'test/unit'
require 'frontend'

class TestSchedulingCalendar < Test::Unit::TestCase
  def setup
		@composer = Composer::FrontEnd.new
		@composer.log_level=Logger::DEBUG
		@composer.tws_level='8.2'
		@composer.use_cache=true
		@composer.calendars_def='testdata\scheduling_calendar_cal.in.0001'
		@composer.schedules_def='testdata\scheduling_calendar_sch.in.0001'
		@composer.parse()
		@composer.face='stream_plan'
  end

  def test_scheduling_calendar001
			@composer.prepare(:visible=,true)
			@composer.prepare(:range_set,'1999-01-21','1999-2-21')
			@composer.convert
		assert_equal('','')
  end

end
