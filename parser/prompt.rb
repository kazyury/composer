
module Composer::TwsObj
class Prompt
	extend ::Composer::SensitiveAttr

	def initialize
		@name=nil
		@value=nil
		@logger=::Composer::SingletonLogger.instance
	end
	sensitive_accessor :name, :value

	# プロンプト文字列に'\n'+改行が記述されている場合には、'\n'を取り除いて改行だけにする。
	def value=(val)
		@logger.warn("#{self.class}"){ "val[ #{@value} ] is overridden by [ #{val} ]."} if @value
		@value=val.gsub(/\\n\n/,"\n")
	end

	# 必須なのはプロンプト名のみ
	def set_enough?
		@name
	end
end
end


