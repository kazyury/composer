
require 'date'

#Ruby�g�ݍ��݂�Date�N���X�Ƀw���p���\�b�h��ǉ��B
class Date
	#self�̔N����1���ڂ�����Date��ԋp����B
	#
	# ��
	# aDate=Date.new(2007,2,18) #=>2007-02-18������Date
	# aDate.first_day_of_month  #=>2007-02-01������Date
	def first_day_of_month
		Date.new(self.year, self.month, 1)
	end

	#self�̔N���̊A��������Date��ԋp����B
	#
	# ��
	# aDate=Date.new(2007,2,18) #=>2007-02-18������Date
	# aDate.last_day_of_month   #=>2007-02-28������Date
	def last_day_of_month
		(self.first_day_of_month >> 1 ) - 1
	end

	#(���StreamPlan�Ŏg�p���邽�߂�)self��yyyy-mm�𕶎���ŕԋp�B
	#
	# ��
	# aDate=Date.new(2007,2,18) #=>2007-02-18������Date
	# aDate.year_and_month      #=>'2007-02'
	def year_and_month
		self.strftime("%Y-%m")
	end
end
		

module Composer
	#�eParser(Composer::Parser::ScheduleParser��)�ŋ��ʂ��Ďg�p���郁�\�b�h�Q�̎���
	module ParserUtils
		# racc ��debug���[�h��ON/OFF
		def racc_debug(bool)
			@yydebug=bool
		end

		#���݃X�L�������Ă���s�ԍ����i�[����B
		def scan_line=(lineno)
			@lineno=lineno
		end

		#�i���_�b�P�H
		def is_valid?(expects, actual)
			str=actual.chomp.strip
			bool=expects.any?{|ex| ex.upcase == str.upcase}
			raise "Expected was [#{expects.join(',')}] but was [ #{str} ]" unless bool
			str
		end
		
		#Racc::ParseError �̃��b�Z�[�W���I�[�o�[���C�h
		def on_error(t,v,values)
			raise Racc::ParseError,"@#{@lineno}, syntax error on #{v.inspect}"
		end
	end

	
	#���Composer::TwsObj�n�̃N���X�ŋ��ʂ��Ďg�p����A���󐫂̍���attr_writer,accessor �̎����B
	#��nil�̃C���X�^���X�ϐ��ɑ΂���@ivar=(value)�ɂ��ϐ��l�̃A�T�C������logger.warn�𔭐�����B
	#
	#(���ǁAsensitive_reader �͉������Ȃ��̂ŁAattr_reader �ƕς��Ȃ��B�Ώې��̂��߂����ɗp�ӁB)
	module SensitiveAttr
		def sensitive_reader(*ivars)
			ivars.each do |ivar|
				module_eval <<-DEFINE_READER
					def #{ivar}
						@#{ivar}
					end
				DEFINE_READER
			end
		end

		#sensitive_writer �Ŏw�肳�ꂽ�C���X�^���X�ϐ�����nil�ł���ꍇ�A@ivar=(value)�ɂ��ϐ��l�A�T�C������logger.warn�𔭐�����B
		#(�C���X�^���X�ϐ��ւ̃A�T�C���͍s����)
		def sensitive_writer(*ivars)
			ivars.each do |ivar|
				module_eval <<-DEFINE_WRITER
					def #{ivar}=(var)
            @logger.warn(\"\#{self.class}\"){ \"#{ivar}[ \#{@#{ivar}} ] is overridden by [ \#{var} ].\"} if @#{ivar}
						@#{ivar}=var
					end
				DEFINE_WRITER
			end
		end

		#sensitive_accessor �Ŏw�肳�ꂽ�C���X�^���X�ϐ�����nil�ł���ꍇ�A@ivar=(value)�ɂ��ϐ��l�A�T�C������logger.warn�𔭐�����B
		#(�C���X�^���X�ϐ��ւ̃A�T�C���͍s����)
		def sensitive_accessor(*ivars)
			sensitive_reader(*ivars)
			sensitive_writer(*ivars)
		end
	end

	#= BaseMake
	#Composer�̕\���`����؂�ւ��邽�߂̃x�[�X���W���[���B
	#�eFace�N���X�͂��̃��W���[����include����K�v������B
	#BaseMake��include���邱�Ƃɂ��AYourFaceClass#initialize����`����A�Œ���K�v�Ȋe��C���X�^���X�ϐ����Z�b�g�����B
	#
	#== create my OWN FACE, HOW TO .
	#
	#�Ǝ���Face�N���X���쐬����ɂ͈ȉ��̎菇�ɏ]���K�v������B
	#1. face �f�B���N�g���ȉ��ɁA#{file_id}/#{file_id}.rb ���쐬����B
	#   composer_face��face���w�肷��ۂɂ́A���� file_id ��p���邱�ƂƂȂ�B
	#    ��.
	#    'default_face' �̏ꍇ�ɂ́Adefault_face/default_face.rb ���쐬����B
	#2. #{file_id}.rb���� #{face_class_id} �N���X���`����B���O��Ԃ́A Composer::Face �ȉ��B
	#   face_class_id �� file_id �����ɁA�ȉ��̃��[���ɂĕϊ��������̂ł���K�v������B
	#   - file_id ��'_'�ŕ�������B
	#   - ������̊e�P��̐擪������啶���A�c����������ɂ���B
	#   - �ϊ���̊e������A���B
	#    ��. 
	#    default_face => default face => Default Face => DefaultFace
	#3. #{face_class_id}�N���X�́AComposer::BaseMake ��include����B
	#4. #{face_class_id}�N���X�ł́Ainitialize���\�b�h�͒�`" <b>���Ȃ�</b> "
	#5. #{face_class_id}�N���X�ɁAformat���\�b�h���`" <b>����</b> "�B
	#   ���̃��\�b�h�́A�ϊ����s�w���̍�(FrontEnd#convert)���ɌĂяo�����B
	#6. #{face_class_id}�I�u�W�F�N�g�̐������ɏ������������K�v�ȏꍇ�ɂ́Aon_setup ���\�b�h(��������)���`����B
	#   ���̃��\�b�h��(��`����Ă���ꍇ�ɂ�)initialize���ɌĂ΂��B
	#7. �ϊ������̏I�����Ɍ㏈�����K�v�ȏꍇ�ɂ́Aon_exiting ���\�b�h(��������)���`����B
	#   ���̃��\�b�h��(��`����Ă���ꍇ�ɂ�)convert���FrontEnd���Ă΂��B
	#8. ���Ƃ́A���D�݂œK�X�̃N���X��݌v�B
	#
	#���̑��̎Q�l���
	#1. initialize ���ɁA@my_dir , @outfiles_dir ����`�����B
	#   @my_dir:: ���t�@�C���̊i�[�p�X���
	#   @outfiles_dir:: �o�̓t�@�C���p�X���
	#    ��
	#    DefaultFace �̏ꍇ�A@my_dir=#{BASE_DIR}/face/default_face
	#    StreamPlan  �̏ꍇ�A@my_dir=#{BASE_DIR}/face/stream_plan
	#2. initialize���ɁA@logger(Composer::SingletonLogger �C���X�^���X)����`�����B
	#   �K�v�ɉ����āA@logger.warn���̃��\�b�h���g�p�\�B
	#   (Composer::SingletonLogger �̓v���Z�X����Singleton�ł��邱�Ƃ��ۏႳ�ꂽ�ALogger�ւ�Delegator(��肭�ǂ�������...)�B)
	#3. ��͌��ʂ̎擾�́A(self.)calendars , (self.)jobs ����p����B
	#4. ���̑��AComposer::BaseMake���Œ�`����Ă��郁�\�b�h�͓K�X�g�p�\�B
	#5. face/default_face/default_face.rb , face/stream_plan/stream_plan.rb ���Q�Ƃ̂��ƁB
	#
	#== Built-in Faces.
	#Composer::Face::DefaultFace :: �f�t�H���g�̑g�ݍ���Face�BErb���g�p�����V���v����CSV�o�́B
	#Composer::Face::StreamPlan :: �g�ݍ���Face�BMicrosoft Excel���g�p�����A1����=1�V�[�g�őS�W���u�X�g���[���̔z�M�\���CALENDAR,SCHEDULE�̉�͌��ʂ��o�́B
	#Composer::Face::Jobnet :: �g�ݍ���Face�Bgraphviz(�����T�C�g http://www.graphviz.org/) ���g�p�����A�W���u�X�g���[���Ԃ̊֌W���r�W���A���ɏo��(�o�͌`����graphviz�Ɉˑ�)�B
	#
	module BaseMake

		#Composer::BaseMake��include�����N���X��initialize���`����B
		#@caller�Ƃ��ČĂь���FrontEnd�I�u�W�F�N�g���A���̑�Composer::BaseMake��
		#�h�L�������g�ɂċL�q�����e��C���X�^���X�ϐ��̏������A�y�сA:on_setup����`����Ă���ꍇ�ɂ́A
		#:on_setup�̌Ăяo�����s���B
		def initialize(caller,face_def)
			@caller=caller
			@logger=SingletonLogger.instance
			#���s����face�N���X�̊i�[����Ă���p�X
			@my_dir="#{Composer::BASE_DIR}/face/#{face_def}"
			#���s���ʂ��o�͂��ׂ��p�X
			@outfiles_dir=OUTFILES_DIR
			on_setup if self.respond_to?(:on_setup)
		end
		
		#calendar �̉�͌���(Composer::TwsObj::Calendar�̔z��)�𓾂�B
		#block���w�肳�ꂽ�ꍇ�ɂ̓t�B���^�����ƌ��Ȃ��A��͌��ʂ̂����u���b�N��]���������ʂ��^�ƂȂ�v�f�݂̂�ԋp����B
		def calendars(&b)
			if block_given?
				@caller.calendars.find_all &b
			else
				@caller.calendars
			end
		end
		#job �̉�͌���(Composer::TwsObj::Job�̔z��)�𓾂�B
		#block���w�肳�ꂽ�ꍇ�ɂ̓t�B���^�����ƌ��Ȃ��A��͌��ʂ̂����u���b�N��]���������ʂ��^�ƂȂ�v�f�݂̂�ԋp����B
		def jobs(&b)
			if block_given?
				@caller.jobs.find_all &b
			else
				@caller.jobs
			end
		end
		#parameter �̉�͌���(Composer::TwsObj::Parameter�̔z��)�𓾂�B
		#block���w�肳�ꂽ�ꍇ�ɂ̓t�B���^�����ƌ��Ȃ��A��͌��ʂ̂����u���b�N��]���������ʂ��^�ƂȂ�v�f�݂̂�ԋp����B
		def parameters(&b)
			if block_given?
				@caller.parameters.find_all &b
			else
				@caller.parameters
			end
		end
		#prompt �̉�͌���(Composer::TwsObj::Prompt�̔z��)�𓾂�B
		#block���w�肳�ꂽ�ꍇ�ɂ̓t�B���^�����ƌ��Ȃ��A��͌��ʂ̂����u���b�N��]���������ʂ��^�ƂȂ�v�f�݂̂�ԋp����B
		def prompts(&b)
			if block_given?
				@caller.prompts.find_all &b
			else
				@caller.prompts
			end
		end
		#resource �̉�͌���(Composer::TwsObj::Resource�̔z��)�𓾂�B
		#block���w�肳�ꂽ�ꍇ�ɂ̓t�B���^�����ƌ��Ȃ��A��͌��ʂ̂����u���b�N��]���������ʂ��^�ƂȂ�v�f�݂̂�ԋp����B
		def resources(&b)
			if block_given?
				@caller.resources.find_all &b
			else
				@caller.resources
			end
		end
		#schedule �̉�͌���(Composer::TwsObj::Schedule�̔z��)�𓾂�B
		#block���w�肳�ꂽ�ꍇ�ɂ̓t�B���^�����ƌ��Ȃ��A��͌��ʂ̂����u���b�N��]���������ʂ��^�ƂȂ�v�f�݂̂�ԋp����B
		def schedules(&b)
			if block_given?
				@caller.schedules.find_all &b
			else
				@caller.schedules
			end
		end
		#cpunames �̉�͌���(Composer::TwsObj::CpuName�̔z��)�𓾂�B
		#block���w�肳�ꂽ�ꍇ�ɂ̓t�B���^�����ƌ��Ȃ��A��͌��ʂ̂����u���b�N��]���������ʂ��^�ƂȂ�v�f�݂̂�ԋp����B
		def cpunames(&b)
			if block_given?
				@caller.cpunames.find_all &b
			else
				@caller.cpunames
			end
		end
		#cpuclass �̉�͌���(Composer::TwsObj::CpuClass�̔z��)�𓾂�B
		#block���w�肳�ꂽ�ꍇ�ɂ̓t�B���^�����ƌ��Ȃ��A��͌��ʂ̂����u���b�N��]���������ʂ��^�ƂȂ�v�f�݂̂�ԋp����B
		def cpuclasses(&b)
			if block_given?
				@caller.cpuclasses.find_all &b
			else
				@caller.cpuclasses
			end
		end
		#domain �̉�͌���(Composer::TwsObj::Domain�̔z��)�𓾂�B
		#block���w�肳�ꂽ�ꍇ�ɂ̓t�B���^�����ƌ��Ȃ��A��͌��ʂ̂����u���b�N��]���������ʂ��^�ƂȂ�v�f�݂̂�ԋp����B
		def domains(&b)
			if block_given?
				@caller.domains.find_all &b
			else
				@caller.domains
			end
		end

		#0����1�ɕϊ�����B
		#�^�Ȃ��'1'�A�U(nil,false)�Ȃ��'0'
		#
		#empty?���^�Ȃ�΋U�Ƃ��Ĉ����B
		def zero_one(bool)
			if bool.respond_to?(:empty?)
				if bool.empty?
					return 0 # ��̏ꍇ�͋U
				else
					return 1
				end
			end
			bool ? "1" : "0"
		end

		#Y����N�ɕϊ�����B
		#�^�Ȃ��'Y'�A�U(nil,false)�Ȃ��'N'
		#
		#empty?���^�Ȃ�΋U�Ƃ��Ĉ����B
		def yes_no(bool)
			if zero_one(bool)=='1'
				return 'Y'
			else
				return 'N'
			end
		end

		#�����Ŏ󂯎����collection�̊e�v�f��linewidth(�f�t�H���g��1)����1�s�Ƃ����������ԋp����B
		#�e�t�B�[���h��separator(�f�t�H���g��',')�ŋ�؂���B
		# > How to use.
		# data=%w( A B C D E F G )
		# multi_line_string(data) #=> "\"A,\nB,\nC,\nD,\nE,\nF,\nG\""
		# multi_line_string(data,3) #=> "\"A,B,C,\nD,E,F,\nG\""
		# multi_line_string(data,3,'=') #=> "\"A=B=C=\nD=E=F=\nG\""
		#�u���b�N�Ƌ��ɌĂ񂾍ۂɂ́Acollection�̊e�v�f�Ńu���b�N��]�������l��p���ĘA���B
		# > How to use.
		# data=%w( A B C D E F G )
		# multi_line_string(data){|i| i.downcase } #=> "\"a,\nb,\nc,\nd,\ne,\nf,\ng\""
		def multi_line_string(collection,linewidth=1,separator=",")
			return '' unless collection
			collection=collection.dup
			if collection.size==1
				if block_given?
					return(yield collection.first)
				else
					return collection.first.to_s
				end
			end
			column_buffer=[]
			record_buffer=[]
			until collection.empty?
				linewidth.times{|n|
					unless collection.empty?
						if block_given?
							column_buffer.push(yield(collection.shift))
						else
							column_buffer.push collection.shift.to_s
						end
					end
				}
				record_buffer.push column_buffer.join(separator)
				column_buffer=[]
			end
			return '"'+record_buffer.join("#{separator}\n").gsub(/"/,'""')+'"'
		end
	end

	#SCHEDULE�I�u�W�F�N�g���ŕێ����Ă�����t�̌v�Z���s���B
	class DateCalculater
		def initialize(schedule,fromdate,todate,calendars)
			@schedule=schedule
			@fromdate=fromdate
			@todate=todate
			@calendars=calendars
			@logger=SingletonLogger.instance
		end

		#Schedule�I�u�W�F�N�g���Œ�`����Ă�����t���v�Z���A����Date�z���ԋp����B
		#���ݍs���Ă���̂́AON��Ŏw�肳�ꂽ���t�Z�b�g��Except��Ŏw�肳�ꂽ���t�Z�b�g�̍���ԋp���Ă���̂݁B
		#
		#FIXME �{���͋x���J�����_�[(�f�t�H���g�Ȃ��HOLIDAYS,FREEDAYS�w�肳��Ă����炻�̃J�����_�[����菜���K�v������H�����āA�̂��l�B
		def calculate
			#on
			on_dates=[]
			@schedule.on.each{|sched_date| on_dates.push expand_dates(sched_date)}
			on_dates.flatten!
			@logger.debug("#{self.class}"){"ON dates is [ #{on_dates.collect do |d| d.to_s end.join(' ')} ]"}

			#except
			except_dates=[]
			@schedule.except.each{|sched_date| except_dates.push expand_dates(sched_date)}
			except_dates.flatten!
			@logger.debug("#{self.class}"){"Except dates is [ #{except_dates.collect do |d| d.to_s end.join(' ')} ]"}

			planned_dates=on_dates-except_dates
			@logger.debug("#{self.class}"){"Planned dates is [ #{planned_dates.collect do |d| d.to_s end.join(' ')} ]"}
			planned_dates.sort
		end

		#�J�����_�[������������A���e����������������Ȃǂŕ\�����ꂽ�A
		#ScheduledDate���A�I�t�Z�b�g�����������t���b�g�ȓ��t�I�u�W�F�N�g�ɓW�J����B
		#���̍ۂɁA@fromdate�y��@todate��p���ē��t�̌��E�l���߂�B('mo','everyday' ���A�����z��������w���q�ɑΉ����邽��)
		def expand_dates(sched_date)
			date_buffer=[]
			value=sched_date.value.upcase
			offset=sched_date.offset

			case value
			when /(\d\d)\/(\d\d)\/(\d\d)/
				date=Date.parse(value,true)
				if date < @fromdate || date > @todate
					@logger.debug("#{self.class}"){"date:[ #{date.to_s} ] is out of range [ #{@fromdate.to_s} to #{@todate.to_s} ]"}
				else
					date_buffer.push date
				end
			when 'SU'
				@fromdate.upto(@todate){|d| date_buffer.push d if d.wday==0 }
			when 'MO'
				@fromdate.upto(@todate){|d| date_buffer.push d if d.wday==1 }
			when 'TU'
				@fromdate.upto(@todate){|d| date_buffer.push d if d.wday==2 }
			when 'WE'
				@fromdate.upto(@todate){|d| date_buffer.push d if d.wday==3 }
			when 'TH'
				@fromdate.upto(@todate){|d| date_buffer.push d if d.wday==4 }
			when 'FR'
				@fromdate.upto(@todate){|d| date_buffer.push d if d.wday==5 }
			when 'SA'
				@fromdate.upto(@todate){|d| date_buffer.push d if d.wday==6 }
			when 'WEEKDAYS'
				@fromdate.upto(@todate){|d| date_buffer.push d unless d.wday==6 || d.wday==0 }
			when 'EVERYDAY'
				@fromdate.upto(@todate){|d| date_buffer.push d }
			when 'WORKDAYS'
				_holiday=nil
				workdays=[] # �y������������(�������AFREEDAYS�w�肳��Ă���ꍇ�ɂ̓I�v�V�����Ɉˑ�)
				if @schedule.freedays_cal
					_holiday=@calendars.find{|cal| cal.name==@schedule.freedays_cal }
					@logger.warn("#{self.class}"){"calendar [ #{@schedule.freedays_cal} ] was NOT found. ignored."} unless _holiday
					#�y���������������v�Z(FREEDAYS�̃I�v�V�����ɂ͈ˑ�)
					if opt=@schedule.freedays_opt
						opt=opt.collect{|s| s.upcase }
						filter=[0,6]
						filter.delete(6) if opt.include?('-SA') #�y�j���͉ғ����Ƃ̎w��̏ꍇ
						filter.delete(0) if opt.include?('-SU') #���j���͉ғ����Ƃ̎w��̏ꍇ
						@fromdate.upto(@todate){|d| 
							if filter.empty?
								workdays.push d
							else
								workdays.push d unless filter.include?(d.wday)
							end
						}
					else
						@fromdate.upto(@todate){|d| workdays.push d unless d.wday==6 || d.wday==0 }
					end
				else
					_holiday=@calendars.find{|cal| cal.name=='HOLIDAYS' }
					@logger.warn("#{self.class}"){"calendar [ HOLIDAYS ] was NOT found. ignored."} unless _holiday
					#�y���������������v�Z
					@fromdate.upto(@todate){|d| workdays.push d unless d.wday==6 || d.wday==0 }
				end

				date_buffer=workdays-_holiday.date_internal

			when 'FREEDAYS'
				_holiday=nil
				if @schedule.freedays_cal
					_holiday=@calendars.find{|cal| cal.name==@schedule.freedays_cal }
					@logger.warn("#{self.class}"){"calendar [ #{@schedule.freedays_cal} ] was NOT found. ignored."} unless _holiday
					if _holiday
						_holiday.dates{|d| date_buffer.push d if d > @fromdate && d < @todate }
					end
				else
					@logger.warn("#{self.class}"){"'ON/EXCEPT FREEDAYS' was specified, But NOT defined 'FREEDAYS CAL'. ignored."}
				end

			when 'REQUEST'
				# do nothing;
			else
				# may be calendar.
				@logger.debug("#{self.class}"){"[ #{value} ] may be calendar."}
				calendar=@calendars.find{|cal| cal.name.upcase == value }
				if calendar
					@logger.debug("#{self.class}"){"calendar [ #{calendar} ] was found."}
					if offset
						#�I�t�Z�b�g�̓K�p
						offset=offset.split(' ')
						plus_minus=offset.shift
						num=offset.shift.to_i
						unit=offset.shift.upcase
						@logger.debug("#{self.class}"){"Applying offsets [ #{plus_minus} ] [ #{num} ] [ #{unit} ] to [ #{calendar} ] ."}
						case unit
						when /\AWEEKDAY/
							# FIXME Not Implemented
						when /\AWORKDAY/
							# FIXME Not Implemented
						when /\ADAY/
							calendar.dates{|d|
								if plus_minus=='+'
									offseted=d+num
								elsif plus_minus=='-'
									offseted=d-num
								else
									offseted=d
								end
								@logger.debug("#{self.class}"){"offset applied date is [ #{offseted.to_s} ]"}
								date_buffer.push offseted if offseted > @fromdate && offseted < @todate
							}
						else
							@logger.warn("#{self.class}"){"offset string is not correct."}
						end
					else
						@logger.debug("#{self.class}"){"no offsets supplied. use [ #{calendar} ] directly ."}
						calendar.dates{|d| date_buffer.push d if d > @fromdate && d < @todate }
					end
				else
					@logger.warn("#{self.class}"){"Calendar [ #{value} ] was not found. ignored."}
				end
			end
			date_buffer
		end
		private :expand_dates
	end
end

