
module Composer::Parser
class ScheduleParser < Racc::Parser
	include ::Composer::ParserUtils

	def parse(fname)
		@logger=::Composer::SingletonLogger.instance
		@comment_buffer=[]
		@job_buffer=[]
		@date_buffer=[]
		@time_buffer=[]
		@follow_buffer=[]
		@resource_buffer=[]
		@file_buffer=[]
		@prompt_buffer=[]
		@job_buffer=[]


		@schedules=[]
		@schedule=::Composer::TwsObj::Schedule.new
		@job=::Composer::TwsObj::ScheduledJob.new
#     scanner=GenericScanner.new(fname)
		# schedule_parser.y でスキャナのモードを切り替える必要があるため、
		# scheduleに関してはscannerをインスタンス変数に格納。
		@scanner=::Composer::Scanner::ModeSwitchableScanner.new(fname,self)
		
		# scannerを設定
		@scanner.append_tokens(/\A\s/)
		@scanner.on(:COMMENTABLE){|s|
			s.append_tokens(/\A\#.*?$/          ,:LINECOMMENT)
		}
		@scanner.append_tokens(/\A\*.*?$/)
		@scanner.append_tokens(/\A<<(.+?)>>/)		# << >> 形式はコメント
		@scanner.append_tokens(/\A\(.+?\)/i		,:PHARENBLOCK)
		@scanner.append_tokens(/\A\:\:/            ,'::')
		@scanner.append_tokens(/\A\:/              ,':')
		@scanner.append_tokens(/\A\,/              ,',')
		@scanner.append_tokens(/\A\./              ,'.')
		@scanner.append_tokens(/\A\@/              ,'@')
		@scanner.append_tokens(/\A\#/i             ,'#')
		@scanner.append_tokens(/\A\+/              ,'+')
		@scanner.append_tokens(/\A\-/              ,'-')
		@scanner.reserved_word(false,"ABENDPROMPT", "AFTER", "AT", "CARRYFORWARD", "CONFIRMED", "DAYS", "DEADLINE", "DESCRIPTION", "DOCOMMAND", "EVERY")
		@scanner.reserved_word(false,"EXCEPT", "FDIGNORE", "FDNEXT", "FDPREV", "FOLLOWS", "FREEDAYS", "GO", "HI", "INTERACTIVE", "KEYJOB", "KEYSCHED", "LIMIT")
		@scanner.reserved_word(false,"NEEDS", "ON", "ONUNTIL", "OPENS", "PRIORITY", "PROMPT", "RCCONDSUCC", "RECOVERY", "REQUEST", "SCHEDULE", "SCRIPTNAME")
		@scanner.reserved_word(false, "STREAMLOGON", "TIMEZONE", "UNTIL", "WEEKDAYS", "WORKDAYS")
		@scanner.reserved_word(false, "DRAFT", "RUNCYCLE")
		@scanner.append_tokens(/\A(day)[^\w-]/i            ,:DAYS , true)
		@scanner.append_tokens(/\A(weekday)[^\w-]/i        ,:WEEKDAYS , true)
		@scanner.append_tokens(/\A(workday)[^\w-]/i        ,:WORKDAYS , true)
		@scanner.append_tokens(/\A(tz)[^\w-]/i             ,:TIMEZONE , true)
		@scanner.append_tokens(/\A(end)[^\w-]/i             ,:ENDSTMT , true)
		@scanner.builtin_token(:DATE8)
		@scanner.builtin_token(:NUMBER)
		@scanner.builtin_token(:WORD)
		@scanner.builtin_token(:STRING)
		@scanner.builtin_token(:PATH)
		@scanner.switch(:COMMENTABLE)
		yyparse(@scanner, :scan)
		{ :schedules => @schedules }
	end

end
end
