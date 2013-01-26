require 'date'

module Composer::TwsObj
	#= Calendar
	#スケジューリングカレンダーを表現するクラス。
	#
	#属性としてカレンダー名(@name),説明(@description)を持つ。
	#mm/dd/yy形式の日付(@date)への直接のアクセス手段は無く、@dateformatが未定義(nil)の場合に
	#Calendar#datesメソッドにて取得できる。
	#@dateformatに妥当なフォーマット文字列(Date#strftime,strftime(3),strptimeを参照)が指定されている
	#場合には、Calendar#datesメソッドはその書式でフォーマットした文字列の配列(日付の古い順にソート)
	#を返却する。
	class Calendar
		extend ::Composer::SensitiveAttr

		def initialize
			@name=nil
			@description=nil
			@date=[]
			@date_internal=[]
			@dateformat=nil
			@logger=::Composer::SingletonLogger.instance
		end
		sensitive_writer :name, :description
		attr_reader :name,:description, :date, :date_internal
		attr_accessor :dateformat

		#@dateへのアクセサ(reader)。
		#Calendar#dateformat='format-string' でdateformatを定義している場合には、
		#その書式を適用した日付を古い順にソートした配列で返却。
		# as of 03/27/2007
    #- %A: 曜日の名称(Sunday, Monday ... )
    #- %a: 曜日の省略名(Sun, Mon ... )
    #- %B: 月の名称(January, February ... )
    #- %b: 月の省略名(Jan, Feb ... )
    #- %c: 日付と時刻
    #- %d: 日(01-31)
    #- %H: 24時間制の時(00-23)
    #- %I: 12時間制の時(01-12)
    #- %j: 年中の通算日(001-366)
    #- %M: 分(00-59)
    #- %m: 月を表す数字(01-12)
    #- %p: 午前または午後(AM,PM)
    #- %S: 秒(00-60) (60はうるう秒)
    #- %U: 週を表す数。最初の日曜日が第1週の始まり(00-53)
    #- %W: 週を表す数。最初の月曜日が第1週の始まり(00-53)
    #- %w: 曜日を表す数。日曜日が0(0-6)
    #- %X: 時刻
    #- %x: 日付
    #- %Y: 西暦を表す数
    #- %y: 西暦の下2桁(00-99)
    #- %Z: タイムゾーン trap
    #- %%: %自身
		#
		#ブロックとともに使用した場合には、各日付(Dateオブジェクト)をyieldする。
		def dates
			if block_given?
				@date_internal.each{|d| yield d }
			else
				if @dateformat
					return @date_internal.collect{|d| d.strftime(@dateformat) }
				else
					return @date
				end
			end
		end

		#@dateへのアクセサ。
		#通常の用途(Faceクラスの開発、Composerファイルの表現形式変更)では使用する必要が無い。
		def append_date(mmddyy)
			@date.push mmddyy
			if /(\d\d)\/(\d\d)\/(\d\d)/=~mmddyy
				@date_internal.push Date.parse(mmddyy,true)
				@date_internal.sort!
			else
				@logger.warn("#{self.class}"){ "defined date [ #{mmddyy} } may not be parsed correctly." }
			end
		end

		#必須のカレンダー名,日付がセットされていればtrueを返却
		def set_enough?
			@name && (! @date.empty?)
		end
	end
end
