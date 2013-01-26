
class Composer::Parser::WorkstationParser
token ACCESS AUTOLINK BEHINDFIREWALL CPUCLASS CPUNAME DESCRIPTION DOMAIN ENDSTMT FOR FULLSTATUS HOST IGNORE MAESTRO MANAGER 
token MEMBERS NODE OS PARENT PATH RESOLVEDEP SECUREADDR SECURITYLEVEL SERVER STRING TCPADDR TIMEZONE TYPE WORD
rule
	statements	:
							| statements statement

	statement		: CPUNAME cpudef ENDSTMT
								{
									@logger.warn("#{self.class}"){ "CPU is not set enough. [ #{@cpuname.inspect} ]"} unless @cpuname.set_enough?
									@logger.info("#{self.class}"){ "CPU [ #{@cpuname.name} ] was reduced." }
									@cpunames.push @cpuname
									@cpuname=::Composer::TwsObj::CpuName.new 
								}
							| CPUCLASS cpuclassstmt ENDSTMT
								{
									@logger.warn("#{self.class}"){ "CPUCLASS is not set enough. [ #{@cpuclass.inspect} ]"} unless @cpuclass.set_enough?
									@logger.info("#{self.class}"){ "CPUCLASS [ #{@cpuclass.cpuclass} ] was reduced." }
									@cpuclasses.push @cpuclass
									@cpuclass=::Composer::TwsObj::CpuClass.new
								}
							| DOMAIN domainstmt ENDSTMT
								{
									@logger.warn("#{self.class}"){ "DOMAIN is not set enough. [ #{@domain.inspect} ]"} unless @domain.set_enough?
									@logger.info("#{self.class}"){ "DOMAIN [ #{@domain.name} ] was reduced." }
									@domains.push @domain
									@domain=::Composer::TwsObj::Domain.new
								}

	cpudef			: WORD cpuoptions maestro
								{ @cpuname.name=val[0] }
	
	cpuoptions	: cpuoption
							| cpuoptions cpuoption

	cpuoption		: cpudesc
							| os
							| node
							| tcpaddr
							| secureaddr
							| timezone
							| domain

	cpudesc			: DESCRIPTION STRING
								{ @cpuname.description=val[1] }

	os					: OS WORD
								{ @cpuname.os=is_valid?(['UNIX','WNT','OTHER'],val[1]) }

	node				: NODE hostname
								{ 
									@cpuname.node=@hostname_buffer
									@hostname_buffer=""
								}

	hostname		: WORD 
								{ @hostname_buffer+=val[0] }
							| hostname '.' WORD
								{ @hostname_buffer=@hostname_buffer+val[1]+val[2] }

	tcpaddr			: TCPADDR WORD
								{ @cpuname.tcpaddr=val[1] }

	secureaddr	: SECUREADDR WORD
								{ @cpuname.secureaddr=val[1] }

	timezone		: TIMEZONE WORD
								{ @cpuname.timezone=val[1] }

	domain			: DOMAIN WORD
								{ @cpuname.domain=val[1] }

	maestro			:
							| FOR MAESTRO maestroopts

	maestroopts	:
							| maestroopts maestroopt 
	
	maestroopt	: host 
							| type
							| ignore 
							| autolink
							| behindfirewall
							| securitylevel
							| fullstatus
							| resolvedep
							| server

	host				: HOST hostname access
								{ 
									@cpuname.host=@hostname_buffer
									@hostname_buffer=""
								}
	
	access			:
							| ACCESS PATH { @cpuname.access=val[1] }
							| ACCESS WORD { @cpuname.access=val[1] }

	type				: TYPE WORD
								{ @cpuname.type=is_valid?(['FTA','S-AGENT','X-AGENT'],val[1]) }
	
	ignore			: IGNORE
								{ @cpuname.ignore=true }
	
	autolink		: AUTOLINK WORD
								{ @cpuname.autolink=is_valid?(['ON','OFF'], val[1]) }
	
	behindfirewall	: BEHINDFIREWALL WORD
										{ @cpuname.behindfirewall=is_valid?(['ON','OFF'], val[1]) }

	securitylevel		: SECURITYLEVEL WORD
										{ @cpuname.securitylevel=is_valid?(['ENABLED','ON','FORCE'],val[1]) }

	fullstatus	: FULLSTATUS WORD
								{ @cpuname.fullstatus=is_valid?(['ON','OFF'],val[1]) }
	
	resolvedep	: RESOLVEDEP WORD
								{ @cpuname.resolvedep=is_valid?(['ON','OFF'],val[1]) }
	
	server			: SERVER WORD
								{ @cpuname.server=val[1] }
	
	cpuclassstmt: WORD MEMBERS wkstations
								{ @cpuclass.cpuclass=val[0] }

	wkstations	: WORD
								{ @cpuclass.members.push val[0] }
							| wkstations WORD
								{ @cpuclass.members.push val[1] }
							| '@'
								{ @cpuclass.members.push val[0] }

	domainstmt	: WORD domdesc MANAGER WORD parent
								{ 
									@domain.name=val[0]
									@domain.manager=val[3]
								}

	domdesc			:
							| DESCRIPTION STRING
								{ @domain.description=val[1] }

	parent			:
							| PARENT WORD
								{ @domain.parent=val[1] }

end
