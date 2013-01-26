
module Composer::TwsObj
	#= Schedule
	#スケジュール(ジョブストリーム)を表現するクラス。
	#
	#属性として以下を持つ。
	#- SCHEDULE定義の直前に付与された行コメントの内容(comment)
	#- スケジュールの定義されたワークステーション名(wkstation)
	#- スケジュール名(name)
	#- FREEDAYSで指定された休業日カレンダー名(freedays_cal)
	#- FREEDAYSで指定するオプション(-sa,-su)の String 配列。(freedays_opt)
	#- ONで指定された実行日付の ScheduledDate 配列(on)
	#- DEADLINEで指定された時刻の ScheduledTime 配列(deadline)
	#- EXCEPTで指定された実行除外日付の  ScheduledDate 配列(except)
	#- ATで指定された開始時刻の ScheduledTime 配列(at)
	#- CARRYFORWARDが指定されているか否か(carryforward)
	#- 該当ジョブストリームが事前条件とするストリーム/ジョブの Follow 配列(follows)
	#- KEYSCHEDが指定されているか否か(keysched)
	#- LIMITで指定された同時実行ジョブ数(limit)
	#- 該当ジョブストリームが必要とするリソースの Resource 配列(needs)
	#- 該当ジョブストリームが必要とするファイルの DependFile 配列(opens)
	#- PRIORITYで指定された優先順位(priority)
	#- PROMPTSで指定されたプロンプトの String 配列(prompts)
	#- UNTILで指定された時刻の ScheduledTime 配列(until)
	#- ONUNTILで指定されたアクション(onuntil)
	#- 該当ストリームで実行されるジョブの ScheduledJob 配列(jobs)
	class Schedule
		extend ::Composer::SensitiveAttr

		def initialize
			@wkstation=nil
			@name=nil
			@freedays_cal=nil
			@freedays_opt=nil
			@description=nil
			@draft=nil
			@on=[]
			@deadline=[]
			@except=[]
			@at=[]
			@carryforward=nil
			@follows=[]
			@keysched=nil
			@limit=nil
			@needs=[]
			@opens=[]
			@priority=nil
			@prompts=[]
			@until=nil
			@onuntil=nil
			@jobs=[]
			@logger=::Composer::SingletonLogger.instance
			@comment=nil
		end
		sensitive_accessor :wkstation, :name, :freedays_cal, :carryforward, :keysched, :limit, :priority, :until, :onuntil, :comment
		attr_accessor :on, :deadline, :except, :at, :follows, :needs, :opens, :prompts, :jobs
		attr_accessor :description, :draft
		attr_reader :freedays_opt

		#スケジュール名が設定されている AND ,ON句,JOB句の双方とも少なくとも1件が存在する場合に真を返却。
		def set_enough?
			@name && (! @jobs.empty?) && (! @on.empty?)
		end

		#freedaysオプションを設定する。通常の用途ではこのメソッドを使用する必要は無い。 
		def freedays_opt=(val) #:nodoc:
			@freedays_opt=val.scan(/\-\w\w/) if val
		end

		#ScheduledDate系の属性を設定するwriter.通常の用途ではこのメソッドを使用する必要は無い。
		def append_dates(ivar,scheduled_dates,fdrule) #:nodoc:
			ivar=instance_variable_get("@#{ivar}")
			scheduled_dates.each{|sched_date|
				sched_date.fdrule=fdrule
				ivar.push sched_date
			}
		end

		#スケジュールの修飾名(wkstation#name)を返却する。
		#ジョブ名(又はリカバリージョブ名)が設定されていない場合には、_NO_ENTRY_ を返却する。
		#ブロック付きで呼ばれた場合には、そのブロックを評価した値が_NO_ENTRY_の代わりとして用いられる。
		def fullname()
			wk=@wkstation
			jo=@name
			if wk && jo
				return wk+'#'+jo
			elsif jo
				return jo
			else
				if block_given?
					val=yield
				else
					val='_NO_ENTRY_'
				end
				@logger.warn("#{self.class}"){"no name is specified. use [ #{val} ] instead."}
				return val
			end
		end

		#スケジュールの修飾名(wkstation#name)を返却する。
		#ジョブ名は付与しない。
		def shortname()
			wk=@wkstation
			jo=@name
			if wk && jo
				return wk+'#'+jo
      else
				return jo
      end
		end

		#carryforwardが指定されていたらtrue
		def carryforward?
			@carryforward ? true : false
		end

		#keyschedが指定されていたらtrue
		def keysched?
			@keysched ? true : false
		end
		alias :keyschedule? :keysched?

		#freedaysの文字列表現を返却。
		def freedays
			if @freedays_cal && @freedays_opt
				@freedays_cal +' '+ @freedays_opt.join(' ')
			elsif @freedays_cal
				@freedays_cal
			else
				''
			end
		end

	end

	#= ScheduledDate
	#スケジュール(ジョブストリーム)内で使用される、オフセット及び休業日時の取り扱いを含んだ日付を表現するクラス。
	#
	#属性として以下を持つ。
	#- 日付を示す文字列(mm/dd/yy),曜日等を示す文字列(tu等)、又はカレンダーの名前(value)
	#- オフセットの文字表現(offset)
	#- 休業日だった際の取り扱い(FDIGNORE,FDNEXT,FDPREV等) (fdrule)
	class ScheduledDate
		def initialize(value,offset,fdrule=nil)
			@value=value
			@offset=offset
			@fdrule=fdrule
		end
		attr_accessor :value, :offset, :fdrule

		#自身の文字列表現を返却する。
		def to_s
			ret=''
			ret << @value if @value
			ret << ' ' << @offset if @offset
			ret << ' ' << @fdrule if @fdrule
			ret
		end
	end

	#= ScheduledTime
	#スケジュール(ジョブストリーム)内で使用される、タイムゾーン及びオフセットの取り扱いを含んだ時刻を表現するクラス。
	#
	#属性として以下を持つ。
	#- 時刻(hhmm)を示す文字列。 (value)
	#- タイムゾーンを示す文字列。(timezone)
	#- オフセットの文字表現(offset)
	class ScheduledTime
		def initialize(value,timezone,offset)
			@value=value
			@timezone=timezone
			@offset=offset
		end
		attr_accessor :value, :timezone, :offset

		#自身の文字列表現を返却する。
		def to_s
			ret=''
			ret << @value if @value
			ret << ' TZ ' << @timezone if @timezone
			ret << ' ' << @offset if @offset
			ret
		end
	end


	#= Follow
	#スケジュール(ジョブストリーム)が依存する先行ジョブ(ジョブストリーム)を表現するクラス。
	#
	#属性として以下を持つ。
	#- ネットワーク・エージェントの名前。 (netagent)
	#- 先行ジョブの稼動するワークステーション名。(wkstation)
	#- 先行ジョブストリーム名(stream)
	#- 先行ジョブ名(job)
	class Follow
		def initialize(netagent,wkstation,stream,job)
			@netagent=netagent
			@wkstation=wkstation
			@stream=stream
			@job=job
		end
		attr_accessor :stream, :job, :wkstation, :netagent

		#自身の文字列表現を返却する。
		def to_s
			ret=''
			ret << @netagent << '::' if @netagent
			ret << @wkstation << '#' if @wkstation
			ret << @stream if @stream
			ret << '.' << @job if @job
			ret
		end

		#Followのストリーム修飾名(wkstation#stream)を返却する。
		#ジョブ名が設定されていない場合には、_NO_ENTRY_ を返却する。
		#ブロック付きで呼ばれた場合には、そのブロックを評価した値が_NO_ENTRY_の代わりとして用いられる。
		def fullname()
			wk=@wkstation
			jo=@stream
			if wk && jo
				return wk+'#'+jo
			elsif jo
				return jo
			else
				if block_given?
					val=yield
				else
					val='_NO_ENTRY_'
				end
				@logger.warn("#{self.class}"){"no name is specified. use [ #{val} ] instead."}
				return val
			end
		end
    
		#Followの修飾名(wkstation#name)を返却する。
		#ジョブ名は付与しない。
		def shortname()
			wk=@wkstation
			jo=@stream
			if wk && jo
				return wk+'#'+jo
      else
				return jo
      end
		end
	end

	#= DependFile
	#スケジュール(ジョブストリーム)の依存ファイルを表現するクラス。
	#
	#属性として以下を持つ。
	#- 依存ファイルの存在するワークステーション名。 (wkstation)
	#- 依存ファイルの存在するパス。(path)
	#- 依存ファイルのテスト条件(qualifier)
	class DependFile
		def initialize(wkstation,path,qualifier)
			@wkstation=wkstation
			@path=path
			@qualifier=qualifier
		end
		attr_accessor :wkstation, :path, :qualifier

		#自身の文字列表現を返却する。
		def to_s()
			ret=''
			ret << @wkstation << '#' if @wkstation
			ret << @path if @path
			ret << @qualifier if @qualifier
			ret
		end
	end

	#= ScheduledJob
	#ジョブストリーム内に定義されたジョブを表現するクラス。
	#
	#
	#基底クラスのComposer::Jobにて定義された属性に加えて以下の属性を持つ。
	#- ATで指定された開始時刻の ScheduledTime 配列(at)
	#- (confirmed)
	#- DEADLINEで指定された時刻の ScheduledTime 配列(deadline)
	#- (every)
	#- 該当ジョブが事前条件とするストリーム/ジョブの Follow 配列(follows)
	#- KEYJOBが指定されているか否か(keyjob)
	#- 該当ジョブが必要とするリソースの Resource 配列(needs)
	#- 該当ジョブが必要とするファイルの DependFile 配列(opens)
	#- PRIORITYで指定された優先順位(priority)
	#- (prompts)
	#- (until)
	class ScheduledJob < Job
		def initialize
			super
			@at=[]
			@confirmed=nil
			@deadline=[]
			@every=nil
			@follows=[]
			@keyjob=nil
			@needs=[]
			@opens=[]
			@priority=nil
			@prompts=[]
			@until=nil
			@onuntil=nil
		end
		attr_accessor :at, :confirmed, :deadline, :every, :follows, :keyjob, :needs, :opens, :priority, :prompts, :until, :onuntil 

		#KEYJOBが指定されている場合には真を返却。
		def keyjob?
			@keyjob ? true : false
		end

		#自身の文字列表現を返却する。
		def to_s()
			ret=super
			ret << ' AT ' << @at.collect{|a| a.to_s}.join(',') if @at
			ret << ' KEYJOB' if @keyjob
			ret << ' PRIORITY ' << @priority if @priority
			ret='"'+ret.gsub(/"/,'""')+'"' if @at.size > 1
			ret
		end
	end

end
