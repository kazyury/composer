
module Composer::Parser
class JobParser < Racc::Parser
	include ::Composer::ParserUtils

	def parse(fname)
		@logger=::Composer::SingletonLogger.instance

		@jobs=[]
		@job=::Composer::TwsObj::Job.new
		scanner=::Composer::Scanner::GenericScanner.new(fname,self)
		
		# scanner‚ðÝ’è
		scanner.declare=/\A\$jobs/i
		scanner.append_tokens(/\A\s/)
		scanner.reserved_word(false,"AFTER","ABENDPROMPT","DESCRIPTION","DOCOMMAND","INTERACTIVE","RECOVERY","SCRIPTNAME","STREAMLOGON","RCCONDSUCC","TASKTYPE")
		scanner.builtin_token(:WORD)
		scanner.builtin_token(:PATH)
		scanner.builtin_token(:STRING)
		scanner.append_tokens(/\A\#/,'#')
		yyparse(scanner, :scan)
		{ :jobs => @jobs }
	end
end
end


