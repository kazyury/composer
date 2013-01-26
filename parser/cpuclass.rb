
module Composer::TwsObj
	#- CpuClass
	class CpuClass
		extend ::Composer::SensitiveAttr

		def initialize
			@cpuclass=nil
			@members=[]
			@logger=::Composer::SingletonLogger.instance
		end
		sensitive_accessor :cpuclass
		attr_accessor :members

		#�K�{�̃��[�N�X�e�[�V�����N���X���ƁA���Ȃ��Ƃ�1����members�����邩?
		def set_enough?
			@cpuclass && (! @members.empty? )
		end
	end
end

