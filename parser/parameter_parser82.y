
class Composer::Parser::ParameterParser
token DECLARE STRING WORD
rule
	params	: DECLARE stmts

	stmts		:
					| stmts param

	param		: name value
						{
							@logger.warn("#{self.class}"){ "PARAMETER is not set enough. [ #{@parameter.inspect} ]"} unless @parameter.set_enough?
							@logger.info("#{self.class}"){ "PARAMETER [ #{@parameter.name} ] was reduced." }
							@parameters.push @parameter
							@parameter=::Composer::TwsObj::Parameter.new
						}

	name		: WORD
						{ @parameter.name=val[0] }

	value		: STRING 
						{ @parameter.value=val[0] }

end


