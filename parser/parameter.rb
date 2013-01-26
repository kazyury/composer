
module Composer::TwsObj
class Parameter
	extend ::Composer::SensitiveAttr

	def initialize
		@name=nil
		@value=nil
		@logger=::Composer::SingletonLogger.instance
	end
	sensitive_accessor :name, :value

	# �K�{�Ȃ̂̓p�����[�^���̂�
	def set_enough?
		@name
	end
end
end

