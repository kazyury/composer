require 'erb'

module Composer::Face
	#= Subnet
  #
  #Jobnet��A�������O���t�ɕ������A���ꂼ��̃O���t���Ƃ̃W���u�l�b�g���o�͂���B
  #�v����ɁA�ˑ��֌W�̂���W���u�l�b�g���ɕ�������B
	#
	#��Face�ł͈ȉ��̐ݒ肪�\�B
	#- �f�t�H���g�̏o�͌`����svg�ł��邪�Aoutformat=(str) ���\�b�h�ɂďo�͌`�����w�肷�邱�Ƃ��\�B
	#  �I���\�ȏo�͌`����graphviz�̎d�l�ɏ]���B(��. jpg, gif, ps ���X)
	#
	#== ��.
	#  frontend.face='jobnet'                               #=> face�Ƃ���Jobnet���g�p�B
	#  frontend.prepare(:outformat=,'jpg')                  #=> �o�̓t�@�C���t�H�[�}�b�g��JPG(�f�t�H���g��svg)
	#  frontend.convert                                     #=> outfiles/jobnet.dot �y�сA outfiles/jobnet.svg ���o�͂����B
	#
	#== �`����e
	#- �W���u�X�g���[���́A�l�p�`�ɂĕ\������B
	#- �W���u�X�g���[���ԂɈˑ��֌W������ꍇ�ɂ́A��s�W���u�X�g���[������A��s�W���u�X�g���[���Ɍ��������ŕ\������B
	#- �W���u�X�g���[����\������l�p�`�����ɂ́A��{�I�ɂ́@"�X�g���[����(���s)@���[�N�X�e�[�V������"�@���o�͂���B
	#  �������A���[�N�X�e�[�V���������̓X�g���[�����Ő�s�W���u�X�g���[�����t�B���^�����O����Ă���ꍇ�A���̐�s�W���u�X�g���[���� "���[�N�X�e�[�V������#�X�g���[����"�ŕ\������B
	#- AT��AUNTIL��ADEADLINE�傪�w�肳�ꂽ�W���u�X�g���[���ɂ́A���ꂼ�� a HHMM u HHMM d HHMM �����̖��̂ɒǉ��ŏo�͂���B
	#- ON�傪REQUEST�݂̂̃W���u�X�g���[���͔j���ŕ\������B
	#
	#== ���̑�
	#���̑��̗��ӎ����ɂ��ẮA Jobnet �ɏ����܂��B
	class Subnet
		include Composer::BaseMake

		def on_setup
			@outformat="svg"
			@source_buffer=nil
			@f_schedules=nil
		end
		#�f�t�H���g��"svg"�B�o�̓t�@�C���t�H�[�}�b�g�������������ݒ肷��B
		attr_accessor :outformat

		def format #:nodoc:
			@logger.info(self.class){"Formatting with [ #{self.class} ]."}
      @source=schedules.dup
      @subgraphs=[]
      divide_schedules
      convert
		end

    def convert
      contents=File.read("#{@my_dir}/subnet.erb")
      # Islands�����͓��ʈ���
      @sub=@subgraphs.pop
      dotfile="#{@outfiles_dir}/subnet_islands.dot"
      outfile="#{@outfiles_dir}/subnet_islands.#{@outformat}"
      File.open(dotfile,"w"){|f| f.puts ERB.new(contents,0,"-").result(binding) }
      @logger.debug(self.class){"[ #{dotfile} ] file was out. "}
      system("dot -T#{@outformat} #{dotfile} -o #{outfile}")
      unless $?==0
        @logger.error(self.class){"may not installed graphviz ? converting to #{@outformat} was failed. "}
      end

      idx=1
      @subgraphs.each_with_index do |sub,idx|
        @sub=sub
        dotfile="#{@outfiles_dir}/subnet#{idx}.dot"
        outfile="#{@outfiles_dir}/subnet#{idx}.#{@outformat}"
        File.open(dotfile,"w"){|f| f.puts ERB.new(contents,0,"-").result(binding) }
        @logger.debug(self.class){"[ #{dotfile} ] file was out. "}
        system("dot -T#{@outformat} #{dotfile} -o #{outfile}")
        unless $?==0
          @logger.error(self.class){"may not installed graphviz ? converting to #{@outformat} was failed. "}
        end
      end
      @logger.info(self.class){"converted #{idx+1} files into [ .#{@outformat} ] format. SUCCESS."}
    end

    # ��͍ς݂�schedules��A�������O���t�ɕ�������B
    # �ŏ���1����schedules�̐擪��p���邪�A�[���D��T�����s���S�Ă̓���H��B
    # �܂��A1�m�[�h�݂̂̕����O���t�B�́A�ЂƂ̃O���t��(Islands)�ɕ\������B
    def divide_schedules
      islands=[]
      idx=0
			@logger.info(self.class){"Start spliting graph to subgraphs"}
      until @source.empty?
        idx+=1
        @logger.debug(self.class){"graph_search ##{idx} start."}
        subgraph=graph_search([], nil)
        if subgraph.size==1
          islands.push subgraph.first
          @logger.debug(self.class){"graph_search ##{idx} end. This graph will be shown in Islands."}
        else
          @subgraphs.push subgraph
          @logger.debug(self.class){"graph_search ##{idx} end. #{subgraph.size} node in this graph."}
        end
      end
      @subgraphs.push islands
			@logger.info(self.class){"Graph was split to #{@subgraphs.size} subgraphs"}
    end

    # �[���D��T���ɂĘA�������O���t�\���m�[�h�𑖍�����B
    # �܂�A�������g��follows �ɓo�^����Ă���W���u�X�g���[���A�������g��follow���Ă���W���u�X�g���[�����ċA�I�ɒH��B
    # - ����!!! buffer �ɂ��A@source �ɂ�TwsObj::Schedule���i�[����Ă���B
    def graph_search(buffer,sched)

			@logger.debug(self.class){"graph_search with [#{buffer.join(',')}], #{sched}"}
      if sched 
        # ����Ă���Ώۂ��w�肳��Ă���΁A@source���T���āA�擾����B
        # �����ł���sched�́A���ۂɂ�Composer::TwsObj::Follow�Ȃ̂ŁATwsObj::Schedule�ɕϊ�����B
        temp=@source.find{|x| x.shortname == sched.shortname}
        unless temp
          @logger.warn(self.class){"#{sched.shortname} was not found.Ignored."}
          return buffer
        end
        sched=temp
      else # ����Ă���Ώۂ��w�肳��Ă��Ȃ���΁A�C�ӂ�1JS���擾����B
        sched=@source.shift
      end
      buffer.push sched
      @source.delete(sched)
			@logger.debug(self.class){"processing #{sched.shortname}"}

      # JS��follow���Ă�����̂�����A����buffer�ɓ����Ă��Ȃ��ꍇ�ɂ́A����follow���Ă�����̂ɂ��čċA�I�Ɏ擾
      if has_follows?(sched)
        has_follows(sched).each do |n|
          @logger.debug(self.class){"#{sched.shortname} follows #{n.shortname}"}
          buffer=graph_search(buffer,n) unless buffer.collect{|x| x.shortname}.include?(n.shortname)
        end
      end
      # ����JS��follow���Ă�����̂�����A����buffer�ɓ����Ă��Ȃ��ꍇ�ɂ́A����follow���Ă�����̂ɂ��čċA�I�Ɏ擾
      if is_followed?(sched)
        is_followed(sched).each do |n|
          @logger.debug(self.class){"#{sched.shortname} is followed by #{n.shortname}"}
          buffer=graph_search(buffer,n) unless buffer.collect{|x| x.shortname}.include?(n.shortname)
        end
      end
      return buffer
    end

    def has_follows?(sched)
      ! has_follows(sched).empty?
    end

    def has_follows(sched)
      sched.follows
    end

    def is_followed?(sched)
      ! is_followed(sched).empty?
    end

    def is_followed(sched)
      @source.find_all do |s|
        sfollows=s.follows.collect{|f| f.shortname }
        sfollows.include?(sched.shortname)
      end
    end

		def def_dot_node()
			@logger.debug(self.class){"writing streams. "}
			@sub.collect{|s|
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
			@logger.debug(self.class){"writing dependency arrows. "}
			@sub.collect{|s|
				myself='"'+s.fullname+'"'
				s.follows.collect{|f| '"'+f.fullname+'" -> '+myself+';'}.join("\n")
			}.join("\n")
		end
		private :def_dot_edge

	end
end

	
