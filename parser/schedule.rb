
module Composer::TwsObj
	#= Schedule
	#�X�P�W���[��(�W���u�X�g���[��)��\������N���X�B
	#
	#�����Ƃ��Ĉȉ������B
	#- SCHEDULE��`�̒��O�ɕt�^���ꂽ�s�R�����g�̓��e(comment)
	#- �X�P�W���[���̒�`���ꂽ���[�N�X�e�[�V������(wkstation)
	#- �X�P�W���[����(name)
	#- FREEDAYS�Ŏw�肳�ꂽ�x�Ɠ��J�����_�[��(freedays_cal)
	#- FREEDAYS�Ŏw�肷��I�v�V����(-sa,-su)�� String �z��B(freedays_opt)
	#- ON�Ŏw�肳�ꂽ���s���t�� ScheduledDate �z��(on)
	#- DEADLINE�Ŏw�肳�ꂽ������ ScheduledTime �z��(deadline)
	#- EXCEPT�Ŏw�肳�ꂽ���s���O���t��  ScheduledDate �z��(except)
	#- AT�Ŏw�肳�ꂽ�J�n������ ScheduledTime �z��(at)
	#- CARRYFORWARD���w�肳��Ă��邩�ۂ�(carryforward)
	#- �Y���W���u�X�g���[�������O�����Ƃ���X�g���[��/�W���u�� Follow �z��(follows)
	#- KEYSCHED���w�肳��Ă��邩�ۂ�(keysched)
	#- LIMIT�Ŏw�肳�ꂽ�������s�W���u��(limit)
	#- �Y���W���u�X�g���[�����K�v�Ƃ��郊�\�[�X�� Resource �z��(needs)
	#- �Y���W���u�X�g���[�����K�v�Ƃ���t�@�C���� DependFile �z��(opens)
	#- PRIORITY�Ŏw�肳�ꂽ�D�揇��(priority)
	#- PROMPTS�Ŏw�肳�ꂽ�v�����v�g�� String �z��(prompts)
	#- UNTIL�Ŏw�肳�ꂽ������ ScheduledTime �z��(until)
	#- ONUNTIL�Ŏw�肳�ꂽ�A�N�V����(onuntil)
	#- �Y���X�g���[���Ŏ��s�����W���u�� ScheduledJob �z��(jobs)
	class Schedule
		extend ::Composer::SensitiveAttr

		def initialize
			@wkstation=nil
			@name=nil
			@freedays_cal=nil
			@freedays_opt=nil
			@description=nil
			@draft=nil
			@on=[]
			@deadline=[]
			@except=[]
			@at=[]
			@carryforward=nil
			@follows=[]
			@keysched=nil
			@limit=nil
			@needs=[]
			@opens=[]
			@priority=nil
			@prompts=[]
			@until=nil
			@onuntil=nil
			@jobs=[]
			@logger=::Composer::SingletonLogger.instance
			@comment=nil
		end
		sensitive_accessor :wkstation, :name, :freedays_cal, :carryforward, :keysched, :limit, :priority, :until, :onuntil, :comment
		attr_accessor :on, :deadline, :except, :at, :follows, :needs, :opens, :prompts, :jobs
		attr_accessor :description, :draft
		attr_reader :freedays_opt

		#�X�P�W���[�������ݒ肳��Ă��� AND ,ON��,JOB��̑o���Ƃ����Ȃ��Ƃ�1�������݂���ꍇ�ɐ^��ԋp�B
		def set_enough?
			@name && (! @jobs.empty?) && (! @on.empty?)
		end

		#freedays�I�v�V������ݒ肷��B�ʏ�̗p�r�ł͂��̃��\�b�h���g�p����K�v�͖����B 
		def freedays_opt=(val) #:nodoc:
			@freedays_opt=val.scan(/\-\w\w/) if val
		end

		#ScheduledDate�n�̑�����ݒ肷��writer.�ʏ�̗p�r�ł͂��̃��\�b�h���g�p����K�v�͖����B
		def append_dates(ivar,scheduled_dates,fdrule) #:nodoc:
			ivar=instance_variable_get("@#{ivar}")
			scheduled_dates.each{|sched_date|
				sched_date.fdrule=fdrule
				ivar.push sched_date
			}
		end

		#�X�P�W���[���̏C����(wkstation#name)��ԋp����B
		#�W���u��(���̓��J�o���[�W���u��)���ݒ肳��Ă��Ȃ��ꍇ�ɂ́A_NO_ENTRY_ ��ԋp����B
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

		#�X�P�W���[���̏C����(wkstation#name)��ԋp����B
		#�W���u���͕t�^���Ȃ��B
		def shortname()
			wk=@wkstation
			jo=@name
			if wk && jo
				return wk+'#'+jo
      else
				return jo
      end
		end

		#carryforward���w�肳��Ă�����true
		def carryforward?
			@carryforward ? true : false
		end

		#keysched���w�肳��Ă�����true
		def keysched?
			@keysched ? true : false
		end
		alias :keyschedule? :keysched?

		#freedays�̕�����\����ԋp�B
		def freedays
			if @freedays_cal && @freedays_opt
				@freedays_cal +' '+ @freedays_opt.join(' ')
			elsif @freedays_cal
				@freedays_cal
			else
				''
			end
		end

	end

	#= ScheduledDate
	#�X�P�W���[��(�W���u�X�g���[��)���Ŏg�p�����A�I�t�Z�b�g�y�ыx�Ɠ����̎�舵�����܂񂾓��t��\������N���X�B
	#
	#�����Ƃ��Ĉȉ������B
	#- ���t������������(mm/dd/yy),�j����������������(tu��)�A���̓J�����_�[�̖��O(value)
	#- �I�t�Z�b�g�̕����\��(offset)
	#- �x�Ɠ��������ۂ̎�舵��(FDIGNORE,FDNEXT,FDPREV��) (fdrule)
	class ScheduledDate
		def initialize(value,offset,fdrule=nil)
			@value=value
			@offset=offset
			@fdrule=fdrule
		end
		attr_accessor :value, :offset, :fdrule

		#���g�̕�����\����ԋp����B
		def to_s
			ret=''
			ret << @value if @value
			ret << ' ' << @offset if @offset
			ret << ' ' << @fdrule if @fdrule
			ret
		end
	end

	#= ScheduledTime
	#�X�P�W���[��(�W���u�X�g���[��)���Ŏg�p�����A�^�C���]�[���y�уI�t�Z�b�g�̎�舵�����܂񂾎�����\������N���X�B
	#
	#�����Ƃ��Ĉȉ������B
	#- ����(hhmm)������������B (value)
	#- �^�C���]�[��������������B(timezone)
	#- �I�t�Z�b�g�̕����\��(offset)
	class ScheduledTime
		def initialize(value,timezone,offset)
			@value=value
			@timezone=timezone
			@offset=offset
		end
		attr_accessor :value, :timezone, :offset

		#���g�̕�����\����ԋp����B
		def to_s
			ret=''
			ret << @value if @value
			ret << ' TZ ' << @timezone if @timezone
			ret << ' ' << @offset if @offset
			ret
		end
	end


	#= Follow
	#�X�P�W���[��(�W���u�X�g���[��)���ˑ������s�W���u(�W���u�X�g���[��)��\������N���X�B
	#
	#�����Ƃ��Ĉȉ������B
	#- �l�b�g���[�N�E�G�[�W�F���g�̖��O�B (netagent)
	#- ��s�W���u�̉ғ����郏�[�N�X�e�[�V�������B(wkstation)
	#- ��s�W���u�X�g���[����(stream)
	#- ��s�W���u��(job)
	class Follow
		def initialize(netagent,wkstation,stream,job)
			@netagent=netagent
			@wkstation=wkstation
			@stream=stream
			@job=job
		end
		attr_accessor :stream, :job, :wkstation, :netagent

		#���g�̕�����\����ԋp����B
		def to_s
			ret=''
			ret << @netagent << '::' if @netagent
			ret << @wkstation << '#' if @wkstation
			ret << @stream if @stream
			ret << '.' << @job if @job
			ret
		end

		#Follow�̃X�g���[���C����(wkstation#stream)��ԋp����B
		#�W���u�����ݒ肳��Ă��Ȃ��ꍇ�ɂ́A_NO_ENTRY_ ��ԋp����B
		#�u���b�N�t���ŌĂ΂ꂽ�ꍇ�ɂ́A���̃u���b�N��]�������l��_NO_ENTRY_�̑���Ƃ��ėp������B
		def fullname()
			wk=@wkstation
			jo=@stream
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
    
		#Follow�̏C����(wkstation#name)��ԋp����B
		#�W���u���͕t�^���Ȃ��B
		def shortname()
			wk=@wkstation
			jo=@stream
			if wk && jo
				return wk+'#'+jo
      else
				return jo
      end
		end
	end

	#= DependFile
	#�X�P�W���[��(�W���u�X�g���[��)�̈ˑ��t�@�C����\������N���X�B
	#
	#�����Ƃ��Ĉȉ������B
	#- �ˑ��t�@�C���̑��݂��郏�[�N�X�e�[�V�������B (wkstation)
	#- �ˑ��t�@�C���̑��݂���p�X�B(path)
	#- �ˑ��t�@�C���̃e�X�g����(qualifier)
	class DependFile
		def initialize(wkstation,path,qualifier)
			@wkstation=wkstation
			@path=path
			@qualifier=qualifier
		end
		attr_accessor :wkstation, :path, :qualifier

		#���g�̕�����\����ԋp����B
		def to_s()
			ret=''
			ret << @wkstation << '#' if @wkstation
			ret << @path if @path
			ret << @qualifier if @qualifier
			ret
		end
	end

	#= ScheduledJob
	#�W���u�X�g���[�����ɒ�`���ꂽ�W���u��\������N���X�B
	#
	#
	#���N���X��Composer::Job�ɂĒ�`���ꂽ�����ɉ����Ĉȉ��̑��������B
	#- AT�Ŏw�肳�ꂽ�J�n������ ScheduledTime �z��(at)
	#- (confirmed)
	#- DEADLINE�Ŏw�肳�ꂽ������ ScheduledTime �z��(deadline)
	#- (every)
	#- �Y���W���u�����O�����Ƃ���X�g���[��/�W���u�� Follow �z��(follows)
	#- KEYJOB���w�肳��Ă��邩�ۂ�(keyjob)
	#- �Y���W���u���K�v�Ƃ��郊�\�[�X�� Resource �z��(needs)
	#- �Y���W���u���K�v�Ƃ���t�@�C���� DependFile �z��(opens)
	#- PRIORITY�Ŏw�肳�ꂽ�D�揇��(priority)
	#- (prompts)
	#- (until)
	class ScheduledJob < Job
		def initialize
			super
			@at=[]
			@confirmed=nil
			@deadline=[]
			@every=nil
			@follows=[]
			@keyjob=nil
			@needs=[]
			@opens=[]
			@priority=nil
			@prompts=[]
			@until=nil
			@onuntil=nil
		end
		attr_accessor :at, :confirmed, :deadline, :every, :follows, :keyjob, :needs, :opens, :priority, :prompts, :until, :onuntil 

		#KEYJOB���w�肳��Ă���ꍇ�ɂ͐^��ԋp�B
		def keyjob?
			@keyjob ? true : false
		end

		#���g�̕�����\����ԋp����B
		def to_s()
			ret=super
			ret << ' AT ' << @at.collect{|a| a.to_s}.join(',') if @at
			ret << ' KEYJOB' if @keyjob
			ret << ' PRIORITY ' << @priority if @priority
			ret='"'+ret.gsub(/"/,'""')+'"' if @at.size > 1
			ret
		end
	end

end
