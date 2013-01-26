require 'win32ole'
require 'date'

module Composer::Face
	#Excelの定数ロード用
	module ExcelConst
	end
	#= StreamPlan
	#Schedule及びCalendarの解析結果に基づき、ジョブストリームの配信計画を
	#Excel上に表現する。
	#
	#convertを実行するまえに、range_setにて表現する範囲を指定する必要がある。
	#
	#例.
	#  frontend.face='stream_plan'
	#  frontend.prepare(:range_set,'2006-01-01','2006-12-31')
	#  frontend.convert
	#
	#依存関係
	#- Microsoft ExcelがインストールされているWindowsマシンで実行されること
	#- Scheduleがparseされていること
	#- Calendarがparseされていること
	#
	#既知の問題
	#- ScheduleのON句,Except句にてカレンダーのオフセットとして {+|-} n WEEKDAYS 又は WORKDAYS を使用している場合のオフセット適用後の日付計算が未実装
	#- ScheduleのON句,Except句にてリテラル(というか、マクロというか。'mo','tu'等)でWORKDAYS,FREEDAYSを使用している場合の日付の計算が不正確(現状は、EVERYDAYを指定した場合と同等)
	#
	#注意点
	#- ThinkPad Z60t(1.6GHz,1GB)で約7,000ジョブストリームの1年分の計画を表現した場合、約30分弱程度要した。その間、Excelを起動することが出来ないので注意が必要。
	#- 動作の確認は、Microsoft Excel 2002(10.6823.6825) SP3　/ Microsoft Windows XP Professional 5.1.2600 Service Pack 2 ビルド 2600 にて行っている。
	class StreamPlan
		include Composer::BaseMake

		#初期化処理を実施する。(Initializeから呼ばれる)
		#各種インスタンス変数の設定と、出力先ファイル名、テンプレートファイル名を設定
		def on_setup
			#出力ファイルのフルパスを取得。
			#WIN32OLEから、Scripting.FileSystemObjectを得て、
			#GetAbsolutePathNameでWindows上のフルパスを取得する。
			fso=WIN32OLE.new('Scripting.FileSystemObject')
			@outfile =fso.GetAbsolutePathName("#{@outfiles_dir}/stream_plan.xls")
			@template=fso.GetAbsolutePathName("#{@my_dir}/template.xlt")
			@fromdate=nil
			@todate=nil
			@months_to_create=[]
			@stream_planned_dates={}
			@visible=false
		end

		#Excelの可視性を設定する。(デフォルトは非可視)
		#- true  : 可視
		#- false : 非可視
		def visible=(bool)
			@visible=bool
		end

		#Excel上に表現する日付範囲を指定する。
		#From,Toいずれも省略可能。(省略時には、実行時の日付を用いる)
		#From,Toは文字列で指定する。(例.2006/02/18,1975-02-18)
		#
		#このメソッドは、Composer#convert実行前に一度は実行する必要がある。
		def range_set(date_a=nil,date_b=nil)
			date_a ?  dateA=Date.parse(date_a,true) : dateA=Date.today
			date_b ?  dateB=Date.parse(date_b,true) : dateB=Date.today
			if dateA > dateB
				fromdate=dateB
				todate=dateA
			else
				fromdate=dateA
				todate=dateB
			end
			@fromdate=fromdate.first_day_of_month
			@todate=todate.last_day_of_month

			#@months_to_create の構築
			buff=@fromdate
			@months_to_create.push buff.year_and_month
			while true
				break if buff.year_and_month > @todate.year_and_month
				@months_to_create.push buff.year_and_month
				buff = buff >> 1
			end
			@months_to_create.uniq!
			@logger.debug("#{self.class}"){"Range set [ Fromdate:#{@fromdate.to_s}, Todate:#{@todate.to_s} ]"}
			@logger.debug("#{self.class}"){"Range set [ #{@months_to_create.join(' ')} ]"}
		end

		#StreamPlanの作成を開始する。
		#実際には、FrontEnd経由(FrontEnd#convert)で実行される。
		#
		#また、処理の終了時にExcelそのものをquitするため、当処理の実施中はExcelの操作を行うべきではない。
		def format
			if calendars.empty? || schedules.empty?
				@logger.error("#{self.class}"){"To use stream_plan, schedules and calendars must be set. "}
				return false
			end
			unless @fromdate && @todate
				@logger.error("#{self.class}"){"To convert, date range must be set. use composer#prepare(:range_set,fromdate,todate)"}
				return false
			end

			@logger.info("#{self.class}"){"Expanding dates of stream . this may take several time."}
			#各ジョブストリームのON句、Except句で指定されたカレンダーやリテラルをDateオブジェクトに展開し、
			#ジョブストリームをキーとしたHashに格納する。
			schedules.each{|sched| 
				@logger.debug("#{self.class}"){"Expanding dates of stream [ #{sched.fullname} ]."}
				#年月別の日付オブジェクトハッシュ
				partitioned_yyyymm={}
				@months_to_create.each{|yyyymm| partitioned_yyyymm[yyyymm]=[] }
				calcurated=calc_dates(sched)
				while aDate=calcurated.shift
					partitioned_yyyymm[aDate.year_and_month].push aDate
				end
				@stream_planned_dates[sched]=partitioned_yyyymm
			}

			@sorted_schedule=schedules.sort_by{|a| a.fullname }
			@size_of_stream=schedules.size

			@logger.warn("#{self.class}"){"writing to Microsoft Excel. -- DO NOT USE Excel -- until ends."}
			@xls=WIN32OLE.new('Excel.Application')
			WIN32OLE.const_load(@xls, ExcelConst)
			@xls.visible=@visible
			@xls.displayAlerts=false
			@book=@xls.workbooks.add(@template)

			begin
				#各シート毎の処理を開始する。
				@months_to_create.each{|yyyymm| 
					@logger.info("#{self.class}"){"Creating [ #{yyyymm} ] sheet data."}
					create_yyyymm_sheet(yyyymm) 
				}
				@logger.warn("#{self.class}"){"saving stream plan to [ #{@outfile} ]. "}
				@book.saveAs(@outfile)
			rescue Exception=>e
				@logger.error("#{self.class}"){"Exception [ #{e.class} ] raised while creating sheet data."}
				raise e
			ensure
				@book.close
				@xls.quit
			end
		end

		#終了時処理。
		#FrontEnd#convertから呼ばれる。
		#
		#ログ出力のみを行う。
		def on_exiting
			@logger.info("#{self.class}"){"creating stream plan ended."}
		end

		############ private #############

		#Excelシートを作成する。
		def create_yyyymm_sheet(yyyymm)

			@logger.debug("#{self.class}"){"Copying template sheet to [ #{yyyymm} ] sheet."}
			#テンプレートシート("yyyymm")の全セルを選択し、コピー。
			#その後、引数で受け取ったyyyymmシートを作成し、テンプレートシートの全セルをペースト。
			@book.worksheets('yyyymm').select
			@book.worksheets('yyyymm').range('A1:IV65536').select
			@xls.selection.copy

			current_sheet=@xls.worksheets.add # <= シートの追加
			current_sheet.name=yyyymm
			current_sheet.paste
			current_sheet.range("A1").value+=yyyymm
			@logger.debug("#{self.class}"){"Copying template sheet to [ #{yyyymm} ] sheet completed."}

			#ヘッダとなる日付、曜日を埋める。
			@logger.debug("#{self.class}"){"Filling date and wday to [ #{yyyymm} ] sheet."}
			pos_x='D'
			yyyy,mm=yyyymm.split('-').collect{|a| a.to_i}
			dd=1
			aDay=Date.new(yyyy,mm,dd)
			aDay.upto(aDay.last_day_of_month){|d|
				current_sheet.range("#{pos_x}2").value=d.day
				current_sheet.range("#{pos_x}3").value=Date::ABBR_DAYNAMES[d.wday]
				pos_x.succ!
			}
			@logger.debug("#{self.class}"){"Filling date and wday to [ #{yyyymm} ] sheet completed."}

			#各ジョブストリームについて行を埋める。
			pos_y=4
			@sorted_schedule.each{|s|
				@logger.debug("#{self.class}"){"Filling plan for schedule [ #{s.fullname} ] ."}
				fill_stream_line(current_sheet,pos_y,s)
				pos_y+=1
			}
			
			#整形
			last_row=4+@size_of_stream-1
			@logger.debug("#{self.class}"){"Formatting for [ #{yyyymm} ] ."}
			current_sheet.range("B4:B#{last_row}").TextToColumns({'DataType'=>ExcelConst::XlDelimited,'Comma'=>true})
			range=current_sheet.range("B4:AH#{last_row}")
			range.FormatConditions.add({'Type'=>ExcelConst::XlExpression,'Formula1'=>'=IF(A$3="Sat",TRUE,FALSE)'})
			range.FormatConditions(1).interior.colorIndex=34
			range.FormatConditions.add({'Type'=>ExcelConst::XlExpression,'Formula1'=>'=IF(A$3="Sun",TRUE,FALSE)'})
			range.FormatConditions(2).interior.colorIndex=40

			[ ExcelConst::XlEdgeTop, ExcelConst::XlEdgeLeft, ExcelConst::XlEdgeRight, ExcelConst::XlEdgeBottom ].each{|edge|
				border=range.borders(edge)
				border.linestyle=ExcelConst::XlContinuous
				border.weight=ExcelConst::XlMedium
			}
			border=current_sheet.range("B4:C#{last_row}").Borders(ExcelConst::XlEdgeRight)
			border.lineStyle=ExcelConst::XlContinuous
			border.weight=ExcelConst::XlMedium
			if @sorted_schedule.size > 2
				border=current_sheet.range("B4:AH#{last_row}").Borders(ExcelConst::XlInsideHorizontal)
				border.lineStyle=ExcelConst::XlDot
				border.weight=ExcelConst::XlThin
			end
		end
		private :create_yyyymm_sheet

		#1ジョブストリーム(のうち、1月分をExcel上の1行で埋める。
		def fill_stream_line(sheet,y,stream)
			#planned_date=@stream_planned_dates[stream].find_all{|a| a.year_and_month == sheet.name }.collect{|a| a.day }
			planned_date=@stream_planned_dates[stream][sheet.name].collect{|a| a.day }
			dates=(1..31).collect{|aday| planned_date.include?(aday) ? "Y" : "" }
			line_string = "#{stream.wkstation},#{stream.name},#{dates.join(',')}"
			sheet.range("B#{y}").value=line_string
		end
		private :fill_stream_line

		
		#Scheduleオブジェクト内で定義されている日付を計算し、そのDate配列を返却する。
		#現在行っているのは、ON句で指定された日付セットとExcept句で指定された日付セットの差を返却しているのみ。
		#
		#FIXME 本当は休日カレンダー(デフォルトならばHOLIDAYS,FREEDAYS指定されていたらそのカレンダーを取り除く必要がある？教えて、偉い人。
		def calc_dates(schedule)
			#on
			on_dates=[]
			schedule.on.each{|sched_date| on_dates.push expand_dates(sched_date)}
			on_dates.flatten!
			@logger.debug("#{self.class}"){"ON dates is [ #{on_dates.collect do |d| d.to_s end.join(' ')} ]"}

			#except
			except_dates=[]
			schedule.except.each{|sched_date| except_dates.push expand_dates(sched_date)}
			except_dates.flatten!
			@logger.debug("#{self.class}"){"Except dates is [ #{except_dates.collect do |d| d.to_s end.join(' ')} ]"}

			planned_dates=on_dates-except_dates
			@logger.debug("#{self.class}"){"Planned dates is [ #{planned_dates.collect do |d| d.to_s end.join(' ')} ]"}
			planned_dates
		end
		private :calc_dates

		#カレンダーを示す文字列、リテラルを示す文字列などで表現された、
		#ScheduledDateを、オフセットを加味したフラットな日付オブジェクトに展開する。
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
				@fromdate.upto(@todate){|d| date_buffer.push d unless d.wday==6 || d.wdays==0 }
			when 'EVERYDAY'
				@fromdate.upto(@todate){|d| date_buffer.push d }
			when 'WORKDAYS'
				# FIXME 現在はEVERYDAYと同じ内容になっている。
				# 本来は
				#
				# 以下のいずれか 1 つが可能です。
				#    * 休業日カレンダーを指定した場合、就業日は saturday と sunday を除く everyday (freedays キーワードと一緒に -sa または -su を指定していない場合)、および指定された休業日カレンダーのすべての日付を除く everyday です。
				#    * 休業日カレンダーを指定しなかった場合、就業日は saturday と sunday を除く everyday、および holidays カレンダーのすべての日付を除く everyday です。
				#
				# とのこと。
				@fromdate.upto(@todate){|d| date_buffer.push d }
			when 'FREEDAYS'
				# FIXME 現在はEVERYDAYと同じ内容になっている。
				# 本来は
				#
				#休業日カレンダーでマークされている日 (指定されている場合)。
				#
				# とのこと。
				@fromdate.upto(@todate){|d| date_buffer.push d }
			when 'REQUEST'
				# do nothing;
			else
				# may be calendar.
				@logger.debug("#{self.class}"){"[ #{value} ] may be calendar."}
				calendar=calendars.find{|cal| cal.name.upcase == value }
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
						when /\AWEEK/
							# FIXME Not Implemented
						when /\AWORK/
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
