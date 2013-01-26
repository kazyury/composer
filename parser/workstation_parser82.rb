
module Composer::Parser
class WorkstationParser < Racc::Parser
	include ::Composer::ParserUtils

	def parse(fname)
		@logger=::Composer::SingletonLogger.instance

		@cpunames=[]
		@cpuclasses=[]
		@domains=[]
		@cpuname=::Composer::TwsObj::CpuName.new
		@cpuclass=::Composer::TwsObj::CpuClass.new
		@domain=::Composer::TwsObj::Domain.new

		@hostname_buffer=""
		scanner=::Composer::Scanner::GenericScanner.new(fname,self)
		
		# scanner‚ðÝ’è
		scanner.append_tokens(/\A\s/)
		scanner.append_tokens(/\A\#.*?$/)		# #‚©‚çs––‚Ü‚Å“Ç‚Ý”ò‚Î‚µ
		scanner.append_tokens(/\A\./                ,'.')
		scanner.append_tokens(/\A\@/                ,'@')
		scanner.reserved_word(false,"CPUNAME", "CPUCLASS", "DOMAIN", "DESCRIPTION", "OS", "NODE", "TCPADDR", "SECUREADDR", "TIMEZONE", "FOR")
		scanner.reserved_word(false,"MAESTRO", "HOST", "ACCESS", "TYPE", "IGNORE", "AUTOLINK", "FULLSTATUS", "RESOLVEDEP", "SERVER", "MEMBERS", "MANAGER")
		scanner.reserved_word(false,"PARENT", "BEHINDFIREWALL", "SECURITYLEVEL")
		scanner.append_tokens(/\A(tz)[^\w-]/i,:TIMEZONE,true)
		scanner.append_tokens(/\A(end)[^\w-]/i,:ENDSTMT,true)
		scanner.builtin_token(:WORD)
		scanner.builtin_token(:STRING)
		scanner.builtin_token(:PATH)

		yyparse(scanner, :scan)
		{ :cpunames => @cpunames, 
			:cpuclasses => @cpuclasses, 
			:domains => @domains }
	end

end
end


