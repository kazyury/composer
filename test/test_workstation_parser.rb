#!ruby

$:.unshift('..')
require 'test/unit'
require 'racc/parser'
require 'singleton_logger'
require 'errors'
require 'utils'
require 'parser/cpuclass'
require 'parser/cpuname'
require 'parser/domain'
require 'parser/workstation_parser82'
require 'parser/workstation_parser_core82'
require 'scanner/generic_scanner'

class TestWorkstationParser < Test::Unit::TestCase
  def setup
    @parser = Composer::Parser::WorkstationParser.new
		@parser.racc_debug(false)
		logger=Composer::SingletonLogger.instance
		logger.level=Logger::INFO
  end

	# sample01 on reference(testdata/0001)
  def test_parse_workstation_0001
		infile="./testdata/workstation_parser.in.0001"
		result=@parser.parse(infile)[:cpunames]
		# cpunameは1個だけ定義されている。
    assert_equal(1, result.size)

		ws=result.first
    assert_equal('hdq-1', ws.name)
    assert_equal('"Headquaters master DM"', ws.description)
    assert_equal('unix', ws.os)
    assert_equal('pst', ws.timezone)
    assert_equal('sultan.ibm.com', ws.node)
    assert_equal('masterdm', ws.domain)
    assert_equal('fta', ws.type)
    assert_equal('on', ws.autolink)
    assert_equal('on', ws.fullstatus)
    assert_equal('on', ws.resolvedep)
  end

	# sample02 on reference(testdata/0002)
  def test_parse_workstation_0002
		infile="./testdata/workstation_parser.in.0002"
		result=@parser.parse(infile)
		domains=result[:domains]
		cpunames=result[:cpunames]

		# domainは1個定義されている。
    assert_equal(1, domains.size)
		dom=domains.shift
		assert_equal('distr-a',dom.name)
		assert_equal('distr-a1',dom.manager)
		assert_equal('masterdm',dom.parent)

		# cpunameは2個定義されている。
    assert_equal(2, cpunames.size)
		# 1個め
		cpu1=cpunames.shift
    assert_equal('distr-a1', cpu1.name)
    assert_equal('"District A domain mgr"', cpu1.description)
    assert_equal('wnt', cpu1.os)
    assert_equal('est', cpu1.timezone)
    assert_equal('pewter.ibm.com', cpu1.node)
    assert_equal('distr-a', cpu1.domain)
    assert_equal('fta', cpu1.type)
    assert_equal('on', cpu1.autolink)
    assert_equal('on', cpu1.fullstatus)
    assert_equal('on', cpu1.resolvedep)
		
		# 2個め
		cpu2=cpunames.shift
    assert_equal('distr-a2', cpu2.name)
    assert_equal('wnt', cpu2.os)
    assert_equal('quatro.ibm.com', cpu2.node)
    assert_equal('est', cpu2.timezone)
    assert_equal('distr-a', cpu2.domain)
    assert_equal('s-agent', cpu2.type)
  end

	# sample03 on reference(testdata/0003)
  def test_parse_workstation_0003
		infile="./testdata/workstation_parser.in.0003"
		result=@parser.parse(infile)[:cpunames]
		# cpunameは1個だけ定義されている。
    assert_equal(1, result.size)

		ws=result.first
    assert_equal('ENNETI3', ws.name)
    assert_equal('WNT', ws.os)
    assert_equal('apollo', ws.node)
    assert_equal('30112', ws.tcpaddr)
    assert_equal('32222', ws.secureaddr)
    assert_equal('off', ws.autolink)
    assert_equal('on', ws.fullstatus)
    assert_equal('on', ws.securitylevel)
  end

	# sample04 on reference(testdata/0004)
  def test_parse_workstation_0004
		infile="./testdata/workstation_parser.in.0004"
		result=@parser.parse(infile)[:cpuclasses]
		# cpuclassは1個だけ定義されている。
    assert_equal(1, result.size)

		cl=result.first
    assert_equal('backup', cl.cpuclass)
    assert_equal(3, cl.members.size)
    assert_equal(['main','site1','site2'], cl.members)
  end

	# sample05 on reference(testdata/0005)
  def test_parse_workstation_0005
		infile="./testdata/workstation_parser.in.0005"
		result=@parser.parse(infile)[:cpuclasses]
		# cpuclassは1個だけ定義されている。
    assert_equal(1, result.size)

		cl=result.first
    assert_equal('allcpus', cl.cpuclass)
    assert_equal(1, cl.members.size)
    assert_equal(['@'], cl.members)
  end
	
	# sample06 on reference(testdata/0006)
  def test_parse_workstation_0006
		infile="./testdata/workstation_parser.in.0006"
		result=@parser.parse(infile)
		domains=result[:domains]

		# domainは1個定義されている。
    assert_equal(1, domains.size)
		dom=domains.shift
		assert_equal('east',dom.name)
		assert_equal('cyclops',dom.manager)
		assert_equal('"The Eastern domain"',dom.description)
	end

	# sample07 on reference(testdata/0007)
  def test_parse_workstation_0007
		infile="./testdata/workstation_parser.in.0007"
		result=@parser.parse(infile)
		domains=result[:domains]

		# domainは3個定義されている。
    assert_equal(3, domains.size)
		# 1個め
		dom=domains.shift
		assert_equal('east',dom.name)
		assert_equal('cyclops',dom.manager)
		assert_equal('"The Eastern domain"',dom.description)
		
		# 2個め
		dom=domains.shift
		assert_equal('northeast',dom.name)
		assert_equal('boxcar',dom.manager)
		assert_equal('east',dom.parent)
		assert_equal('"The Northeastern domain"',dom.description)

		# 3個め
		dom=domains.shift
		assert_equal('southeast',dom.name)
		assert_equal('sedan',dom.manager)
		assert_equal('east',dom.parent)
		assert_equal('"The Southeastern domain"',dom.description)
	end

	# all directives in reference(testdata/full)
  def test_parse_workstation_full
		infile="./testdata/workstation_parser.in.full"
		result=@parser.parse(infile)
		domains=result[:domains]
		cpunames=result[:cpunames]
		cpuclasses=result[:cpuclasses]

		# domainは1個定義されている。
    assert_equal(1, domains.size)
		dom=domains.shift
		assert_equal('distr-a',dom.name)
		assert_equal('" this is distributed site A domain. "',dom.description)
		assert_equal('distr-a1',dom.manager)
		assert_equal('masterdm',dom.parent)

		# cpuclassは1個定義されている。
    assert_equal(1, cpuclasses.size)
		cl=cpuclasses.shift
    assert_equal('allcpus', cl.cpuclass)
    assert_equal(1, cl.members.size)
    assert_equal(['@'], cl.members)
		
		# cpunameは2個定義されている。
    assert_equal(2, cpunames.size)

		cpu=cpunames.shift
		assert_equal('ENNETI3',cpu.name)
		assert_equal('WNT',cpu.os)
		assert_equal('apollo',cpu.node)
		assert_equal('30112',cpu.tcpaddr)
		assert_equal('32222',cpu.secureaddr)
		assert_equal('est',cpu.timezone)
		assert_equal('distr-a',cpu.domain)
		assert_equal('49ners.hoge.hige',cpu.host)
		assert_equal('FOO',cpu.access)
		assert_equal('X-AGENT',cpu.type)
		assert_equal(true,cpu.ignore)
		assert_equal('off',cpu.autolink)
		assert_equal('ON',cpu.fullstatus)
		assert_equal('force',cpu.securitylevel)
		assert_equal('M',cpu.server)
		assert_equal('on',cpu.behindfirewall)

		cpu=cpunames.shift
    assert_equal('distr-a1', cpu.name)
    assert_equal('"District A domain mgr"', cpu.description)
    assert_equal('wnt', cpu.os)
    assert_equal('est', cpu.timezone)
    assert_equal('pewter.ibm.com', cpu.node)
    assert_equal('fta', cpu.type)
    assert_equal('on', cpu.autolink)
    assert_equal('on', cpu.fullstatus)
    assert_equal('on', cpu.resolvedep)
	end

end
