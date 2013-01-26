require 'erb'

module Composer::Face
	#= Jobnet
	#��͂����W���u�X�g���[����FOLLOWS�����ɁA�W���u�X�g���[���Ԃ̈ˑ��֌W��Jobnet�}�Ƃ��Ď��o������B
	#���o������ۂɂ�graphviz���C���X�g�[������Ă��邱�Ƃ��O��ƂȂ�B
	#
	#=== graphviz�����T�C�g(http://www.graphviz.org/)
	#graphviz��CPL(Common Public License)�ɏ]���Ĕz�z����Ă���B
	#���o�[�W�����ł̉ғ��m�F���́A
	# dot - Graphviz version 2.12 (Mon Dec  4 22:04:37 UTC 2006)
	#
	#��Face�ł͈ȉ��̐ݒ肪�\�B
	#- �f�t�H���g�̏o�͌`����svg�ł��邪�Aoutformat=(str) ���\�b�h�ɂďo�͌`�����w�肷�邱�Ƃ��\�B
	#  �I���\�ȏo�͌`����graphviz�̎d�l�ɏ]���B(��. jpg, gif, ps ���X)
	#- �o�͑Ώۂ̃W���u�X�g���[�����A���[�N�X�e�[�V�������A�X�g���[�����ɂăt�B���^�����O���邱�Ƃ��\�B
	#  (wkstation_filter=(str),stream_filter=(str))
	#- SCHEDULE�ɂ�ON��Ƃ���REQUEST�݂̂���`����Ă���X�g���[�����o�͑ΏۂƂ��邩�ۂ��B
	#  (draw_only_request=(bool) true:�o�͂���Bfalse:�o�͂��Ȃ��B)
	#
	#== ��.
	#  frontend.face='jobnet'                               #=> face�Ƃ���Jobnet���g�p�B
	#  frontend.prepare(:outformat=,'jpg')                  #=> �o�̓t�@�C���t�H�[�}�b�g��JPG(�f�t�H���g��svg)
	#  frontend.prepare(:wkstation_filter=,'RV00000')       #=> ���[�N�X�e�[�V��������RV00000����n�܂���݂̂̂��o��(�f�t�H���g�͑S��)
	#  frontend.prepare(:stream_filter=,'STR_(A|B|C)\w')    #=> �X�g���[������STR_����n�܂�A���̌�A����B����C�@�������A���̌�̕������p�����ł������(�f�t�H���g�͑S��)
	#  frontend.prepare(:draw_only_request=,true)           #=> ON�傪REQUEST�݂̂̃X�g���[�����o�͂���(�������A�j���ŏo��)�B(�f�t�H���g�͏o�͂��Ȃ�)
	#  frontend.convert                                     #=> outfiles/jobnet.dot �y�сA outfiles/jobnet.svg ���o�͂����B
	#
	#== �`����e
	#- �W���u�X�g���[���́A�l�p�`�ɂĕ\������B
	#- �W���u�X�g���[���ԂɈˑ��֌W������ꍇ�ɂ́A��s�W���u�X�g���[������A��s�W���u�X�g���[���Ɍ��������ŕ\������B
	#- �W���u�X�g���[����\������l�p�`�����ɂ́A��{�I�ɂ́@"�X�g���[����(���s)@���[�N�X�e�[�V������"�@���o�͂���B
	#  �������A���[�N�X�e�[�V���������̓X�g���[�����Ő�s�W���u�X�g���[�����t�B���^�����O����Ă���ꍇ�A���̐�s�W���u�X�g���[���� "���[�N�X�e�[�V������#�X�g���[����"�ŕ\������B
	#- AT��AUNTIL��ADEADLINE�傪�w�肳�ꂽ�W���u�X�g���[���ɂ́A���ꂼ�� a HHMM u HHMM d HHMM �����̖��̂ɒǉ��ŏo�͂���B
	#- ON�傪REQUEST�݂̂̃W���u�X�g���[���͔j���ŕ\������B(draw_only_request=true�̏ꍇ�̂�)
	#
	#== �ˑ��֌W
	#- graphviz���C���X�g�[������Ă���}�V����Ŏ��s���邱�ƁB(graphviz���C���X�g�[������Ă��Ȃ��ꍇ�Adot�t�@�C���݂̂�outfiles�f�B���N�g���ɏo��)
	#- Schedule��parse����Ă��邱��
	#
	#== ���ӓ_
	#��ʂ̃X�g���[��(��7,000�X�g���[��)���摜�t�@�C��������ۂɂ́A���ɑ�ʂ̃�����(1G�̃������ł��s�������B)��v�����邽�߁A
	#�f�t�H���g�̏o�͌`�����r�I�����ȃ����������v�����Ȃ�svg�`���Ƃ��Ă���B
	#�������A�g�p���Ă���SVG viewer�ɂ���Ă͑傫��svg�t�@�C�����Q�Ƃł��Ȃ��ꍇ������̂Œ��ӁB
	#
	#( �Q�l- SVG viewer )
	#- Inkscape ( �����T�C�g http://www.inkscape.org/ ) : �X�^���h�A������SVG Viewer
	#- Adobe SVG Viewer ( �����T�C�g http://www.adobe.com/jp/svg/ ) : Web�u���E�U(IE)��plugin
	#- Mozilla Firefox ( �����T�C�g http://www.mozilla.com/en-US/ ) : Web�u���E�U
	class Jobnet
		include Composer::BaseMake

		def on_setup
			@outformat="svg"
			@wkstation_filter=nil
			@stream_filter=nil
			@draw_only_request=false
			@f_schedules=nil
		end
		#�f�t�H���g��"svg"�B�o�̓t�@�C���t�H�[�}�b�g�������������ݒ肷��B
		attr_accessor :outformat
		#�f�t�H���g��nil�B���炩�̕�����ݒ肵���ꍇ�A���[�N�X�e�[�V�������̐擪����w�肳�ꂽ����(�𐳋K�\���Ƃ��Ă�����)�Ƀ}�b�`����X�g���[���݂̂��o�͑ΏۂƂ���B
		attr_accessor :wkstation_filter
		#�f�t�H���g��nil�B���炩�̕�����ݒ肵���ꍇ�A�X�g���[�����̐擪����w�肳�ꂽ����(�𐳋K�\���Ƃ��Ă�����)�Ƀ}�b�`����X�g���[���݂̂��o�͑ΏۂƂ���B
		attr_accessor :stream_filter
		#�f�t�H���g��false�Btrue��ݒ肵���ꍇ�ɂ́AREQUEST����ON��Ɏw�肳��Ă��Ȃ��X�g���[�����o�͑ΏۂƂ���B
		attr_accessor :draw_only_request

		def format #:nodoc:
			@logger.info("#{self.class}"){"Formatting with [ #{self.class} ]."}

			contents=File.read("#{@my_dir}/jobnet.erb")
			File.open("#{@outfiles_dir}/jobnet.dot","w"){|f| f.puts ERB.new(contents,0,"-").result(binding) }

			@logger.info("#{self.class}"){"[ #{@outfiles_dir}/jobnet.dot ] file was out. "}
		end

		def def_dot_node()
			@logger.info("#{self.class}"){"writing streams. "}
			@f_schedules=schedules
			if @wkstation_filter
				@logger.debug("#{self.class}"){"wkstation_filter is set. filtering with [ #{@wkstation_filter} ]."}
				@f_schedules=@f_schedules.find_all{|s| /\A#{@wkstation_filter}/=~s.wkstation }
			end
			if @stream_filter
				@logger.debug("#{self.class}"){"stream_filter is set. filtering with [ #{@stream_filter} ]."}
				@f_schedules=@f_schedules.find_all{|s| /\A#{@stream_filter}/=~s.name }
			end
			unless @draw_only_request
				@logger.debug("#{self.class}"){"DO NOT draw 'REQUEST' only stream. draw_only_request is [ #{@draw_only_request} ]. "}
				@f_schedules=@f_schedules.reject{|s| s.on.size==1 && s.on.first.value.upcase=='REQUEST' } 
			end
			@f_schedules.collect{|s|
				streamname='"'+s.fullname+'" '
				streamname << "[ label=\"#{s.name}\\n@#{s.wkstation} "
				streamname << "a #{s.at.join(",")}" unless s.at.empty?
				streamname << "u #{s.until.join(",")}" if s.until
				streamname << "d #{s.deadline.join(",")}" unless s.deadline.empty?
				streamname << '"'
				streamname << ' style=dashed' if s.on.size==1 && s.on.first.value.upcase=='REQUEST'
				streamname << '];'
				streamname
			}.join("\n")
		end
		private :def_dot_node

		def def_dot_edge()
			@logger.info("#{self.class}"){"writing dependency arrows. "}
			@f_schedules.collect{|s|
				myself='"'+s.fullname+'"'
				s.follows.collect{|f| '"'+f.fullname+'" -> '+myself+';'}.join("\n")
			}.join("\n")
		end
		private :def_dot_edge

		def on_exiting
			@logger.info("#{self.class}"){"converting .dot files into [ .#{@outformat} ] file. "}
			system("dot -T#{@outformat} #{@outfiles_dir}/jobnet.dot -o #{@outfiles_dir}/jobnet.#{@outformat}")
			if $?==0
				@logger.info("#{self.class}"){"converting .dot files into [ .#{@outformat} ] file. SUCCESS."}
			else
				@logger.error("#{self.class}"){"may not installed graphviz ? converting to #{@outformat} was failed. "}
			end
		end
	end
end

	
