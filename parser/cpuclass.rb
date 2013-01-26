
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

		#必須のワークステーションクラス名と、少なくとも1件のmembersがいるか?
		def set_enough?
			@cpuclass && (! @members.empty? )
		end
	end
end

