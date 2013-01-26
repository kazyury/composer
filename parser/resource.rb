
module Composer::TwsObj
	#= Resource
	#使用可能なリソースを表現するクラス。
	#
	#属性として以下を持つ。
	#- リソースが使用されるワークステーション又はワークステーションクラス名(wkstation)
	#- リソースの名前(name)
	#- 使用可能なリソースユニットの数(units)
	#- 説明(description)
	class Resource
		extend ::Composer::SensitiveAttr

		def initialize
			@wkstation=nil
			@name=nil
			@units=nil
			@description=nil
			@logger=::Composer::SingletonLogger.instance
		end
		sensitive_accessor :wkstation, :name, :units, :description

		#必須のワークステーション名,リソース名,リソース単位がセットされていればtrue
		def set_enough?
			@wkstation && @name && @units
		end

		#リソースの修飾名(wkstation#name)を返却する。
		#リソース名が設定されていない場合には、_NO_ENTRY_ を返却する。
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

	end
end
