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
require 'parser/resource'
require 'parser/resource_parser82'
require 'parser/resource_parser_core82'
require 'parser/schedule'
require 'parser/schedule_parser82'
require 'parser/schedule_parser_core82'
require 'scanner/generic_scanner'
require 'scanner/mode_switchable_scanner'

class TestScheduleParser < Test::Unit::TestCase
  def setup
    @parser = Composer::Parser::ScheduleParser.new
		@parser.racc_debug(false)
		logger=Composer::SingletonLogger.instance
		logger.level=Logger::INFO
  end

	# sample01 on reference(testdata/0001)
  def test_parse_schedule_0001
		infile="./testdata/schedule_parser.in.0001"
		result=@parser.parse(infile)[:schedules]
		# scheduleは1個定義されている。
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sked7', schedule.name)

    assert_equal(1, schedule.on.size)
		on=schedule.on.shift
		assert_equal('tu',on.value)

    assert_equal(1, schedule.at.size)
		at=schedule.at.shift
		assert_equal('0300',at.value)

    assert_equal(2, schedule.jobs.size)
		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)
		job2=schedule.jobs.shift
		assert_equal('job2',job2.name)
  end
	
	# sample02 on reference(testdata/0002)
  def test_parse_schedule_0002
		infile="./testdata/schedule_parser.in.0002"
		result=@parser.parse(infile)[:schedules]
		# scheduleは1個定義されている。
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sfran', schedule.wkstation)
    assert_equal('sked8', schedule.name)

    assert_equal(1, schedule.on.size)
		on=schedule.on.shift
		assert_equal('fr',on.value)

    assert_equal(1, schedule.at.size)
		at=schedule.at.shift
		assert_equal('1000',at.value)
		assert_equal('+ 1 day',at.offset)

    assert_equal(3, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)

		job2=schedule.jobs.shift
		assert_equal('job2',job2.name)
		assert_equal(1,job2.at.size)
		at=job2.at.shift
		assert_equal('1400',at.value)
		assert_equal('est',at.timezone)

		job3=schedule.jobs.shift
		assert_equal('nycity',job3.wkstation)
		assert_equal('job3',job3.name)
		assert_equal(1,job3.at.size)
		at=job3.at.shift
		assert_equal('1600',at.value)
  end

	# sample03 on reference(testdata/0003)
  def test_parse_schedule_0003
		infile="./testdata/schedule_parser.in.0003"
		result=@parser.parse(infile)[:schedules]
		# scheduleは1個定義されている。
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sked43', schedule.name)
		assert_equal(true,schedule.carryforward)

    assert_equal(1, schedule.on.size)
		on=schedule.on.shift
		assert_equal('th',on.value)

    assert_equal(3, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('job12',job1.name)
		job2=schedule.jobs.shift
		assert_equal('job13',job2.name)
		job3=schedule.jobs.shift
		assert_equal('job13a',job3.name)
  end

	# sample04 on reference(testdata/0004)
  def test_parse_schedule_0004
		infile="./testdata/schedule_parser.in.0004"
		result=@parser.parse(infile)[:schedules]
		# scheduleは1個定義されている。
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('wkend', schedule.name)
		assert_equal(true,schedule.carryforward)
		assert_equal("****************************************\n* The weekly cleanup jobs \n****************************************\n*",schedule.comment)

    assert_equal(1, schedule.on.size)
		on=schedule.on.shift
		assert_equal('fr',on.value)

    assert_equal(1, schedule.at.size)
		at=schedule.at.shift
		assert_equal('1830',at.value)
		
    assert_equal(2, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)
		job2=schedule.jobs.shift
		assert_equal('job2',job2.name)
  end

	# sample05 on reference(testdata/0005)
  def test_parse_schedule_0005
		infile="./testdata/schedule_parser.in.0005"
		result=@parser.parse(infile)[:schedules]
		# scheduleは1個定義されている。
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('test1', schedule.name)

    assert_equal(1, schedule.on.size)
		on=schedule.on.shift
		assert_equal('fr',on.value)

    assert_equal(3, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)
		assert_equal(true,job1.confirmed)
		job2=schedule.jobs.shift
		assert_equal('job2',job2.name)
		assert_equal(1,job2.follows.size)
		follow=job2.follows.shift
		assert_equal('job1',follow.job)

		job3=schedule.jobs.shift
		assert_equal('job3',job3.name)
		assert_equal(1,job3.follows.size)
		follow=job3.follows.shift
		assert_equal('job1',follow.job)
  end

	# sample06 on reference(testdata/0006)
  def test_parse_schedule_0006
		infile="./testdata/schedule_parser.in.0006"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sked7', schedule.name)

    assert_equal(1, schedule.on.size)
		on=schedule.on.shift
		assert_equal('everyday',on.value)

    assert_equal(1, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('jobc',job1.name)
		assert_equal(1,job1.at.size)
		at=job1.at.shift
		assert_equal('1430',at.value)
		assert_equal(1,job1.deadline.size)
		deadline=job1.deadline.shift
		assert_equal('1600',deadline.value)
  end

	# sample07 on reference(testdata/0007)
  def test_parse_schedule_0007
		infile="./testdata/schedule_parser.in.0007"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('test1', schedule.name)

    assert_equal(1, schedule.on.size)
		on=schedule.on.shift
		assert_equal('monthend',on.value)

    assert_equal(3, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)
		job2=schedule.jobs.shift
		assert_equal('job2',job2.name)
		job3=schedule.jobs.shift
		assert_equal('job3',job3.name)
  end

	# sample08 on reference(testdata/0008)
  def test_parse_schedule_0008
		infile="./testdata/schedule_parser.in.0008"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('bkup', schedule.name)

    assert_equal(1, schedule.on.size)
		on=schedule.on.shift
		assert_equal('fr',on.value)

    assert_equal(1, schedule.at.size)
		at=schedule.at.shift
		assert_equal('fr',on.value)

    assert_equal(3, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('cpu1',job1.wkstation)
		assert_equal('jbk1',job1.name)
		job2=schedule.jobs.shift
		assert_equal('cpu2',job2.wkstation)
		assert_equal('jbk2',job2.name)
		assert_equal(1,job2.needs.size)
		needs=job2.needs.shift
		assert_equal('1',needs.units)
		assert_equal('tape',needs.name)
		job3=schedule.jobs.shift
		assert_equal('cpu3',job3.wkstation)
		assert_equal('jbk3',job3.name)
		assert_equal(1,job3.follows.size)
		follows=job3.follows.shift
		assert_equal('jbk1',follows.job)
  end

	# sample09 on reference(testdata/0009)
  def test_parse_schedule_0009
		infile="./testdata/schedule_parser.in.0009"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sked4', schedule.name)

    assert_equal(1, schedule.on.size)
		on=schedule.on.shift
		assert_equal('mo',on.value)

    assert_equal(2, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)
		assert_equal('"d:\apps\maestro\scripts\jcljob1"',job1.scriptname)
		assert_equal('jack',job1.streamlogon)
		assert_equal('stop',job1.recovery)
		assert_equal('"continue production"',job1.abendprompt)

		job2=schedule.jobs.shift
		assert_equal('site1',job2.wkstation)
		assert_equal('job2',job2.name)
		assert_equal('"d:\apps\maestro\scripts\jcljob2"',job2.scriptname)
		assert_equal('jack',job2.streamlogon)
		assert_equal('job1',job2.follows.shift.job)
  end

	# sample10 on reference(testdata/0010)
  def test_parse_schedule_0010
		infile="./testdata/schedule_parser.in.0010"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('cpu1', schedule.wkstation)
    assert_equal('sched1', schedule.name)
    assert_equal(true, schedule.keysched)

    assert_equal(1, schedule.on.size)
		on=schedule.on.shift
		assert_equal('everyday',on.value)

    assert_equal(1, schedule.at.size)
		at=schedule.at.shift
		assert_equal('0100',at.value)

    assert_equal(1, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('cpu1',job1.wkstation)
		assert_equal('myjob1',job1.name)
		assert_equal(true,job1.keyjob)
  end

	# sample11 on reference(testdata/0011)
  def test_parse_schedule_0011
		infile="./testdata/schedule_parser.in.0011"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sked4', schedule.name)

    assert_equal(3, schedule.on.size)
		assert_equal('mo',schedule.on.shift.value)
		assert_equal('we',schedule.on.shift.value)
		assert_equal('fr',schedule.on.shift.value)

    assert_equal(4, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('joba',job1.name)
		assert_equal(1,job1.needs.size)
		assert_equal('1',job1.needs.first.units)
		assert_equal('jlimit',job1.needs.first.name)

		job2=schedule.jobs.shift
		assert_equal('jobb',job2.name)
		assert_equal(1,job2.needs.size)
		assert_equal('1',job2.needs.first.units)
		assert_equal('jlimit',job2.needs.first.name)

		job3=schedule.jobs.shift
		assert_equal('jobc',job3.name)
		assert_equal(1,job3.needs.size)
		assert_equal('2',job3.needs.first.units)
		assert_equal('jlimit',job3.needs.first.name)

		job4=schedule.jobs.shift
		assert_equal('jobd',job4.name)
		assert_equal(1,job4.needs.size)
		assert_equal('1',job4.needs.first.units)
		assert_equal('jlimit',job4.needs.first.name)
  end

	# sample12 on reference(testdata/0012)
  def test_parse_schedule_0012
		infile="./testdata/schedule_parser.in.0012"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sked1', schedule.name)

    assert_equal(1, schedule.on.size)
		assert_equal('tu',schedule.on.shift.value)

    assert_equal(2, schedule.jobs.size)

		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)
		assert_equal('15',job1.priority)

		job2=schedule.jobs.shift
		assert_equal('job2',job2.name)
		assert_equal('10',job2.priority)
  end

	# sample13 on reference(testdata/0013)
  def test_parse_schedule_0013
		infile="./testdata/schedule_parser.in.0013"
		result=@parser.parse(infile)[:schedules]
    assert_equal(2, result.size)

		schedule=result.shift
    assert_equal('sked3', schedule.name)
    assert_equal(2, schedule.on.size)
		assert_equal('tu',schedule.on.shift.value)
		assert_equal('th',schedule.on.shift.value)
    assert_equal(1, schedule.prompts.size)
    assert_equal('"All ap users logged out of ^sys1^? (y/n)"', schedule.prompts.shift)

    assert_equal(2, schedule.jobs.size)
		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)
		assert_equal('apmsg',job1.prompts.shift)
		job2=schedule.jobs.shift
		assert_equal('job2',job2.name)
		assert_equal('apmsg',job2.prompts.shift)

		schedule=result.shift
    assert_equal('sked5', schedule.name)
    assert_equal(1, schedule.on.size)
		assert_equal('fr',schedule.on.shift.value)
    assert_equal(1, schedule.prompts.size)
    assert_equal("\"The jobs in this job stream consume \nan enormous amount of cpu time.\nDo you want to launch it now? (y/n)\"", schedule.prompts.shift)

    assert_equal(2, schedule.jobs.size)
		job1=schedule.jobs.shift
		assert_equal('j1',job1.name)
		job2=schedule.jobs.shift
		assert_equal('j2',job2.name)
		assert_equal('j1',job2.follows.shift.job)
  end

	# sample14 on reference(testdata/0014)
  def test_parse_schedule_0014
		infile="./testdata/schedule_parser.in.0014"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sked2', schedule.name)
    assert_equal(1, schedule.on.size)
		assert_equal('weekdays',schedule.on.shift.value)

    assert_equal(1, schedule.jobs.size)
		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)
		assert_equal('1300',job1.at.shift.value)
		assert_equal('1700',job1.until.shift.value)
  end

	# sample15 on reference(testdata/0015)
  def test_parse_schedule_0015
		infile="./testdata/schedule_parser.in.0015"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sked3', schedule.name)
    assert_equal(1, schedule.on.size)
		assert_equal('mo',schedule.on.shift.value)

    assert_equal(1, schedule.jobs.size)
		job1=schedule.jobs.shift
		assert_equal('joba',job1.name)
		assert_equal('0015',job1.every)
		assert_equal('2330',job1.until.shift.value)
  end

	# sample16 on reference(testdata/0016)
  def test_parse_schedule_0016
		infile="./testdata/schedule_parser.in.0016"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sked4', schedule.name)
    assert_equal(1, schedule.on.size)
		assert_equal('fr',schedule.on.shift.value)

    assert_equal(1, schedule.at.size)
		at=schedule.at.shift
		assert_equal('0800',at.value)
		assert_equal('+ 2 days',at.offset)

    assert_equal(1, schedule.until.size)
		unt=schedule.until.shift
		assert_equal('1300',unt.value)
		assert_equal('+ 2 days',unt.offset)

    assert_equal(3, schedule.jobs.size)
		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)
		job2=schedule.jobs.shift
		assert_equal('job2',job2.name)
		assert_equal('0900',job2.at.shift.value)
		job3=schedule.jobs.shift
		assert_equal('job3',job3.name)
		assert_equal('1200',job3.at.shift.value)
		assert_equal('job2',job3.follows.shift.job)
  end

	# sample17 on reference(testdata/0017)
  def test_parse_schedule_0017
		infile="./testdata/schedule_parser.in.0017"
		result=@parser.parse(infile)[:schedules]
    assert_equal(1, result.size)

		schedule=result.shift
    assert_equal('sked8', schedule.name)
    assert_equal(1, schedule.on.size)
		assert_equal('weekdays',schedule.on.shift.value)
    assert_equal(1, schedule.at.size)
    assert_equal('1600', schedule.at.shift.value)
    assert_equal(1, schedule.deadline.size)
    assert_equal('1700', schedule.deadline.shift.value)

    assert_equal(2, schedule.jobs.size)
		job1=schedule.jobs.shift
		assert_equal('job1',job1.name)
    assert_equal(1, job1.at.size)
    assert_equal('1600', job1.at.shift.value)
    assert_equal(1, job1.until.size)
    assert_equal('1620', job1.until.shift.value)
		assert_equal('cont', job1.onuntil)

		job2=schedule.jobs.shift
		assert_equal('job2',job2.name)
    assert_equal(1, job2.at.size)
    assert_equal('1630', job2.at.shift.value)
    assert_equal(1, job2.until.size)
    assert_equal('1650', job2.until.shift.value)
		assert_equal('canc', job2.onuntil)
  end

	# sample18 on reference(testdata/0018)
  def test_parse_schedule_0018
		infile="./testdata/schedule_parser.in.0018"
		result=@parser.parse(infile)[:schedules]
    assert_equal(3, result.size)

		schedule=result.shift
    assert_equal('sked01', schedule.name)
		assert_equal('everyday',schedule.on.shift.value)
		job=schedule.jobs.shift
		assert_equal('job01',job.name)
    assert_equal('2035', job.until.shift.value)
		assert_equal('suppr', job.onuntil)

		schedule=result.shift
    assert_equal('sked02', schedule.name)
		assert_equal('everyday',schedule.on.shift.value)
		follow=schedule.follows.shift
		assert_equal('sked01',follow.stream)
		assert_equal('@',follow.job)
		job=schedule.jobs.shift
		assert_equal('job02',job.name)

		schedule=result.shift
    assert_equal('sked03', schedule.name)
		assert_equal('everyday',schedule.on.shift.value)
		follow=schedule.follows.shift
		assert_equal('sked01',follow.stream)
		assert_equal('JTEST',follow.job)
		job=schedule.jobs.shift
		assert_equal('job03',job.name)

  end

	# full path
  def test_parse_schedule_full
		infile="./testdata/schedule_parser.in.full"
		result=@parser.parse(infile)[:schedules]
    assert_equal(2, result.size)

		schedule=result.shift
    assert_equal("* this is full-path of \n* schedule def test case.", schedule.comment)
    assert_equal('twshost01', schedule.wkstation)
    assert_equal('sched01', schedule.name)
    assert_equal('GERMHOL', schedule.freedays_cal)
    assert_equal('-sa', schedule.freedays_opt.first)
    assert_equal('-su', schedule.freedays_opt.last)
		assert_equal(4,schedule.on.size)
		on=schedule.on.shift
		assert_equal('mo',on.value)
		assert_equal('fdnext',on.fdrule)
		on=schedule.on.shift
		assert_equal('12/29/01',on.value)
		assert_equal('fdnext',on.fdrule)
		on=schedule.on.shift
		assert_equal('fr',on.value)
		assert_equal('fdprev',on.fdrule)
		on=schedule.on.shift
		assert_equal('monthend',on.value)
		assert_equal('- 2 weekdays',on.offset)
		assert_equal('fdignore',on.fdrule)
		dl=schedule.deadline.shift
		assert_equal('1600',dl.value)
		assert_equal('est',dl.timezone)
		assert_equal('+ 1 day',dl.offset)
		dl=schedule.deadline.shift
		assert_equal('2300',dl.value)
		ex=schedule.except.shift
		assert_equal('monthend',ex.value)
		assert_equal('+ 2 weekdays',ex.offset)
		assert_equal('fdignore',ex.fdrule)
		ex=schedule.except.shift
		assert_equal('05/15/99',ex.value)
		assert_equal('fdignore',ex.fdrule)
		ex=schedule.except.shift
		assert_equal('monthend',ex.value)
		assert_equal('fdprev',ex.fdrule)
		at=schedule.at.shift
		assert_equal('1000',at.value)
		assert_equal('+ 1 day',at.offset)
		at=schedule.at.shift
		assert_equal('2300',at.value)
		assert_equal('est',at.timezone)
		assert_equal('+ 24 days',at.offset)

		assert_equal(true,schedule.carryforward)

		follow=schedule.follows.shift
		assert_equal('site1',follow.wkstation)
		assert_equal('sked4',follow.stream)
		follow=schedule.follows.shift
		assert_equal('site2',follow.wkstation)
		assert_equal('sked5',follow.stream)
		assert_equal('joba',follow.job)
		follow=schedule.follows.shift
		assert_equal('cluster4',follow.netagent)
		assert_equal('site4',follow.wkstation)
		assert_equal('skedx',follow.stream)
		assert_equal('jobx',follow.job)
		follow=schedule.follows.shift
		assert_equal('sked6',follow.stream)
		follow=schedule.follows.shift
		assert_equal('sked7',follow.stream)
		assert_equal('@',follow.job)

		assert_equal(true,schedule.keysched)
		assert_equal('6',schedule.limit)

		need=schedule.needs.shift
		assert_equal('3',need.units)
		assert_equal('cputime',need.name)
		need=schedule.needs.shift
		assert_equal('2',need.units)
		assert_equal('tapes',need.name)

		dep=schedule.opens.shift
		assert_equal('nt5',dep.wkstation)
		assert_equal('"c:\users\fred\datafiles\file88"',dep.path)
		dep=schedule.opens.shift
		assert_equal('"/users"',dep.path)
		assert_equal('(-d %p/john -a -d %p/mary -a -d %p/roger)',dep.qualifier)
		dep=schedule.opens.shift
		assert_equal('/users/xpr/hp3000/send2',dep.path)
		assert_equal('(-n "`ls /users/xpr/hp3000/m*`" -o -r %p)',dep.qualifier)

		assert_equal('HI',schedule.priority)
		assert_equal('"no bugs, no life. do you continue?"',schedule.prompts.shift)

		unt=schedule.until.shift
		assert_equal('1700',unt.value)
		assert_equal('est',unt.timezone)
		assert_equal('+ 2 day',unt.offset)
		assert_equal('CANC',schedule.onuntil)
		
		job=schedule.jobs.shift
		assert_equal('job1',job.name)
		assert_equal('"hello,world!"',job.description)
		assert_equal('"d:\apps\maestro\scripts\jcljob1"',job.scriptname)
		assert_equal('jack',job.streamlogon)
		assert_equal(true,job.interactive)
		assert_equal('"(RC=3) OR ((RC<=5) AND (RC<10))"',job.rccondsucc)
		assert_equal('stop',job.recovery)
		assert_equal('cpu1',job.recovery_job_wkstation)
		assert_equal('job01',job.recovery_job_name)
		assert_equal('"continue production"',job.abendprompt)

		at=job.at.shift
		assert_equal('1000',at.value)
		assert_equal('+ 1 day',at.offset)
		at=job.at.shift
		assert_equal('2300',at.value)
		assert_equal('est',at.timezone)
		assert_equal('+ 24 days',at.offset)

		assert_equal(true,job.confirmed)

		dl=job.deadline.shift
		assert_equal('1600',dl.value)
		assert_equal('+ 1 day',dl.offset)
		dl=job.deadline.shift
		assert_equal('2300',dl.value)

		assert_equal('100',job.every)

		fl=job.follows.shift
		assert_equal('joba',fl.job)
		fl=job.follows.shift
		assert_equal('skeda',fl.stream)
		assert_equal('job3',fl.job)
		fl=job.follows.shift
		assert_equal('unix1',fl.wkstation)
		assert_equal('skedb',fl.stream)
		assert_equal('@',fl.job)

		assert_equal(true,job.keyjob)

		need=job.needs.shift
		assert_equal('9',need.units)
		assert_equal('printers',need.name)
		need=job.needs.shift
		assert_equal('cpu',need.name)

		op=job.opens.shift
		assert_equal('dev3',op.wkstation)
		assert_equal('"d:\work\john\execit1"',op.path)
		assert_equal('(notempty)',op.qualifier)

		assert_equal('GO',job.priority)
		assert_equal('"continue?"',job.prompts.shift)

		unt=job.until.shift
		assert_equal('1700',unt.value)
		assert_equal('est',unt.timezone)
		assert_equal('+ 2 day',unt.offset)
		assert_equal('SUPPR',job.onuntil)

		schedule=result.shift
    assert_equal("* this is 2nd schedule", schedule.comment)
    assert_equal('sched02', schedule.name)
    assert_equal('HOLIDAYS', schedule.on.shift.value)
		assert_equal('job1',schedule.jobs.shift.name)
  end

end
