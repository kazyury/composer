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
	#指定されたComposerの定義情報ファイルの読み込み、解析、表現形式の変換を行うためのフロントエンド。
	#scanner/parser/faceの各オブジェクト群の制御に携わる。
	#
	#各オブジェクトの実行時コーリング・シーケンスの概略は以下のとおり。
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
	#1. Composer::FrontEndは、*_def=メソッド(schedules_def=() 等)により、解析対象ファイルのパスを受け取る。
	#2. Composer::FrontEnd#parse()により、解析対象に対応する、Composer::Parser群のparserインスタンスを生成し、parserインスタンスのparse()を実行する。
	#3. Composer::Parser::xParserは自らが使用するComposer::Scanner群のscannerインスタンスを生成し、scannerインスタンスのscan()を実行する。(実際には、Raccのyyparseを使用。詳しくはRaccのドキュメント等を参照)
	#4. Composer::Parser::xParserは自らの解析対象(Schedule等)をLALR(1)文法で還元を実施する際に、Composer::TwsObj群のインスタンスを生成し、解析結果に格納する。
	#5. Composer::FrontEnd#face=() で指定されたComposer::Face群のインスタンスをload及びnewする。
	#6. Composer::Face群のfaceインスタンスは、自らにon_setup()が定義されている場合には、initialize時に実行する。
	#7. Composer::FrontEnd#prepare() (又はpre_conversion()) にて、その時点でのfaceインスタンスに対して必要な事前準備のメソッドを呼び出す。(必要な事前準備のメソッドは、prepare()の引数にて指定。)
	#8. Composer::FrontEnd#convertにより、その時点でのfaceインスタンスに対する実行指示を行う。faceインスタンスにon_exiting()メソッドが定義されている場合には、convert終了後にon_exitingを呼び出す。
	#9. Composer::FrontEnd#face=() , Composer::FrontEnd#prepare() , Composer::FrontEnd#convert()の一連の流れは、複数のFace群に対して繰り返すことが可能。
	#
	#== Calling Sequence Example
	# appl=Composer::FrontEnd.new
	# appl.schedules_def='/path/to/schedules_def_file'        #(1) ジョブストリームの定義ファイルを指定
	# appl.workstations_def='/path/to/workstations_def_file'  #(1) ワークステーションの定義ファイルを指定
	# appl.calendars_def='/path/to/calendars_def_file'        #(1) カレンダーの定義ファイルを指定
	# 
	# appl.parse #(2) 解析実行。この例ではSCHEDULE,Workstation(CPUNAME,CPUCLASS,DOMAIN),CALENDARの解析を行う。
	#            #(3) ScheduleParserはModeSwitchableScannerを、他のパーサはGenericScannerを生成してscan()メソッドにて字句解析を行う。
	#            #(4) SCHEDULE,CPUNAME,CPUCLASS,DOMAIN,CALENDARのそれぞれを還元時にComposer::TwsObj群のインスタンスを生成、解析結果のスタックに積む。
	# 
	# appl.face='my_face'                                     #(5) face/my_face/my_face.rb をrequireし、Composer::Face::MyFaceのインスタンスを生成する。
	#                                                         #(6) MyFace#on_setup()が定義されている場合にはこのタイミングで呼ばれる。
	# appl.prepare(:add_template,'default_calendar')          #(7) 変換事前準備のメソッド(MyFace#add_template)を、引数'default_calendar' で実行
	# appl.convert                                            #(8) 解析内容を指定した表現形式で出力
	#
	# appl.face='stream_plan'                                 #(9) 複数のfaceを使用する場合には、face=() -> prepare() -> convert の順を繰り返す。
	# appl.prepare(:range_set,'2006-01-01','2006-12-31')
	# appl.convert
	#
	#== Composer,Parser,Scanner and TwsObj
	#Composer定義情報、Composer::Parser群、Composer::Scanner群、及びComposer::TwsObj群の関連は以下のとおり。
	#Workstation関連の部分は特殊な形態となっている。
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
	# *1 : TWS composerプログラムのcreateコマンドで指定するfrom句の文字列(例. composer cr stemp from sched=@ の sched 部分)
	# *2 : Scheduleは内部に他のTwsObj群クラスの配列を持つ。詳細はComposer::TwsObj::Scheduleを参照
	#
	#== See Also.
	#===Composer::Parser群
	#Racc::Parserを継承しており、特筆すべきことはあまり無い。
	#文法の詳細を知りたい場合には、parser/*_parser.y がRacc文法ファイルとなっているので、そちらを確認すること。
	#
	#===Composer::Scanner群
	#Parser群と対となるScanner群。
	#基本的にはGenericScanerで用を為すが、ScheduleについてはSCHEDULE定義直前の行コメントを解析の対象としたかったため、
	#状態を持てるScannerであるModeSwitchableScannerを使用している。
	#Composer::Scanner::GenericScanner :: 字句解析を行うための正規表現及びそのTOKEN記号のセットを保持し、文字列を逐次スキャンするスキャナ。
	#Composer::Scanner::ModeSwitchableScanner :: GenericScannerを継承しつつ、モードによるスキャン対象の選別を可能とした逐次スキャナ。
	#
	#===Composer::TwsObj群
	#Composerのオブジェクトを表現するTwsObj群。
	#1インスタンスでComposerの1オブジェクトを表現する。基本的にはComposerの文法上の1識別子に1インスタンス変数が対応付けられている。(例外有り)
  #Composer::TwsObj::Calendar :: 1カレンダーを表現するクラス。日付は内部値ではDate型の配列として保持している。
  #Composer::TwsObj::Parameter :: 1パラメータを表現するクラス。
  #Composer::TwsObj::Prompt :: 1プロンプトを表現するクラス。
  #Composer::TwsObj::Resource :: 1リソースを表現するクラス。
  #Composer::TwsObj::CpuName :: 1ワークステーションを表現するクラス。
  #Composer::TwsObj::CpuClass :: 1ワークステーションクラスを表現するクラス。
  #Composer::TwsObj::Domain :: 1ドメインを表現するクラス。
  #Composer::TwsObj::Job :: 1ジョブを表現するクラス。
	#
  #Composer::TwsObj::Schedule :: 1ジョブストリーム(スケジュール)を表現するクラス。内部には以下のTwsObj群インスタンスの配列及び、Composer::TwsObj::Resourceの配列(NEEDS句)を持つ。
  #Composer::TwsObj::DependFile :: ジョブストリームの1依存ファイル(OPENS句)を表現するクラス。
  #Composer::TwsObj::Follow :: ジョブ(orジョブストリーム)の1依存先行ジョブ(orジョブストリーム)(FOLLOWS句)を表現するクラス
  #Composer::TwsObj::ScheduledDate :: ジョブストリーム内のオフセットを含めた日付指定句(ON,EXCEPT)内で指定される日付セットを表現するクラス。mm/dd/yyによる日付指定、'MO'等によるリテラル指定、カレンダー指定が含まれる。
  #Composer::TwsObj::ScheduledTime :: ジョブストリーム内のオフセットを含めた時刻指定句(AT,UNTIL,DEADLINE)内で指定される時刻を表現するクラス。
  #Composer::TwsObj::ScheduledJob :: ジョブストリーム内で定義される、スケジューリング定義を含んだ1ジョブを表現するクラス。Composer::TwsObj::Jobを継承する。
	class FrontEnd
	
		#FrontEndオブジェクトを生成する。
		#第1引数はLogレベル、第2引数は*Parserのデバッグ出力、第3引数は入力ファイルの文字コードセット。
		#Logレベルについては、ruby標準添付のlogger.rb参照
		# > How to use.
		# fe=FrontEnd.new(Logger::DEBUG, true) #=> ログレベルをLogger::DEBUGに、RaccのデバッグモードをONに。
		# fe=FrontEnd.new() #=> デフォルトではログレベルはLogger::WARN,RaccデバッグはOFF。
		def initialize(log_level=Logger::WARN, racc_debug=false, def_file_kcode='SJIS')
			@calendars_def = nil # calendar の定義ファイル。
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

		#calendar の解析結果を得る。戻り値は Composer::TwsObj::Calendar の配列。
		def calendars; @result[:calendars]; end
		#job の解析結果を得る。戻り値は Composer::TwsObj::Job の配列。
		def jobs; @result[:jobs]; end
		#parameter の解析結果を得る。戻り値は Composer::TwsObj::Parameterの配列。
		def parameters; @result[:parameters]; end
		#prompt の解析結果を得る。戻り値は Composer::TwsObj::Prompt の配列。
		def prompts; @result[:prompts]; end
		#resource の解析結果を得る。戻り値は Composer::TwsObj::Resource の配列。
		def resources; @result[:resources]; end
		#schedule の解析結果を得る。戻り値は Composer::TwsObj::Schedule の配列。
		def schedules; @result[:schedules]; end
		#cpunames(aka, wkstation) の解析結果を得る。戻り値は Composer::TwsObj::CpuName の配列。
		def cpunames; @result[:cpunames]; end
		#cpuclass(aka, wkstationclass) の解析結果を得る。戻り値は Composer::TwsObj::CpuClass の配列。
		def cpuclasses; @result[:cpuclasses]; end
		#domain の解析結果を得る。戻り値は Composer::TwsObj::Domain の配列。
		def domains; @result[:domains]; end

		#log_levelを変更する。
		#
		#基本的に、
		#- スキャナ系のクラスはlogger.debug
		#- パーサ系のクラスはlogger.info
		#を用いているので、スキャナの詳細を見るためにはLogger::DEBUGにする必要がある。
		def log_level=(level)
			@logger.level=level
		end
    
		# 処理するTWSのバージョンを指定する。
    # デフォルトは8.2(内部処理形式：82)
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

		#パーサジェネレータ(Racc)のデバッグ(@yydebug)を切り替える
		def racc_debug=(bool)
			@racc_debug=bool
		end

		#入力ファイルの文字コードセットを指定(デフォルトはSJIS)。
		#使用できる文字コードセットについてはrubyの仕様に依存。
		def def_file_kcode=(kcode)
			case kcode
			when /^s/i, /^e/i,/^u/i
				@def_file_kcode=kcode
			else
				@logger.warn(self.class){ "KCODE should be SJIS or EUC or UTF-8 but was [ #{kcode} ].Not changed." }
			end
		end

		#解析を実行する。
		def parse()
			current_kcode=$KCODE
			@logger.info(self.class){ "original KCODE was       #{current_kcode}" }
			$KCODE=@def_file_kcode
			@logger.info(self.class){ "current  KCODE is set to #{@def_file_kcode}" }

			%w(calendar job parameter prompt resource schedule workstation).each{|item|
				# パーサクラス
				parser_class = Composer::Parser.const_get("#{item.capitalize}Parser")
				# @xxxx_defの中身(入力ファイルパス)
				inst_var= self.instance_variable_get("@#{item}s_def")
				if parsable?(inst_var)
					if @use_cache && cache_usable?(item,inst_var)
						# cacheの使用が設定されており、かつキャッシュが使用可能であるならば
						# cacheされているパース結果を@resultにマージする。
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

		#出力するFaceクラスを指定する。(デフォルトはComposer::Face::DefaultFace)
		#
		#組み込み以外のFaceクラスを独自に作成する場合には、utils.rb のBaseMakeモジュールの説明を参照。
		#
		# > How to use.
		# appl=Composer::FrontEnd.new
		# appl.face='default_face' 
		#		#=> face/default_face/default_face.rb を読み込み、Composer::Face::DefaultFaceオブジェクトをFaceとして指定する。
		#
		def face=(face_def)
			@face=load_face(face_def)
		end

		#Faceオブジェクトの変換実行前に行わせたい動作を、メソッドシンボルとその引数の組み合わせで指定する。
		# > How to use.
		# appl=Composer::FrontEnd.new
		# appl.face='default_face' 
		# appl.pre_conversion("add_template",%w(schedule job calendar))
		#      #=> DefaultFace#add_template( %w(schedule job calendar) ) を実行する。
		def pre_conversion(meth,*args)
			@face.__send__(meth,*args)
		end
		alias :prepare :pre_conversion

		#Faceオブジェクトに表現形式の変換(出力)を依頼する。
		def convert
			begin
				@face.format
			ensure
				@face.on_exiting if @face.respond_to?(:on_exiting)
			end
		end

		#--- private methods. ---

		#引数で受け取った@xxx_defが真かつ、その指している先が正規のファイルである場合に、真を返却。
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

		#itemで指定されたオブジェクトのcache fileが存在し、かつ@xxxxxx_defで指定されたファイルと同内容である場合にtrue
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

		#itemで指定されたキャッシュオブジェクトを読み込む。
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

