
module Composer::TwsObj
	#= Domain
	#�h���C����\������N���X�B
	#
	#�����Ƃ��Ĉȉ������B
	#- �h���C����(name)
	#- ����(description)
	#- �h���C���}�l�[�W����(manager)
	#- �e�h���C���̖���(parent)
	class Domain
		extend ::Composer::SensitiveAttr

		def initialize
			@name=nil
			@description=nil
			@manager=nil
			@parent=nil
			@logger=::Composer::SingletonLogger.instance
		end
		sensitive_accessor :name, :description, :manager, :parent

		#�K�{�̃h���C�����A�h���C���}�l�[�W�������ݒ肳��Ă��邩?
		def set_enough?
			@name && @manager
		end
	end
end
