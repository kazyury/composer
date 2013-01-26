
module Composer::TwsObj
	#= Job
	#ジョブを表現するクラス。
	#
	#属性として以下を持つ。
	#- ワークステーション名(wkstation)
	#- ジョブ名(name)
	#- 説明(description)
	#- スクリプト名(scriptname) <- SCRIPTNAME で定義された内容
	#- コマンド名(docommand)    <- DOCOMMAND  で定義された内容
	#- 実行ユーザー(streamlogon)
	#- タスクタイプ(tasktype)
	#- 対話式か否か(interactive)
	#- ジョブが成功したと見なすために必要な戻りコードを判別する式(rccondsucc)
	#- リカバリーオプション(recovery)
	#- リカバリージョブのワークステーション(recovery_job_wkstation)
	#- リカバリージョブのジョブ名(recovery_job_name)
	#- リカバリー・プロンプト(abendprompt)
	class Job
		extend ::Composer::SensitiveAttr

		def initialize
			@wkstation=nil
			@name=nil
			@description=nil
			@scriptname=nil
			@docommand=nil
			@streamlogon=nil
			@interactive=nil
			@rccondsucc=nil
			@recovery=nil
			@recovery_job_wkstation=nil
			@recovery_job_name=nil
			@abendprompt=nil
			@tasktype=nil
			@logger=::Composer::SingletonLogger.instance
		end
		sensitive_accessor :wkstation,:name,:description,:scriptname,:docommand,:streamlogon,:interactive
		sensitive_accessor :rccondsucc,:recovery,:recovery_job_wkstation,:recovery_job_name,:abendprompt, :tasktype

		#必須のジョブ名,ジョブファイル名(またはジョブコマンド名),ジョブ実行ユーザー名がセットされていればtrue
		def set_enough?
			@name && ( @scriptname || @docommand ) && @streamlogon
		end

		#interactiveがONで定義されていたらtrue
		def interactive?
			return false unless @interactive
			@interactive.upcase=='ON' ? true : false
		end

		#ジョブの修飾名(wkstation#name)を返却する。
		#引数として非偽が設定されている場合には、リカバリージョブの修飾名を返却する。
		#ジョブ名(又はリカバリージョブ名)が設定されていない場合には、_NO_ENTRY_ を返却する。
		#ブロック付きで呼ばれた場合には、そのブロックを評価した値が_NO_ENTRY_の代わりとして用いられる。
		def fullname(rec_job=false)
			if rec_job
				wk=@recovery_job_wkstation
				jo=@recovery_job_name
			else
				wk=@wkstation
				jo=@name
			end
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


		#自身の文字列表現を返却する。
		def to_s
			ret=''
			ret << fullname if @name
			if @scriptname
				ret << ' SCRIPTNAME ' << @scriptname
			elsif @docommand
				ret << ' DOCOMMAND ' << @docommand
			end
			ret << ' STREAMLOGON ' << @streamlogon if @streamlogon
			ret
		end

	end
end

