
class Composer::Parser::PromptParser
token DECLARE WORD STRING
rule
	params	: DECLARE stmts

	stmts	:
				| stmts param

	param	: name value
					{
						@logger.warn("#{self.class}"){ "PROMPT is not set enough. [ #{@prompt.inspect} ]"} unless @prompt.set_enough?
						@logger.info("#{self.class}"){ "PROMPT [ #{@prompt.name} ] was reduced." }
						@prompts.push @prompt
						@prompt=::Composer::TwsObj::Prompt.new
					}

	name	: WORD
					{ @prompt.name=val[0] }

	value	: STRING
					{ @prompt.value=val[0] }

end

