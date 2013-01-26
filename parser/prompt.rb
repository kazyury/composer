
module Composer::TwsObj
class Prompt
	extend ::Composer::SensitiveAttr

	def initialize
		@name=nil
		@value=nil
		@logger=::Composer::SingletonLogger.instance
	end
	sensitive_accessor :name, :value

	# �v�����v�g�������'\n'+���s���L�q����Ă���ꍇ�ɂ́A'\n'����菜���ĉ��s�����ɂ���B
	def value=(val)
		@logger.warn("#{self.class}"){ "val[ #{@value} ] is overridden by [ #{val} ]."} if @value
		@value=val.gsub(/\\n\n/,"\n")
	end

	# �K�{�Ȃ̂̓v�����v�g���̂�
	def set_enough?
		@name
	end
end
end


