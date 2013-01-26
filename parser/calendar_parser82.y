
class Composer::Parser::CalendarParser
token DATE6 DECLARE STRING WORD
rule
	cals			: DECLARE stmts

	stmts					:
								| stmts calendar

	calendar			: name description date
									{
										@logger.warn("#{self.class}"){ "CALENDAR is not set enough. [ #{@calendar.inspect} ]"} unless @calendar.set_enough?
										@logger.info("#{self.class}"){ "CALENDAR [ #{@calendar.name} ] was reduced." }
										@calendars.push @calendar
										@calendar=::Composer::TwsObj::Calendar.new
									}
	name					: WORD
									{ @calendar.name=val[0] }

	description		:
								| STRING
									{ @calendar.description=val[0] }

	date					: DATE6
									{ @calendar.append_date val[0] }
								| date DATE6
									{ @calendar.append_date val[1] }
end

