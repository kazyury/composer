require 'date'

module Composer::TwsObj
	#= Calendar
	#�X�P�W���[�����O�J�����_�[��\������N���X�B
	#
	#�����Ƃ��ăJ�����_�[��(@name),����(@description)�����B
	#mm/dd/yy�`���̓��t(@date)�ւ̒��ڂ̃A�N�Z�X��i�͖����A@dateformat������`(nil)�̏ꍇ��
	#Calendar#dates���\�b�h�ɂĎ擾�ł���B
	#@dateformat�ɑÓ��ȃt�H�[�}�b�g������(Date#strftime,strftime(3),strptime���Q��)���w�肳��Ă���
	#�ꍇ�ɂ́ACalendar#dates���\�b�h�͂��̏����Ńt�H�[�}�b�g����������̔z��(���t�̌Â����Ƀ\�[�g)
	#��ԋp����B
	class Calendar
		extend ::Composer::SensitiveAttr

		def initialize
			@name=nil
			@description=nil
			@date=[]
			@date_internal=[]
			@dateformat=nil
			@logger=::Composer::SingletonLogger.instance
		end
		sensitive_writer :name, :description
		attr_reader :name,:description, :date, :date_internal
		attr_accessor :dateformat

		#@date�ւ̃A�N�Z�T(reader)�B
		#Calendar#dateformat='format-string' ��dateformat���`���Ă���ꍇ�ɂ́A
		#���̏�����K�p�������t���Â����Ƀ\�[�g�����z��ŕԋp�B
		# as of 03/27/2007
    #- %A: �j���̖���(Sunday, Monday ... )
    #- %a: �j���̏ȗ���(Sun, Mon ... )
    #- %B: ���̖���(January, February ... )
    #- %b: ���̏ȗ���(Jan, Feb ... )
    #- %c: ���t�Ǝ���
    #- %d: ��(01-31)
    #- %H: 24���Ԑ��̎�(00-23)
    #- %I: 12���Ԑ��̎�(01-12)
    #- %j: �N���̒ʎZ��(001-366)
    #- %M: ��(00-59)
    #- %m: ����\������(01-12)
    #- %p: �ߑO�܂��͌ߌ�(AM,PM)
    #- %S: �b(00-60) (60�͂��邤�b)
    #- %U: �T��\�����B�ŏ��̓��j������1�T�̎n�܂�(00-53)
    #- %W: �T��\�����B�ŏ��̌��j������1�T�̎n�܂�(00-53)
    #- %w: �j����\�����B���j����0(0-6)
    #- %X: ����
    #- %x: ���t
    #- %Y: �����\����
    #- %y: ����̉�2��(00-99)
    #- %Z: �^�C���]�[�� trap
    #- %%: %���g
		#
		#�u���b�N�ƂƂ��Ɏg�p�����ꍇ�ɂ́A�e���t(Date�I�u�W�F�N�g)��yield����B
		def dates
			if block_given?
				@date_internal.each{|d| yield d }
			else
				if @dateformat
					return @date_internal.collect{|d| d.strftime(@dateformat) }
				else
					return @date
				end
			end
		end

		#@date�ւ̃A�N�Z�T�B
		#�ʏ�̗p�r(Face�N���X�̊J���AComposer�t�@�C���̕\���`���ύX)�ł͎g�p����K�v�������B
		def append_date(mmddyy)
			@date.push mmddyy
			if /(\d\d)\/(\d\d)\/(\d\d)/=~mmddyy
				@date_internal.push Date.parse(mmddyy,true)
				@date_internal.sort!
			else
				@logger.warn("#{self.class}"){ "defined date [ #{mmddyy} } may not be parsed correctly." }
			end
		end

		#�K�{�̃J�����_�[��,���t���Z�b�g����Ă����true��ԋp
		def set_enough?
			@name && (! @date.empty?)
		end
	end
end
