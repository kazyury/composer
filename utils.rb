
require 'date'

#Ruby組み込みのDateクラスにヘルパメソッドを追加。
class Date
	#selfの年月の1日目を示すDateを返却する。
	#
	# 例
	# aDate=Date.new(2007,2,18) #=>2007-02-18を示すDate
	# aDate.first_day_of_month  #=>2007-02-01を示すDate
	def first_day_of_month
		Date.new(self.year, self.month, 1)
	end

	#selfの年月の晦日を示すDateを返却する。
	#
	# 例
	# aDate=Date.new(2007,2,18) #=>2007-02-18を示すDate
	# aDate.last_day_of_month   #=>2007-02-28を示すDate
	def last_day_of_month
		(self.first_day_of_month >> 1 ) - 1
	end

	#(主にStreamPlanで使用するために)selfのyyyy-mmを文字列で返却。
	#
	# 例
	# aDate=Date.new(2007,2,18) #=>2007-02-18を示すDate
	# aDate.year_and_month      #=>'2007-02'
	def year_and_month
		self.strftime("%Y-%m")
	end
end
		

module Composer
	#各Parser(Composer::Parser::ScheduleParser等)で共通して使用するメソッド群の実装
	module ParserUtils
		# racc のdebugモードをON/OFF
		def racc_debug(bool)
			@yydebug=bool
		end

		#現在スキャンしている行番号を格納する。
		def scan_line=(lineno)
			@lineno=lineno
		end

		#ナンダッケ？
		def is_valid?(expects, actual)
			str=actual.chomp.strip
			bool=expects.any?{|ex| ex.upcase == str.upcase}
			raise "Expected was [#{expects.join(',')}] but was [ #{str} ]" unless bool
			str
		end
		
		#Racc::ParseError のメッセージをオーバーライド
		def on_error(t,v,values)
			raise Racc::ParseError,"@#{@lineno}, syntax error on #{v.inspect}"
		end
	end

	
	#主にComposer::TwsObj系のクラスで共通して使用する、感受性の高いattr_writer,accessor の実装。
	#非nilのインスタンス変数に対する@ivar=(value)による変数値のアサイン時にlogger.warnを発生する。
	#
	#(けど、sensitive_reader は何もしないので、attr_reader と変わらない。対象性のためだけに用意。)
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

		#sensitive_writer で指定されたインスタンス変数が非nilである場合、@ivar=(value)による変数値アサイン時にlogger.warnを発生する。
		#(インスタンス変数へのアサインは行われる)
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

		#sensitive_accessor で指定されたインスタンス変数が非nilである場合、@ivar=(value)による変数値アサイン時にlogger.warnを発生する。
		#(インスタンス変数へのアサインは行われる)
		def sensitive_accessor(*ivars)
			sensitive_reader(*ivars)
			sensitive_writer(*ivars)
		end
	end

	#= BaseMake
	#Composerの表現形式を切り替えるためのベースモジュール。
	#各Faceクラスはこのモジュールをincludeする必要がある。
	#BaseMakeをincludeすることにより、YourFaceClass#initializeが定義され、最低限必要な各種インスタンス変数がセットされる。
	#
	#== create my OWN FACE, HOW TO .
	#
	#独自のFaceクラスを作成するには以下の手順に従う必要がある。
	#1. face ディレクトリ以下に、#{file_id}/#{file_id}.rb を作成する。
	#   composer_faceでfaceを指定する際には、この file_id を用いることとなる。
	#    例.
	#    'default_face' の場合には、default_face/default_face.rb を作成する。
	#2. #{file_id}.rb内に #{face_class_id} クラスを定義する。名前空間は、 Composer::Face 以下。
	#   face_class_id は file_id を元に、以下のルールにて変換した名称である必要がある。
	#   - file_id を'_'で分割する。
	#   - 分割後の各単語の先頭文字を大文字、残りを小文字にする。
	#   - 変換語の各文字を連結。
	#    例. 
	#    default_face => default face => Default Face => DefaultFace
	#3. #{face_class_id}クラスは、Composer::BaseMake をincludeする。
	#4. #{face_class_id}クラスでは、initializeメソッドは定義" <b>しない</b> "
	#5. #{face_class_id}クラスに、formatメソッドを定義" <b>する</b> "。
	#   このメソッドは、変換実行指示の際(FrontEnd#convert)時に呼び出される。
	#6. #{face_class_id}オブジェクトの生成時に初期化処理が必要な場合には、on_setup メソッド(引数無し)を定義する。
	#   このメソッドは(定義されている場合には)initialize時に呼ばれる。
	#7. 変換処理の終了時に後処理が必要な場合には、on_exiting メソッド(引数無し)を定義する。
	#   このメソッドは(定義されている場合には)convert後にFrontEndより呼ばれる。
	#8. あとは、お好みで適宜のクラスを設計。
	#
	#その他の参考情報
	#1. initialize 時に、@my_dir , @outfiles_dir が定義される。
	#   @my_dir:: 自ファイルの格納パス情報
	#   @outfiles_dir:: 出力ファイルパス情報
	#    例
	#    DefaultFace の場合、@my_dir=#{BASE_DIR}/face/default_face
	#    StreamPlan  の場合、@my_dir=#{BASE_DIR}/face/stream_plan
	#2. initialize時に、@logger(Composer::SingletonLogger インスタンス)が定義される。
	#   必要に応じて、@logger.warn等のメソッドを使用可能。
	#   (Composer::SingletonLogger はプロセス内でSingletonであることが保障された、LoggerへのDelegator(回りくどい説明だ...)。)
	#3. 解析結果の取得は、(self.)calendars , (self.)jobs 等を用いる。
	#4. その他、Composer::BaseMake内で定義されているメソッドは適宜使用可能。
	#5. face/default_face/default_face.rb , face/stream_plan/stream_plan.rb も参照のこと。
	#
	#== Built-in Faces.
	#Composer::Face::DefaultFace :: デフォルトの組み込みFace。Erbを使用したシンプルなCSV出力。
	#Composer::Face::StreamPlan :: 組み込みFace。Microsoft Excelを使用した、1ヶ月=1シートで全ジョブストリームの配信予定をCALENDAR,SCHEDULEの解析結果より出力。
	#Composer::Face::Jobnet :: 組み込みFace。graphviz(公式サイト http://www.graphviz.org/) を使用した、ジョブストリーム間の関係をビジュアルに出力(出力形式はgraphvizに依存)。
	#
	module BaseMake

		#Composer::BaseMakeをincludeしたクラスにinitializeを定義する。
		#@callerとして呼び元のFrontEndオブジェクトを、その他Composer::BaseMakeの
		#ドキュメントにて記述した各種インスタンス変数の初期化、及び、:on_setupが定義されている場合には、
		#:on_setupの呼び出しを行う。
		def initialize(caller,face_def)
			@caller=caller
			@logger=SingletonLogger.instance
			#実行時のfaceクラスの格納されているパス
			@my_dir="#{Composer::BASE_DIR}/face/#{face_def}"
			#実行結果を出力すべきパス
			@outfiles_dir=OUTFILES_DIR
			on_setup if self.respond_to?(:on_setup)
		end
		
		#calendar の解析結果(Composer::TwsObj::Calendarの配列)を得る。
		#blockが指定された場合にはフィルタ条件と見なし、解析結果のうちブロックを評価した結果が真となる要素のみを返却する。
		def calendars(&b)
			if block_given?
				@caller.calendars.find_all &b
			else
				@caller.calendars
			end
		end
		#job の解析結果(Composer::TwsObj::Jobの配列)を得る。
		#blockが指定された場合にはフィルタ条件と見なし、解析結果のうちブロックを評価した結果が真となる要素のみを返却する。
		def jobs(&b)
			if block_given?
				@caller.jobs.find_all &b
			else
				@caller.jobs
			end
		end
		#parameter の解析結果(Composer::TwsObj::Parameterの配列)を得る。
		#blockが指定された場合にはフィルタ条件と見なし、解析結果のうちブロックを評価した結果が真となる要素のみを返却する。
		def parameters(&b)
			if block_given?
				@caller.parameters.find_all &b
			else
				@caller.parameters
			end
		end
		#prompt の解析結果(Composer::TwsObj::Promptの配列)を得る。
		#blockが指定された場合にはフィルタ条件と見なし、解析結果のうちブロックを評価した結果が真となる要素のみを返却する。
		def prompts(&b)
			if block_given?
				@caller.prompts.find_all &b
			else
				@caller.prompts
			end
		end
		#resource の解析結果(Composer::TwsObj::Resourceの配列)を得る。
		#blockが指定された場合にはフィルタ条件と見なし、解析結果のうちブロックを評価した結果が真となる要素のみを返却する。
		def resources(&b)
			if block_given?
				@caller.resources.find_all &b
			else
				@caller.resources
			end
		end
		#schedule の解析結果(Composer::TwsObj::Scheduleの配列)を得る。
		#blockが指定された場合にはフィルタ条件と見なし、解析結果のうちブロックを評価した結果が真となる要素のみを返却する。
		def schedules(&b)
			if block_given?
				@caller.schedules.find_all &b
			else
				@caller.schedules
			end
		end
		#cpunames の解析結果(Composer::TwsObj::CpuNameの配列)を得る。
		#blockが指定された場合にはフィルタ条件と見なし、解析結果のうちブロックを評価した結果が真となる要素のみを返却する。
		def cpunames(&b)
			if block_given?
				@caller.cpunames.find_all &b
			else
				@caller.cpunames
			end
		end
		#cpuclass の解析結果(Composer::TwsObj::CpuClassの配列)を得る。
		#blockが指定された場合にはフィルタ条件と見なし、解析結果のうちブロックを評価した結果が真となる要素のみを返却する。
		def cpuclasses(&b)
			if block_given?
				@caller.cpuclasses.find_all &b
			else
				@caller.cpuclasses
			end
		end
		#domain の解析結果(Composer::TwsObj::Domainの配列)を得る。
		#blockが指定された場合にはフィルタ条件と見なし、解析結果のうちブロックを評価した結果が真となる要素のみを返却する。
		def domains(&b)
			if block_given?
				@caller.domains.find_all &b
			else
				@caller.domains
			end
		end

		#0又は1に変換する。
		#真ならば'1'、偽(nil,false)ならば'0'
		#
		#empty?が真ならば偽として扱う。
		def zero_one(bool)
			if bool.respond_to?(:empty?)
				if bool.empty?
					return 0 # 空の場合は偽
				else
					return 1
				end
			end
			bool ? "1" : "0"
		end

		#Y又はNに変換する。
		#真ならば'Y'、偽(nil,false)ならば'N'
		#
		#empty?が真ならば偽として扱う。
		def yes_no(bool)
			if zero_one(bool)=='1'
				return 'Y'
			else
				return 'N'
			end
		end

		#引数で受け取ったcollectionの各要素をlinewidth(デフォルトは1)個分を1行とした文字列を返却する。
		#各フィールドはseparator(デフォルトは',')で区切られる。
		# > How to use.
		# data=%w( A B C D E F G )
		# multi_line_string(data) #=> "\"A,\nB,\nC,\nD,\nE,\nF,\nG\""
		# multi_line_string(data,3) #=> "\"A,B,C,\nD,E,F,\nG\""
		# multi_line_string(data,3,'=') #=> "\"A=B=C=\nD=E=F=\nG\""
		#ブロックと共に呼んだ際には、collectionの各要素でブロックを評価した値を用いて連結。
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

	#SCHEDULEオブジェクト内で保持している日付の計算を行う。
	class DateCalculater
		def initialize(schedule,fromdate,todate,calendars)
			@schedule=schedule
			@fromdate=fromdate
			@todate=todate
			@calendars=calendars
			@logger=SingletonLogger.instance
		end

		#Scheduleオブジェクト内で定義されている日付を計算し、そのDate配列を返却する。
		#現在行っているのは、ON句で指定された日付セットとExcept句で指定された日付セットの差を返却しているのみ。
		#
		#FIXME 本当は休日カレンダー(デフォルトならばHOLIDAYS,FREEDAYS指定されていたらそのカレンダーを取り除く必要がある？教えて、偉い人。
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

		#カレンダーを示す文字列、リテラルを示す文字列などで表現された、
		#ScheduledDateを、オフセットを加味したフラットな日付オブジェクトに展開する。
		#その際に、@fromdate及び@todateを用いて日付の限界値を定める。('mo','everyday' 等、無限配列を示す指示子に対応するため)
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
				workdays=[] # 土日を除く毎日(ただし、FREEDAYS指定されている場合にはオプションに依存)
				if @schedule.freedays_cal
					_holiday=@calendars.find{|cal| cal.name==@schedule.freedays_cal }
					@logger.warn("#{self.class}"){"calendar [ #{@schedule.freedays_cal} ] was NOT found. ignored."} unless _holiday
					#土日を除く毎日を計算(FREEDAYSのオプションには依存)
					if opt=@schedule.freedays_opt
						opt=opt.collect{|s| s.upcase }
						filter=[0,6]
						filter.delete(6) if opt.include?('-SA') #土曜日は稼働日との指定の場合
						filter.delete(0) if opt.include?('-SU') #日曜日は稼働日との指定の場合
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
					#土日を除く毎日を計算
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
						#オフセットの適用
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

