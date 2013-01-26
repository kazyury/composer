
class Composer::Parser::ResourceParser
token DECLARE WORD NUMBER STRING
rule
	resources			: DECLARE stmts

	stmts					:
								| stmts resource

	resource  		: wkstation '#' resourcename units description
									{
										@logger.warn("#{self.class}"){ "RESOURCE is not set enough. [ #{@resource.inspect} ]"} unless @resource.set_enough?
										@logger.info("#{self.class}"){ "RESOURCE [ #{@resource.name} ] was reduced." }
										@resources.push @resource
										@resource=::Composer::TwsObj::Resource.new
									}
	wkstation 		: WORD
									{ @resource.wkstation=val[0] }
	resourcename	: WORD
									{ @resource.name=val[0] }
	units					: NUMBER
									{ @resource.units=val[0] }
	description		:
								| STRING
									{ @resource.description=val[0] }
end

