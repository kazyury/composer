require 'win32ole'
require 'date'

module Composer::Face
	#Excel�̒萔���[�h�p
	module ExcelConst
	end
	#= StreamPlan
	#Schedule�y��Calendar�̉�͌��ʂɊ�Â��A�W���u�X�g���[���̔z�M�v���
	#Excel��ɕ\������B
	#
	#convert�����s����܂��ɁArange_set�ɂĕ\������͈͂��w�肷��K�v������B
	#
	#��.
	#  frontend.face='stream_plan'
	#  frontend.prepare(:range_set,'2006-01-01','2006-12-31')
	#  frontend.convert
	#
	#�ˑ��֌W
	#- Microsoft Excel���C���X�g�[������Ă���Windows�}�V���Ŏ��s����邱��
	#- Schedule��parse����Ă��邱��
	#- Calendar��parse����Ă��邱��
	#
	#���m�̖��
	#- Schedule��ON��,Except��ɂăJ�����_�[�̃I�t�Z�b�g�Ƃ��� {+|-} n WEEKDAYS ���� WORKDAYS ���g�p���Ă���ꍇ�̃I�t�Z�b�g�K�p��̓��t�v�Z��������
	#- Schedule��ON��,Except��ɂă��e����(�Ƃ������A�}�N���Ƃ������B'mo','tu'��)��WORKDAYS,FREEDAYS���g�p���Ă���ꍇ�̓��t�̌v�Z���s���m(����́AEVERYDAY���w�肵���ꍇ�Ɠ���)
	#
	#���ӓ_
	#- ThinkPad Z60t(1.6GHz,1GB)�Ŗ�7,000�W���u�X�g���[����1�N���̌v���\�������ꍇ�A��30������x�v�����B���̊ԁAExcel���N�����邱�Ƃ��o���Ȃ��̂Œ��ӂ��K�v�B
	#- ����̊m�F�́AMicrosoft Excel 2002(10.6823.6825) SP3�@/ Microsoft Windows XP Professional 5.1.2600 Service Pack 2 �r���h 2600 �ɂčs���Ă���B
	class StreamPlan
		include Composer::BaseMake

		#���������������{����B(Initialize����Ă΂��)
		#�e��C���X�^���X�ϐ��̐ݒ�ƁA�o�͐�t�@�C�����A�e���v���[�g�t�@�C������ݒ�
		def on_setup
			#�o�̓t�@�C���̃t���p�X���擾�B
			#WIN32OLE����AScripting.FileSystemObject�𓾂āA
			#GetAbsolutePathName��Windows��̃t���p�X���擾����B
			fso=WIN32OLE.new('Scripting.FileSystemObject')
			@outfile =fso.GetAbsolutePathName("#{@outfiles_dir}/stream_plan.xls")
			@template=fso.GetAbsolutePathName("#{@my_dir}/template.xlt")
			@fromdate=nil
			@todate=nil
			@months_to_create=[]
			@stream_planned_dates={}
			@visible=false
		end

		#Excel�̉�����ݒ肷��B(�f�t�H���g�͔��)
		#- true  : ��
		#- false : ���
		def visible=(bool)
			@visible=bool
		end

		#Excel��ɕ\��������t�͈͂��w�肷��B
		#From,To��������ȗ��\�B(�ȗ����ɂ́A���s���̓��t��p����)
		#From,To�͕�����Ŏw�肷��B(��.2006/02/18,1975-02-18)
		#
		#���̃��\�b�h�́AComposer#convert���s�O�Ɉ�x�͎��s����K�v������B
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

			#@months_to_create �̍\�z
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

		#StreamPlan�̍쐬���J�n����B
		#���ۂɂ́AFrontEnd�o�R(FrontEnd#convert)�Ŏ��s�����B
		#
		#�܂��A�����̏I������Excel���̂��̂�quit���邽�߁A�������̎��{����Excel�̑�����s���ׂ��ł͂Ȃ��B
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
			#�e�W���u�X�g���[����ON��AExcept��Ŏw�肳�ꂽ�J�����_�[�⃊�e������Date�I�u�W�F�N�g�ɓW�J���A
			#�W���u�X�g���[�����L�[�Ƃ���Hash�Ɋi�[����B
			schedules.each{|sched| 
				@logger.debug("#{self.class}"){"Expanding dates of stream [ #{sched.fullname} ]."}
				#�N���ʂ̓��t�I�u�W�F�N�g�n�b�V��
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
				#�e�V�[�g���̏������J�n����B
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

		#�I���������B
		#FrontEnd#convert����Ă΂��B
		#
		#���O�o�݂͂̂��s���B
		def on_exiting
			@logger.info("#{self.class}"){"creating stream plan ended."}
		end

		############ private #############

		#Excel�V�[�g���쐬����B
		def create_yyyymm_sheet(yyyymm)

			@logger.debug("#{self.class}"){"Copying template sheet to [ #{yyyymm} ] sheet."}
			#�e���v���[�g�V�[�g("yyyymm")�̑S�Z����I�����A�R�s�[�B
			#���̌�A�����Ŏ󂯎����yyyymm�V�[�g���쐬���A�e���v���[�g�V�[�g�̑S�Z�����y�[�X�g�B
			@book.worksheets('yyyymm').select
			@book.worksheets('yyyymm').range('A1:IV65536').select
			@xls.selection.copy

			current_sheet=@xls.worksheets.add # <= �V�[�g�̒ǉ�
			current_sheet.name=yyyymm
			current_sheet.paste
			current_sheet.range("A1").value+=yyyymm
			@logger.debug("#{self.class}"){"Copying template sheet to [ #{yyyymm} ] sheet completed."}

			#�w�b�_�ƂȂ���t�A�j���𖄂߂�B
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

			#�e�W���u�X�g���[���ɂ��čs�𖄂߂�B
			pos_y=4
			@sorted_schedule.each{|s|
				@logger.debug("#{self.class}"){"Filling plan for schedule [ #{s.fullname} ] ."}
				fill_stream_line(current_sheet,pos_y,s)
				pos_y+=1
			}
			
			#���`
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

		#1�W���u�X�g���[��(�̂����A1������Excel���1�s�Ŗ��߂�B
		def fill_stream_line(sheet,y,stream)
			#planned_date=@stream_planned_dates[stream].find_all{|a| a.year_and_month == sheet.name }.collect{|a| a.day }
			planned_date=@stream_planned_dates[stream][sheet.name].collect{|a| a.day }
			dates=(1..31).collect{|aday| planned_date.include?(aday) ? "Y" : "" }
			line_string = "#{stream.wkstation},#{stream.name},#{dates.join(',')}"
			sheet.range("B#{y}").value=line_string
		end
		private :fill_stream_line

		
		#Schedule�I�u�W�F�N�g���Œ�`����Ă�����t���v�Z���A����Date�z���ԋp����B
		#���ݍs���Ă���̂́AON��Ŏw�肳�ꂽ���t�Z�b�g��Except��Ŏw�肳�ꂽ���t�Z�b�g�̍���ԋp���Ă���̂݁B
		#
		#FIXME �{���͋x���J�����_�[(�f�t�H���g�Ȃ��HOLIDAYS,FREEDAYS�w�肳��Ă����炻�̃J�����_�[����菜���K�v������H�����āA�̂��l�B
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

		#�J�����_�[������������A���e����������������Ȃǂŕ\�����ꂽ�A
		#ScheduledDate���A�I�t�Z�b�g�����������t���b�g�ȓ��t�I�u�W�F�N�g�ɓW�J����B
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
				# FIXME ���݂�EVERYDAY�Ɠ������e�ɂȂ��Ă���B
				# �{����
				#
				# �ȉ��̂����ꂩ 1 ���\�ł��B
				#    * �x�Ɠ��J�����_�[���w�肵���ꍇ�A�A�Ɠ��� saturday �� sunday ������ everyday (freedays �L�[���[�h�ƈꏏ�� -sa �܂��� -su ���w�肵�Ă��Ȃ��ꍇ)�A����юw�肳�ꂽ�x�Ɠ��J�����_�[�̂��ׂĂ̓��t������ everyday �ł��B
				#    * �x�Ɠ��J�����_�[���w�肵�Ȃ������ꍇ�A�A�Ɠ��� saturday �� sunday ������ everyday�A����� holidays �J�����_�[�̂��ׂĂ̓��t������ everyday �ł��B
				#
				# �Ƃ̂��ƁB
				@fromdate.upto(@todate){|d| date_buffer.push d }
			when 'FREEDAYS'
				# FIXME ���݂�EVERYDAY�Ɠ������e�ɂȂ��Ă���B
				# �{����
				#
				#�x�Ɠ��J�����_�[�Ń}�[�N����Ă���� (�w�肳��Ă���ꍇ)�B
				#
				# �Ƃ̂��ƁB
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
						#�I�t�Z�b�g�̓K�p
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
