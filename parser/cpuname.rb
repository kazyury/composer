
module Composer::TwsObj
	#= CpuName
	#�P��̃��[�N�X�e�[�V������\������N���X�B
	#
	#�����Ƃ��Ĉȉ������B
	#- ���[�N�X�e�[�V������(name)
	#- ����(description)
	#- OS�̃^�C�v(os)
	#- �z�X�g������IP�A�h���X(node)
	#- �X�P�W���[���[�����[�N�X�e�[�V������ł̒ʐM�Ɏg�p����TCP�|�[�g�ԍ�(tcpaddr)
	#- ���MSSL�ڑ���listen����̂Ɏg�p�����|�[�g(secureaddr)
	#- ���[�N�X�e�[�V�����̎��ԑ�(timezone)
	#- ���[�N�X�e�[�V�����̃X�P�W���[���[�E�h���C����(domain)
	#- �G�[�W�F���g�̃z�X�g�E���[�N�X�e�[�V�����̖��O(host)
	#- �g���G�[�W�F���g�ƃl�b�g���[�N�E�G�[�W�F���g�̃A�N�Z�X����(access)
	#- ���[�N�X�e�[�V�����̃^�C�v(type)
	#- ���[�N�X�e�[�V������`�𖳎����邩�ۂ�(ignore)
	#- �n�����Ƀ��[�N�X�e�[�V�����Ԃ̃����N���J�����ǂ���(autolink)
	#- ���[�N�X�e�[�V�����ƃ}�X�^�[�E�h���C���E�}�l�[�W���[�Ƃ̊ԂɃt�@�C�A�E�H�[�������݂��邩�ۂ�(behindfirewall)
	#- �G�[�W�F���g�����S�󋵂܂��͕����󋵂̂ǂ���ōX�V����邩(fullstatus)
	#- ���[�N�X�e�[�V������ SSL �F�؂̃^�C�v(securitylevel)
	#- �G�[�W�F���g�����ׂĂ̈ˑ��֌W��ǐՂ���̂��ۂ�(resolvedep)
	#- �G�[�W�F���g�Ƃ̒ʐM���������߂́A�h���C���E�}�l�[�W���[��Mailman�T�[�o�[ID(server)
	class CpuName
		extend ::Composer::SensitiveAttr

		def initialize
			@name=nil
			@description=nil
			@os=nil
			@node=nil
			@tcpaddr=nil
			@secureaddr=nil
			@timezone=nil
			@domain=nil
			@host=nil
			@access=nil
			@type=nil
			@ignore=nil
			@autolink=nil
			@behindfirewall=nil
			@fullstatus=nil
			@resolvedep=nil
			@server=nil
			@securitylevel=nil
			@logger=::Composer::SingletonLogger.instance
		end
		sensitive_accessor :secureaddr, :name, :description, :os, :node, :tcpaddr, :timezone, :domain, :host, :access, :type, :ignore, :autolink, :fullstatus, :resolvedep, :server, :behindfirewall, :securitylevel

		#ignore���w�肳��Ă�����true
		def ignore?
			@ignore ? true : false
		end

		# autolink��ON�Œ�`����Ă�����true
		def autolink?
			return false unless @autolink
			@autolink.upcase=='ON' ? true : false
		end

		# behindfirewall��ON�Œ�`����Ă�����true
		def behindfirewall?
			return false unless @behindfirewall
			@behindfirewall.upcase=='ON' ? true : false
		end

		# fullstatus��ON�Œ�`����Ă�����true
		def fullstatus?
			return false unless @fullstatus
			@fullstatus.upcase=='ON' ? true : false
		end

		# resolvedep��ON�Œ�`����Ă�����true
		def resolvedep?
			return false unless @resolvedep
			@resolvedep.upcase=='ON' ? true : false
		end

		#�K�{�̃��[�N�X�e�[�V�������AOS�^�C�v�A�z�X�g�����ݒ肳��Ă��邩?
		def set_enough?
			@name && @os && @node
		end
	end
end

