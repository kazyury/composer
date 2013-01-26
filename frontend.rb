#!ruby -Ks

require 'racc/parser'

require 'dirs'
require 'singleton_logger'
require 'errors'
require 'utils'

require 'parser/calendar'
require 'parser/cpuclass'
require 'parser/cpuname'
require 'parser/domain'
require 'parser/job'
require 'parser/parameter'
require 'parser/prompt'
require 'parser/resource'
require 'parser/schedule'
require 'scanner/generic_scanner'
require 'scanner/mode_switchable_scanner'


module Composer
	#= FrontEnd
	#�w�肳�ꂽComposer�̒�`���t�@�C���̓ǂݍ��݁A��́A�\���`���̕ϊ����s�����߂̃t�����g�G���h�B
	#scanner/parser/face�̊e�I�u�W�F�N�g�Q�̐���Ɍg���B
	#
	#�e�I�u�W�F�N�g�̎��s���R�[�����O�E�V�[�P���X�̊T���͈ȉ��̂Ƃ���B
	#== Abstract Calling Sequence.
	#
	# +-----+     +----------+   +--------+      +---------+   +--------+      +------+
	# | U/I |     | FrontEnd |   | Parser |      | Scanner |   | TwsObj |      | Face |
	# +-----+     +----------+   +--------+      +---------+   +--------+      +------+
	#    |*_def=()     |             |                |             |             |
	#    +------------>|             |                |             |             |
	#    |             |             |                |             |             |
	#    |parse()      |             |                |             |             |
	#    +------------>| new()       |                |             |             |
	#    |             +------------>|                |             |             |     =================\ 
	#    |             |             |                |             |             |                      |
	#    |             | parse()     |                |             |             |                      |
	#    |             +------------>|new(),scan()    |             |             |                      |
	#    |             |             +--------------->|             |             |                      | x N times
	#    |             |             |                |             |             |                      |
	#    |             |             |new()                         |             |                      |
	#    |             |             +----------------------------->|             |                      |
	#    |             |<<-----------+                                            |     =================/ 
	#    |face=()      |                                                          |
	#    +------------>|load(),new()                                              |     =================\ 
	#    |             +--------------------------------------------------------->|                      |
	#    |             |                                                          +----\                 |
	#    |             |                                                          |    | on_setup()      |
	#    |prepare()    |                                                          |<---/                 |
	#    +------------>|xxxxxxx() <--- method specified in :prepare               |                      |
	#    |             +--------------------------------------------------------->|                      |
	#    |             |xxxxxxx() <--- method specified in :prepare               |                      | x N times
	#    |             +--------------------------------------------------------->|                      |
	#    |             |                                                          |                      |
	#    |convert()    |                                                          |                      |
	#    +------------>|format()                                                  |                      |
	#    |             +--------------------------------------------------------->|                      |
	#    |             |on_exiting()                                              |                      |
	#    |             +--------------------------------------------------------->|                      |
	#    |             |                                                                =================/ 
	#
	#1. Composer::FrontEnd�́A*_def=���\�b�h(schedules_def=() ��)�ɂ��A��͑Ώۃt�@�C���̃p�X���󂯎��B
	#2. Composer::FrontEnd#parse()�ɂ��A��͑ΏۂɑΉ�����AComposer::Parser�Q��parser�C���X�^���X�𐶐����Aparser�C���X�^���X��parse()�����s����B
	#3. Composer::Parser::xParser�͎��炪�g�p����Composer::Scanner�Q��scanner�C���X�^���X�𐶐����Ascanner�C���X�^���X��scan()�����s����B(���ۂɂ́ARacc��yyparse���g�p�B�ڂ�����Racc�̃h�L�������g�����Q��)
	#4. Composer::Parser::xParser�͎���̉�͑Ώ�(Schedule��)��LALR(1)���@�ŊҌ������{����ۂɁAComposer::TwsObj�Q�̃C���X�^���X�𐶐����A��͌��ʂɊi�[����B
	#5. Composer::FrontEnd#face=() �Ŏw�肳�ꂽComposer::Face�Q�̃C���X�^���X��load�y��new����B
	#6. Composer::Face�Q��face�C���X�^���X�́A�����on_setup()����`����Ă���ꍇ�ɂ́Ainitialize���Ɏ��s����B
	#7. Composer::FrontEnd#prepare() (����pre_conversion()) �ɂāA���̎��_�ł�face�C���X�^���X�ɑ΂��ĕK�v�Ȏ��O�����̃��\�b�h���Ăяo���B(�K�v�Ȏ��O�����̃��\�b�h�́Aprepare()�̈����ɂĎw��B)
	#8. Composer::FrontEnd#convert�ɂ��A���̎��_�ł�face�C���X�^���X�ɑ΂�����s�w�����s���Bface�C���X�^���X��on_exiting()���\�b�h����`����Ă���ꍇ�ɂ́Aconvert�I�����on_exiting���Ăяo���B
	#9. Composer::FrontEnd#face=() , Composer::FrontEnd#prepare() , Composer::FrontEnd#convert()�̈�A�̗���́A������Face�Q�ɑ΂��ČJ��Ԃ����Ƃ��\�B
	#
	#== Calling Sequence Example
	# appl=Composer::FrontEnd.new
	# appl.schedules_def='/path/to/schedules_def_file'        #(1) �W���u�X�g���[���̒�`�t�@�C�����w��
	# appl.workstations_def='/path/to/workstations_def_file'  #(1) ���[�N�X�e�[�V�����̒�`�t�@�C�����w��
	# appl.calendars_def='/path/to/calendars_def_file'        #(1) �J�����_�[�̒�`�t�@�C�����w��
	# 
	# appl.parse #(2) ��͎��s�B���̗�ł�SCHEDULE,Workstation(CPUNAME,CPUCLASS,DOMAIN),CALENDAR�̉�͂��s���B
	#            #(3) ScheduleParser��ModeSwitchableScanner���A���̃p�[�T��GenericScanner�𐶐�����scan()���\�b�h�ɂĎ����͂��s���B
	#            #(4) SCHEDULE,CPUNAME,CPUCLASS,DOMAIN,CALENDAR�̂��ꂼ����Ҍ�����Composer::TwsObj�Q�̃C���X�^���X�𐶐��A��͌��ʂ̃X�^�b�N�ɐςށB
	# 
	# appl.face='my_face'                                     #(5) face/my_face/my_face.rb ��require���AComposer::Face::MyFace�̃C���X�^���X�𐶐�����B
	#                                                         #(6) MyFace#on_setup()����`����Ă���ꍇ�ɂ͂��̃^�C�~���O�ŌĂ΂��B
	# appl.prepare(:add_template,'default_calendar')          #(7) �ϊ����O�����̃��\�b�h(MyFace#add_template)���A����'default_calendar' �Ŏ��s
	# appl.convert                                            #(8) ��͓��e���w�肵���\���`���ŏo��
	#
	# appl.face='stream_plan'                                 #(9) ������face���g�p����ꍇ�ɂ́Aface=() -> prepare() -> convert �̏����J��Ԃ��B
	# appl.prepare(:range_set,'2006-01-01','2006-12-31')
	# appl.convert
	#
	#== Composer,Parser,Scanner and TwsObj
	#Composer��`���AComposer::Parser�Q�AComposer::Scanner�Q�A�y��Composer::TwsObj�Q�̊֘A�͈ȉ��̂Ƃ���B
	#Workstation�֘A�̕����͓���Ȍ`�ԂƂȂ��Ă���B
	#
	# +--------------+-------------------+-----------------------+--------------+
	# | composer(*1) | Parser            | Scanner               | TwsObj       |
	# +--------------+-------------------+-----------------------+--------------+
	# | calendars    | CalendarParser    | GenericScanner        | Calendar     |
	# +--------------+-------------------+-----------------------+--------------+
	# | parms        | ParameterParser   | GenericScanner        | Parameter    |
	# +--------------+-------------------+-----------------------+--------------+
	# | prompts      | PromptParser      | GenericScanner        | Prompt       |
	# +--------------+-------------------+-----------------------+--------------+
	# | resources    | ResourceParser    | GenericScanner        | Resource     |
	# +--------------+-------------------+-----------------------+--------------+
	# |              |                   |                       | CpuName      |
	# | cpu          | WorkstationParser | GenericScanner        | CpuClass     |
	# |              |                   |                       | Domain       |
	# +--------------+-------------------+-----------------------+--------------+
	# | jobs         | JobParser         | GenericScanner        | Job          |
	# +--------------+-------------------+-----------------------+--------------+
	# | sched        | ScheduleParser    | ModeSwitchableScanner | Schedule(*2) |
	# +--------------+-------------------+-----------------------+--------------+
	# | users        | NOT IMPLEMENTED   | -                     | -            |
	# +--------------+-------------------+--------------------------------------+
	# *1 : TWS composer�v���O������create�R�}���h�Ŏw�肷��from��̕�����(��. composer cr stemp from sched=@ �� sched ����)
	# *2 : Schedule�͓����ɑ���TwsObj�Q�N���X�̔z������B�ڍׂ�Composer::TwsObj::Schedule���Q��
	#
	#== See Also.
	#===Composer::Parser�Q
	#Racc::Parser���p�����Ă���A���M���ׂ����Ƃ͂��܂薳���B
	#���@�̏ڍׂ�m�肽���ꍇ�ɂ́Aparser/*_parser.y ��Racc���@�t�@�C���ƂȂ��Ă���̂ŁA��������m�F���邱�ƁB
	#
	#===Composer::Scanner�Q
	#Parser�Q�Ƒ΂ƂȂ�Scanner�Q�B
	#��{�I�ɂ�GenericScaner�ŗp���ׂ����ASchedule�ɂ��Ă�SCHEDULE��`���O�̍s�R�����g����͂̑ΏۂƂ������������߁A
	#��Ԃ����Ă�Scanner�ł���ModeSwitchableScanner���g�p���Ă���B
	#Composer::Scanner::GenericScanner :: �����͂��s�����߂̐��K�\���y�т���TOKEN�L���̃Z�b�g��ێ����A������𒀎��X�L��������X�L���i�B
	#Composer::Scanner::ModeSwitchableScanner :: GenericScanner���p�����A���[�h�ɂ��X�L�����Ώۂ̑I�ʂ��\�Ƃ��������X�L���i�B
	#
	#===Composer::TwsObj�Q
	#Composer�̃I�u�W�F�N�g��\������TwsObj�Q�B
	#1�C���X�^���X��Composer��1�I�u�W�F�N�g��\������B��{�I�ɂ�Composer�̕��@���1���ʎq��1�C���X�^���X�ϐ����Ή��t�����Ă���B(��O�L��)
  #Composer::TwsObj::Calendar :: 1�J�����_�[��\������N���X�B���t�͓����l�ł�Date�^�̔z��Ƃ��ĕێ����Ă���B
  #Composer::TwsObj::Parameter :: 1�p�����[�^��\������N���X�B
  #Composer::TwsObj::Prompt :: 1�v�����v�g��\������N���X�B
  #Composer::TwsObj::Resource :: 1���\�[�X��\������N���X�B
  #Composer::TwsObj::CpuName :: 1���[�N�X�e�[�V������\������N���X�B
  #Composer::TwsObj::CpuClass :: 1���[�N�X�e�[�V�����N���X��\������N���X�B
  #Composer::TwsObj::Domain :: 1�h���C����\������N���X�B
  #Composer::TwsObj::Job :: 1�W���u��\������N���X�B
	#
  #Composer::TwsObj::Schedule :: 1�W���u�X�g���[��(�X�P�W���[��)��\������N���X�B�����ɂ͈ȉ���TwsObj�Q�C���X�^���X�̔z��y�сAComposer::TwsObj::Resource�̔z��(NEEDS��)�����B
  #Composer::TwsObj::DependFile :: �W���u�X�g���[����1�ˑ��t�@�C��(OPENS��)��\������N���X�B
  #Composer::TwsObj::Follow :: �W���u(or�W���u�X�g���[��)��1�ˑ���s�W���u(or�W���u�X�g���[��)(FOLLOWS��)��\������N���X
  #Composer::TwsObj::ScheduledDate :: �W���u�X�g���[�����̃I�t�Z�b�g���܂߂����t�w���(ON,EXCEPT)���Ŏw�肳�����t�Z�b�g��\������N���X�Bmm/dd/yy�ɂ����t�w��A'MO'���ɂ�郊�e�����w��A�J�����_�[�w�肪�܂܂��B
  #Composer::TwsObj::ScheduledTime :: �W���u�X�g���[�����̃I�t�Z�b�g���܂߂������w���(AT,UNTIL,DEADLINE)���Ŏw�肳��鎞����\������N���X�B
  #Composer::TwsObj::ScheduledJob :: �W���u�X�g���[�����Œ�`�����A�X�P�W���[�����O��`���܂�1�W���u��\������N���X�BComposer::TwsObj::Job���p������B
	class FrontEnd
	
		#FrontEnd�I�u�W�F�N�g�𐶐�����B
		#��1������Log���x���A��2������*Parser�̃f�o�b�O�o�́A��3�����͓��̓t�@�C���̕����R�[�h�Z�b�g�B
		#Log���x���ɂ��ẮAruby�W���Y�t��logger.rb�Q��
		# > How to use.
		# fe=FrontEnd.new(Logger::DEBUG, true) #=> ���O���x����Logger::DEBUG�ɁARacc�̃f�o�b�O���[�h��ON�ɁB
		# fe=FrontEnd.new() #=> �f�t�H���g�ł̓��O���x����Logger::WARN,Racc�f�o�b�O��OFF�B
		def initialize(log_level=Logger::WARN, racc_debug=false, def_file_kcode='SJIS')
			@calendars_def = nil # calendar �̒�`�t�@�C���B
			@jobs_def      = nil
			@parameters_def= nil
			@prompts_def   = nil
			@resources_def = nil
			@schedules_def = nil
			@workstations_def = nil 
			@logger=SingletonLogger.instance
			@logger.level=log_level
			@racc_debug=racc_debug
			@def_file_kcode=def_file_kcode
			@face=load_face('default_face')
			@use_cache=false
			@tws_level="82"
			@result = {}
			@result.default=[]
		end
		attr_accessor :calendars_def, :jobs_def, :parameters_def, :prompts_def, :resources_def, :schedules_def, :workstations_def, :use_cache
		attr_reader :racc_debug, :def_file_kcode, :face, :tws_level

		#calendar �̉�͌��ʂ𓾂�B�߂�l�� Composer::TwsObj::Calendar �̔z��B
		def calendars; @result[:calendars]; end
		#job �̉�͌��ʂ𓾂�B�߂�l�� Composer::TwsObj::Job �̔z��B
		def jobs; @result[:jobs]; end
		#parameter �̉�͌��ʂ𓾂�B�߂�l�� Composer::TwsObj::Parameter�̔z��B
		def parameters; @result[:parameters]; end
		#prompt �̉�͌��ʂ𓾂�B�߂�l�� Composer::TwsObj::Prompt �̔z��B
		def prompts; @result[:prompts]; end
		#resource �̉�͌��ʂ𓾂�B�߂�l�� Composer::TwsObj::Resource �̔z��B
		def resources; @result[:resources]; end
		#schedule �̉�͌��ʂ𓾂�B�߂�l�� Composer::TwsObj::Schedule �̔z��B
		def schedules; @result[:schedules]; end
		#cpunames(aka, wkstation) �̉�͌��ʂ𓾂�B�߂�l�� Composer::TwsObj::CpuName �̔z��B
		def cpunames; @result[:cpunames]; end
		#cpuclass(aka, wkstationclass) �̉�͌��ʂ𓾂�B�߂�l�� Composer::TwsObj::CpuClass �̔z��B
		def cpuclasses; @result[:cpuclasses]; end
		#domain �̉�͌��ʂ𓾂�B�߂�l�� Composer::TwsObj::Domain �̔z��B
		def domains; @result[:domains]; end

		#log_level��ύX����B
		#
		#��{�I�ɁA
		#- �X�L���i�n�̃N���X��logger.debug
		#- �p�[�T�n�̃N���X��logger.info
		#��p���Ă���̂ŁA�X�L���i�̏ڍׂ����邽�߂ɂ�Logger::DEBUG�ɂ���K�v������B
		def log_level=(level)
			@logger.level=level
		end
    
		# ��������TWS�̃o�[�W�������w�肷��B
    # �f�t�H���g��8.2(���������`���F82)
		def tws_level=(level)
			buf=level.to_s.gsub(/\./,'')
      @tws_level=buf
      begin
        require "parser/calendar_parser#{@tws_level}"
        require "parser/calendar_parser_core#{@tws_level}"
        require "parser/workstation_parser#{@tws_level}"
        require "parser/workstation_parser_core#{@tws_level}"
        require "parser/job_parser#{@tws_level}"
        require "parser/job_parser_core#{@tws_level}"
        require "parser/parameter_parser#{@tws_level}"
        require "parser/parameter_parser_core#{@tws_level}"
        require "parser/prompt_parser#{@tws_level}"
        require "parser/prompt_parser_core#{@tws_level}"
        require "parser/resource_parser#{@tws_level}"
        require "parser/resource_parser_core#{@tws_level}"
        require "parser/schedule_parser#{@tws_level}"
        require "parser/schedule_parser_core#{@tws_level}"
      rescue LoadError=>e
				@logger.error(self.class){"TWS level #{level} is not supported."}
        raise e
      end
		end

		#�p�[�T�W�F�l���[�^(Racc)�̃f�o�b�O(@yydebug)��؂�ւ���
		def racc_debug=(bool)
			@racc_debug=bool
		end

		#���̓t�@�C���̕����R�[�h�Z�b�g���w��(�f�t�H���g��SJIS)�B
		#�g�p�ł��镶���R�[�h�Z�b�g�ɂ��Ă�ruby�̎d�l�Ɉˑ��B
		def def_file_kcode=(kcode)
			case kcode
			when /^s/i, /^e/i,/^u/i
				@def_file_kcode=kcode
			else
				@logger.warn(self.class){ "KCODE should be SJIS or EUC or UTF-8 but was [ #{kcode} ].Not changed." }
			end
		end

		#��͂����s����B
		def parse()
			current_kcode=$KCODE
			@logger.info(self.class){ "original KCODE was       #{current_kcode}" }
			$KCODE=@def_file_kcode
			@logger.info(self.class){ "current  KCODE is set to #{@def_file_kcode}" }

			%w(calendar job parameter prompt resource schedule workstation).each{|item|
				# �p�[�T�N���X
				parser_class = Composer::Parser.const_get("#{item.capitalize}Parser")
				# @xxxx_def�̒��g(���̓t�@�C���p�X)
				inst_var= self.instance_variable_get("@#{item}s_def")
				if parsable?(inst_var)
					if @use_cache && cache_usable?(item,inst_var)
						# cache�̎g�p���ݒ肳��Ă���A���L���b�V�����g�p�\�ł���Ȃ��
						# cache����Ă���p�[�X���ʂ�@result�Ƀ}�[�W����B
						@logger.info(self.class){ "Restoring cache for file:[ #{inst_var} ]." }
						@result.merge! load_cache(item)
					else
						@logger.info(self.class){ "Parsing file:[ #{inst_var} ] with [ #{parser_class} ]." }
						parser_obj=parser_class.new
						parser_obj.racc_debug(@racc_debug)
						result=parser_obj.parse(inst_var)
						dump_cache(item,result,inst_var)
						@result.merge! result
					end
				end
			}
			$KCODE=current_kcode
			@logger.info(self.class){ "current KCODE is set back to #{current_kcode}" }
			@logger.info(self.class){ "[ #{@result.keys.join(' ')} ] was parsed." }
			@result
		end

		#�o�͂���Face�N���X���w�肷��B(�f�t�H���g��Composer::Face::DefaultFace)
		#
		#�g�ݍ��݈ȊO��Face�N���X��Ǝ��ɍ쐬����ꍇ�ɂ́Autils.rb ��BaseMake���W���[���̐������Q�ƁB
		#
		# > How to use.
		# appl=Composer::FrontEnd.new
		# appl.face='default_face' 
		#		#=> face/default_face/default_face.rb ��ǂݍ��݁AComposer::Face::DefaultFace�I�u�W�F�N�g��Face�Ƃ��Ďw�肷��B
		#
		def face=(face_def)
			@face=load_face(face_def)
		end

		#Face�I�u�W�F�N�g�̕ϊ����s�O�ɍs�킹����������A���\�b�h�V���{���Ƃ��̈����̑g�ݍ��킹�Ŏw�肷��B
		# > How to use.
		# appl=Composer::FrontEnd.new
		# appl.face='default_face' 
		# appl.pre_conversion("add_template",%w(schedule job calendar))
		#      #=> DefaultFace#add_template( %w(schedule job calendar) ) �����s����B
		def pre_conversion(meth,*args)
			@face.__send__(meth,*args)
		end
		alias :prepare :pre_conversion

		#Face�I�u�W�F�N�g�ɕ\���`���̕ϊ�(�o��)���˗�����B
		def convert
			begin
				@face.format
			ensure
				@face.on_exiting if @face.respond_to?(:on_exiting)
			end
		end

		#--- private methods. ---

		#�����Ŏ󂯎����@xxx_def���^���A���̎w���Ă���悪���K�̃t�@�C���ł���ꍇ�ɁA�^��ԋp�B
		def parsable?(ivar)
			return false unless ivar
			unless File.file?(ivar)
				@logger.warn(self.class){"File [ #{ivar} ] was not found. ignore."}
				return false
			else
				return true
			end
		end
		private :parsable?

		def load_face(face_def)
			# location of face-def script.
			loc="#{Composer::FACE_DIR}/#{face_def}/#{face_def}"
			require loc
			# create Face object.
			mod_name=Composer::Face.const_get(face_def.split('_').collect{|w| w.capitalize }.join(''))
			obj=mod_name.new(self,face_def)
			obj
		end
		private :load_face

		#item�Ŏw�肳�ꂽ�I�u�W�F�N�g��cache file�����݂��A����@xxxxxx_def�Ŏw�肳�ꂽ�t�@�C���Ɠ����e�ł���ꍇ��true
		def cache_usable?(item,def_file_path)
			cached_src="#{Composer::CACHE_DIR}/#{item}.src"
			unless File.exist?(cached_src) 
				@logger.info(self.class){"cached src[ #{cached_src} ] is not exist. cannot use cache."}
				return false
			end
			cached=File.read(cached_src)
			deffile=File.read(def_file_path)
			if cached==deffile
				return true
			else
				@logger.info(self.class){"cached src[ #{cached_src} ] differs from [ #{def_file_path} ]. cannot use cache."}
				return false
			end
		end
		private :cache_usable?

		#item�Ŏw�肳�ꂽ�L���b�V���I�u�W�F�N�g��ǂݍ��ށB
		def load_cache(item)
			cached_obj="#{Composer::CACHE_DIR}/#{item}.parsed"
			return nil unless File.exist?(cached_obj)
			ret=nil
			File.open(cached_obj,"r"){|f| ret=Marshal.load(f) }
			return ret
		end
		private :load_cache

		def dump_cache(item,result,def_file_path)
			cached_src="#{Composer::CACHE_DIR}/#{item}.src"
			cached_obj="#{Composer::CACHE_DIR}/#{item}.parsed"
			File.open(cached_obj,"w"){|f| Marshal.dump(result,f) }
			File.open(cached_src,"w"){|f| f.puts File.read(def_file_path) }
		end
		private :dump_cache

	end
end

