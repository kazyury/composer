#!ruby

$:.unshift('..')
require 'test/unit'
require 'frontend'

class TestDefaultFace < Test::Unit::TestCase
  def setup
		@composer = Composer::FrontEnd.new
		@composer.log_level=Logger::INFO
		@composer.use_cache=true
		@composer.calendars_def='testdata\calendar_parser.in.real'
		@composer.parameters_def='testdata\parameter_parser.in.0001'
		@composer.prompts_def='testdata\prompt_parser.in.0001'
		@composer.resources_def='testdata\resource_parser.in.0001'
		@composer.jobs_def='testdata\job_parser.in.full'
		@composer.workstations_def='testdata\workstation_parser.in.full'
		@composer.schedules_def='test\testdata\schedule_parser.in.full'
		@composer.parse()
		@face=@composer.face
  end

	#default_calendar
  def test_default_calendar
		assert_nothing_raised{
			@composer.pre_conversion(:add_template,'default_calendar')
			@composer.convert
		}
  end

	#default_parameter
  def test_default_parameter
		assert_nothing_raised{
			@composer.pre_conversion(:add_template,'default_parameter')
			@composer.convert
		}
  end

	#default_prompt
  def test_default_prompt
		assert_nothing_raised{
			@composer.pre_conversion(:add_template,'default_prompt')
			@composer.convert
		}
  end

	#default_resource
  def test_default_resource
		assert_nothing_raised{
			@composer.pre_conversion(:add_template,'default_resource')
			@composer.convert
		}
  end

	#default_job
  def test_default_job
		assert_nothing_raised{
			@composer.pre_conversion(:add_template,'default_job')
			@composer.convert
		}
  end

	#default_cpuname
  def test_default_cpuname
		assert_nothing_raised{
			@composer.pre_conversion(:add_template,'default_cpuname')
			@composer.convert
		}
  end

	#default_cpuclass
  def test_default_cpuclass
		assert_nothing_raised{
			@composer.pre_conversion(:add_template,'default_cpuclass')
			@composer.convert
		}
  end

	#default_domain
  def test_default_domain
		assert_nothing_raised{
			@composer.pre_conversion(:add_template,'default_domain')
			@composer.convert
		}
  end

	#default_schedule
  def test_default_schedule
		assert_nothing_raised{
			@composer.pre_conversion(:add_template,'default_schedule')
			@composer.convert
		}
  end
end
