
class Composer::Parser::ScheduleParser
token ABENDPROMPT AFTER AT CARRYFORWARD CONFIRMED DATE6 DAYS DEADLINE 
token DESCRIPTION DOCOMMAND ENDSTMT EVERY EXCEPT FDIGNORE FDNEXT FDPREV 
token FOLLOWS FREEDAYS GO HI INTERACTIVE KEYJOB KEYSCHED LIMIT LINECOMMENT 
token NEEDS NUMBER ON ONUNTIL OPENS PATH PHARENBLOCK PRIORITY PROMPT 
token RCCONDSUCC RECOVERY REQUEST SCHEDULE SCRIPTNAME STREAMLOGON STRING 
token TIMEZONE UNTIL WEEKDAYS WORD WORKDAYS
rule
	schedules		: schedule
							| schedules schedule

	schedule		: linecomments SCHEDULE {@processing=:SCHEDULE;@scanner.switch(:DEFAULT)} streamstmt ':' {@processing=:JOB} jobstmts ENDSTMT
							{
								@scanner.switch(:COMMENTABLE)
								@schedule.comment=@comment_buffer.join("\n")
								@schedule.jobs=@job_buffer
								@comment_buffer=[]
								@job_buffer=[]
								@logger.warn("#{self.class}"){ "SCHEDULE is not set enough. [ #{@schedule.inspect} ]"} unless @schedule.set_enough?
								@logger.info("#{self.class}"){ "SCHEDULE [ #{@schedule.name} ] was reduced." }
								@schedules.push @schedule
								@schedule=::Composer::TwsObj::Schedule.new
							}
	
	linecomments	: 
								| linecomments LINECOMMENT
									{ @comment_buffer.push val[1] }
							
	streamstmt	: streamname streamattrs

	streamname	: WORD
								{ @schedule.name=val[0] }
							| WORD '#' WORD
								{ 
									@schedule.wkstation=val[0] 
									@schedule.name=val[2] 
								}

	streamattrs	: streamattr
							| streamattrs streamattr

	streamattr	: FREEDAYS WORD freedaysopts
								{ 
									@schedule.freedays_cal=val[1]
									@schedule.freedays_opt=val[2]
								}
							| ON dates fdrule
								{ 
									@schedule.append_dates(:on,@date_buffer,val[2]) 
									@date_buffer=[]
								}
							| DEADLINE times
								{ 
									@schedule.deadline=@time_buffer
									@time_buffer=[]
								}
							| EXCEPT dates fdrule
								{ 
									@schedule.append_dates(:except,@date_buffer,val[2])
									@date_buffer=[]
								}
							| AT times
								{ 
									@schedule.at=@time_buffer
									@time_buffer=[]
								}
							| CARRYFORWARD
								{ @schedule.carryforward=true }
							| FOLLOWS follows
								{ 
									@schedule.follows=@follow_buffer
									@follow_buffer=[]
								}
							| KEYSCHED
								{ @schedule.keysched=true }
							| LIMIT NUMBER
								{ @schedule.limit=val[1] }
							| NEEDS resources
								{ 
									@schedule.needs=@resource_buffer
									@resource_buffer=[]
								}
							| OPENS files
								{ 
									@schedule.opens=@file_buffer
									@file_buffer=[]
								}
							| PRIORITY porder
								{ @schedule.priority=val[1] }
							| PROMPT prompts
								{
									@schedule.prompts=@prompt_buffer
									@prompt_buffer=[]
								}
							| UNTIL times
								{ 
									@schedule.until=@time_buffer
									@time_buffer=[]
								}
							| ONUNTIL WORD
								{ @schedule.onuntil=val[1] }
	
	freedaysopts	:
								| '-' WORD
									{ result=val.join('') }
								| '-' WORD '-' WORD
									{ result=val.join('') }

	dates				: date
							| dates ',' date
	
	date				: DATE6
								{ @date_buffer.push ::Composer::TwsObj::ScheduledDate.new(val[0],nil) }
							| WEEKDAYS
								{ @date_buffer.push ::Composer::TwsObj::ScheduledDate.new(val[0],nil) }
							| WORKDAYS
								{ @date_buffer.push ::Composer::TwsObj::ScheduledDate.new(val[0],nil) }
							| FREEDAYS
								{ @date_buffer.push ::Composer::TwsObj::ScheduledDate.new(val[0],nil) }
							| WORD offset
								{ @date_buffer.push ::Composer::TwsObj::ScheduledDate.new(val[0],val[1]) }
							| REQUEST
								{ @date_buffer.push ::Composer::TwsObj::ScheduledDate.new(val[0],nil) }
	
	offset			:
							| '+' NUMBER DAYS
								{ result=val.join(' ') }
							| '+' NUMBER WEEKDAYS
								{ result=val.join(' ') }
							| '+' NUMBER WORKDAYS
								{ result=val.join(' ') }
							| '-' NUMBER DAYS
								{ result=val.join(' ') }
							| '-' NUMBER WEEKDAYS
								{ result=val.join(' ') }
							| '-' NUMBER WORKDAYS
								{ result=val.join(' ') }

	fdrule			:
								{ result='' }
							| FDIGNORE
							| FDNEXT
							| FDPREV
	
	times				: time
							| times ',' time
	
	time				: WORD timezone offset
								{ @time_buffer.push ::Composer::TwsObj::ScheduledTime.new(val[0],val[1],val[2]) }
							| NUMBER timezone offset
								{ @time_buffer.push ::Composer::TwsObj::ScheduledTime.new(val[0],val[1],val[2]) }
	
	timezone		:
								{ result=nil }
							| TIMEZONE WORD
								{ result=val[1] }

	follows			: follow
							| follows ',' follow
	
	follow			: WORD
								{ 
									if @processing==:SCHEDULE
										@follow_buffer.push ::Composer::TwsObj::Follow.new(nil,nil,val[0],nil)
									elsif @processing==:JOB
										@follow_buffer.push ::Composer::TwsObj::Follow.new(nil,nil,nil,val[0])
									else
										@logger.error("#{self.class}"){ "[ Bug ] @processing is not valid. [ #{@processing} ]"}
									end
								}
							| WORD '.' WORD
								{ @follow_buffer.push ::Composer::TwsObj::Follow.new(nil,nil,val[0],val[2]) }
							| WORD '.' '@'
								{ @follow_buffer.push ::Composer::TwsObj::Follow.new(nil,nil,val[0],val[2]) }
							| WORD '#' WORD
								{ 
									if @processing==:SCHEDULE
										@follow_buffer.push ::Composer::TwsObj::Follow.new(nil,val[0],val[2],nil)
									elsif @processing==:JOB
										@follow_buffer.push ::Composer::TwsObj::Follow.new(nil,val[0],nil,val[2])
									else
										@logger.error("#{self.class}"){ "[ Bug ] @processing is not valid. [ #{@processing} ]"}
									end
								}
							| WORD '#' WORD '.' WORD
								{ @follow_buffer.push ::Composer::TwsObj::Follow.new(nil,val[0],val[2],val[4]) }
							| WORD '#' WORD '.' '@'
								{ @follow_buffer.push ::Composer::TwsObj::Follow.new(nil,val[0],val[2],val[4]) }
							| WORD '::' WORD '#' WORD
								{ 
									if @processing==:SCHEDULE
										@follow_buffer.push ::Composer::TwsObj::Follow.new(val[0],val[2],val[4],nil)
									elsif @processing==:JOB
										@follow_buffer.push ::Composer::TwsObj::Follow.new(val[0],val[2],nil,val[4])
									else
										@logger.error("#{self.class}"){ "[ Bug ] @processing is not valid. [ #{@processing} ]"}
									end
								}
							| WORD '::' WORD '#' WORD '.' WORD
								{ @follow_buffer.push ::Composer::TwsObj::Follow.new(val[0],val[2],val[4],val[6]) }
							| WORD '::' WORD '#' WORD '.' '@'
								{ @follow_buffer.push ::Composer::TwsObj::Follow.new(val[0],val[2],val[4],val[6]) }

	resources		: resource
							| resources ',' resource
	
	resource		: WORD
								{
									resource=::Composer::TwsObj::Resource.new
									resource.name=val[0]
									@resource_buffer.push resource
								}
							| WORD '#' WORD
								{
									resource=::Composer::TwsObj::Resource.new
									resource.wkstation=val[0]
									resource.name=val[2]
									@resource_buffer.push resource
								}
							| NUMBER WORD
								{
									resource=::Composer::TwsObj::Resource.new
									resource.units=val[0]
									resource.name=val[1]
									@resource_buffer.push resource
								}
							| NUMBER WORD '#' WORD
								{
									resource=::Composer::TwsObj::Resource.new
									resource.units=val[0]
									resource.wkstation=val[1]
									resource.name=val[3]
									@resource_buffer.push resource
								}
	
	files				: file
							| files ',' file
	
	file				: PATH
								{ @file_buffer.push ::Composer::TwsObj::DependFile.new(nil,val[0],nil) }
							| STRING
								{ @file_buffer.push ::Composer::TwsObj::DependFile.new(nil,val[0],nil) }
							| PATH PHARENBLOCK
								{ @file_buffer.push ::Composer::TwsObj::DependFile.new(nil,val[0],val[1]) }
							| STRING PHARENBLOCK
								{ @file_buffer.push ::Composer::TwsObj::DependFile.new(nil,val[0],val[1]) }
							| WORD '#' PATH
								{ @file_buffer.push ::Composer::TwsObj::DependFile.new(val[0],val[2],nil) }
							| WORD '#' STRING
								{ @file_buffer.push ::Composer::TwsObj::DependFile.new(val[0],val[2],nil) }
							| WORD '#' PATH PHARENBLOCK
								{ @file_buffer.push ::Composer::TwsObj::DependFile.new(val[0],val[2],val[3]) }
							| WORD '#' STRING PHARENBLOCK
								{ @file_buffer.push ::Composer::TwsObj::DependFile.new(val[0],val[2],val[3]) }
	
	porder			: NUMBER
							| HI
							| GO

	prompts			: prompt
							| prompts ',' prompt

	prompt			: WORD
								{ @prompt_buffer.push val[0].gsub(/\\n\n/,"\n") }
							| STRING
								{ @prompt_buffer.push val[0].gsub(/\\n\n/,"\n") }
	
	jobstmts		: 
							| jobstmts jobstmt

	jobstmt			: jobname jobdescs jobattrs
								{
									@job_buffer.push @job
									@job=::Composer::TwsObj::ScheduledJob.new
								}

	jobname 		: WORD
								{ @job.name=val[0] }
							| WORD '#' WORD
								{ 
									@job.wkstation=val[0]
									@job.name=val[2]
								}

	jobdescs		: 
							| jobdescs jobdesc

	jobdesc			: SCRIPTNAME PATH
								{ @job.scriptname = val[1] }
							| SCRIPTNAME STRING
								{ @job.scriptname = val[1] }
							| DOCOMMAND STRING
								{ @job.docommand = val[1] }
							| DOCOMMAND PATH
								{ @job.docommand = val[1] }
							| STREAMLOGON WORD
								{ @job.streamlogon = val[1] }
							| STREAMLOGON STRING
								{ @job.streamlogon = val[1] }
							| DESCRIPTION STRING
								{ @job.description = val[1] }
							| INTERACTIVE
								{ @job.interactive=true }
							| RCCONDSUCC STRING
								{ @job.rccondsucc=val[1] }
							| RECOVERY WORD rcvjobstmt rcvprmptstmt
								{ @job.recovery = is_valid?(['STOP','CONTINUE','RERUN'],val[1]) }

	rcvjobstmt	:
							| AFTER WORD
								{ @job.recovery_job_name = val[1] }
							| AFTER WORD '#' WORD
								{ 
									@job.recovery_job_wkstation = val[1]
									@job.recovery_job_name = val[3]
								}

	rcvprmptstmt	:
								| ABENDPROMPT STRING
									{ @job.abendprompt = val[1] }

	jobattrs		: 
							| jobattrs jobattr

	jobattr			: AT times
								{ 
									@job.at=@time_buffer
									@time_buffer=[]
								}
							| CONFIRMED
								{ @job.confirmed=true }
							| DEADLINE times
								{ 
									@job.deadline=@time_buffer
									@time_buffer=[]
								}
							| EVERY WORD
								{ @job.every=val[1] }
							| EVERY NUMBER
								{ @job.every=val[1] }
							| FOLLOWS follows
								{ 
									@job.follows=@follow_buffer
									@follow_buffer=[]
								}
							| KEYJOB
								{ @job.keyjob=true }
							| NEEDS resources
								{ 
									@job.needs=@resource_buffer
									@resource_buffer=[]
								}
							| OPENS files
								{ 
									@job.opens=@file_buffer
									@file_buffer=[]
								}
							| PRIORITY porder
								{ @job.priority=val[1] }
							| PROMPT prompts
								{
									@job.prompts=@prompt_buffer
									@prompt_buffer=[]
								}
							| UNTIL times
								{ 
									@job.until=@time_buffer
									@time_buffer=[]
								}
							| ONUNTIL WORD
								{ @job.onuntil=val[1] }

end
