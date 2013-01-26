
class Composer::Parser::JobParser
token ABENDPROMPT AFTER DECLARE DESCRIPTION DOCOMMAND INTERACTIVE PATH RCCONDSUCC RECOVERY SCRIPTNAME STREAMLOGON STRING WORD
rule
	jobs			: DECLARE stmts

	stmts			:
						| stmts job
	
	job				: name jobdescs
							{
								@logger.warn("#{self.class}"){ "JOB is not set enough. [ #{@job.inspect} ]"} unless @job.set_enough?
								@logger.info("#{self.class}"){ "JOB [ #{@job.name} ] was reduced." }
								@jobs.push @job
								@job=::Composer::TwsObj::Job.new
							}
	
	name 			: WORD
							{ @job.name = val[0] }
						| WORD '#' WORD
							{ 
								@job.wkstation = val[0]
								@job.name = val[2]
								result=val.join('')
							}
	
	jobdescs	: jobdesc
						| jobdescs jobdesc
	
	jobdesc		: SCRIPTNAME PATH
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

	rcvjobstmt:
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
end
