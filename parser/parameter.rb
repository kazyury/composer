
module Composer::TwsObj
class Parameter
	extend ::Composer::SensitiveAttr

	def initialize
		@name=nil
		@value=nil
		@logger=::Composer::SingletonLogger.instance
	end
	sensitive_accessor :name, :value

	# 必須なのはパラメータ名のみ
	def set_enough?
		@name
	end
end
end

