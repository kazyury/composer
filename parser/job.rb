
module Composer::TwsObj
	#= Job
	#�W���u��\������N���X�B
	#
	#�����Ƃ��Ĉȉ������B
	#- ���[�N�X�e�[�V������(wkstation)
	#- �W���u��(name)
	#- ����(description)
	#- �X�N���v�g��(scriptname) <- SCRIPTNAME �Œ�`���ꂽ���e
	#- �R�}���h��(docommand)    <- DOCOMMAND  �Œ�`���ꂽ���e
	#- ���s���[�U�[(streamlogon)
	#- �^�X�N�^�C�v(tasktype)
	#- �Θb�����ۂ�(interactive)
	#- �W���u�����������ƌ��Ȃ����߂ɕK�v�Ȗ߂�R�[�h�𔻕ʂ��鎮(rccondsucc)
	#- ���J�o���[�I�v�V����(recovery)
	#- ���J�o���[�W���u�̃��[�N�X�e�[�V����(recovery_job_wkstation)
	#- ���J�o���[�W���u�̃W���u��(recovery_job_name)
	#- ���J�o���[�E�v�����v�g(abendprompt)
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

		#�K�{�̃W���u��,�W���u�t�@�C����(�܂��̓W���u�R�}���h��),�W���u���s���[�U�[�����Z�b�g����Ă����true
		def set_enough?
			@name && ( @scriptname || @docommand ) && @streamlogon
		end

		#interactive��ON�Œ�`����Ă�����true
		def interactive?
			return false unless @interactive
			@interactive.upcase=='ON' ? true : false
		end

		#�W���u�̏C����(wkstation#name)��ԋp����B
		#�����Ƃ��Ĕ�U���ݒ肳��Ă���ꍇ�ɂ́A���J�o���[�W���u�̏C������ԋp����B
		#�W���u��(���̓��J�o���[�W���u��)���ݒ肳��Ă��Ȃ��ꍇ�ɂ́A_NO_ENTRY_ ��ԋp����B
		#�u���b�N�t���ŌĂ΂ꂽ�ꍇ�ɂ́A���̃u���b�N��]�������l��_NO_ENTRY_�̑���Ƃ��ėp������B
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


		#���g�̕�����\����ԋp����B
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

