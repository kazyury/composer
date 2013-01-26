
module Composer::Parser
class ParameterParser < Racc::Parser
	include ::Composer::ParserUtils

	def parse(fname)
		@logger=::Composer::SingletonLogger.instance

		@parameters=[]
		@parameter=::Composer::TwsObj::Parameter.new
		scanner=::Composer::Scanner::GenericScanner.new(fname,self)

		# scanner‚ðÝ’è
		scanner.declare=/\A\$parm/i
		scanner.append_tokens(/\A\s/)
		scanner.builtin_token(:WORD)
		scanner.builtin_token(:STRING)
		yyparse(scanner, :scan)
		{:parameters => @parameters }
	end

end
end
