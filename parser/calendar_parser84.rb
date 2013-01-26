
module Composer::Parser
class CalendarParser < Racc::Parser
	include ::Composer::ParserUtils

	def parse(fname)
		@logger=::Composer::SingletonLogger.instance

		@calendars=[]
		@calendar=::Composer::TwsObj::Calendar.new
		scanner=::Composer::Scanner::GenericScanner.new(fname,self)
		
		# scanner‚ðÝ’è
		scanner.declare=/\A\$calendar/i
		scanner.append_tokens(/\A\s/)
		scanner.builtin_token(:DATE8)
		scanner.builtin_token(:WORD)
		scanner.builtin_token(:STRING)
		yyparse(scanner, :scan)
		{:calendars => @calendars }
	end

end
end

