
module Composer::Parser
class ResourceParser < Racc::Parser
	include ::Composer::ParserUtils

	def parse(fname)
		@logger=::Composer::SingletonLogger.instance

		@resources=[]
		@resource=::Composer::TwsObj::Resource.new
		scanner=::Composer::Scanner::GenericScanner.new(fname,self)

		# scanner‚ðÝ’è
		scanner.declare=/\A\$resource/i
		scanner.append_tokens(/\A\s/)
		scanner.append_tokens(/\A\#/,'#')
		scanner.builtin_token(:NUMBER)
		scanner.builtin_token(:WORD)
		scanner.builtin_token(:STRING)
		yyparse(scanner, :scan)
		{ :resources => @resources }
	end

end
end

