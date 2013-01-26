
module Composer::Parser
class PromptParser < Racc::Parser
	include ::Composer::ParserUtils

	def parse(fname)
		@logger=::Composer::SingletonLogger.instance

		@prompts=[]
		@prompt=::Composer::TwsObj::Prompt.new
		scanner=::Composer::Scanner::GenericScanner.new(fname,self)

		# scanner‚ðÝ’è
		scanner.declare=/\A\$prompt/i
		scanner.append_tokens(/\A\s/)
		scanner.builtin_token(:WORD)
		scanner.builtin_token(:STRING)
		yyparse(scanner, :scan)
		{ :prompts => @prompts }
	end

end
end
