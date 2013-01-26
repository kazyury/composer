
module Composer::TwsObj
	#= Resource
	#�g�p�\�ȃ��\�[�X��\������N���X�B
	#
	#�����Ƃ��Ĉȉ������B
	#- ���\�[�X���g�p����郏�[�N�X�e�[�V�������̓��[�N�X�e�[�V�����N���X��(wkstation)
	#- ���\�[�X�̖��O(name)
	#- �g�p�\�ȃ��\�[�X���j�b�g�̐�(units)
	#- ����(description)
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

		#�K�{�̃��[�N�X�e�[�V������,���\�[�X��,���\�[�X�P�ʂ��Z�b�g����Ă����true
		def set_enough?
			@wkstation && @name && @units
		end

		#���\�[�X�̏C����(wkstation#name)��ԋp����B
		#���\�[�X�����ݒ肳��Ă��Ȃ��ꍇ�ɂ́A_NO_ENTRY_ ��ԋp����B
		#�u���b�N�t���ŌĂ΂ꂽ�ꍇ�ɂ́A���̃u���b�N��]�������l��_NO_ENTRY_�̑���Ƃ��ėp������B
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
