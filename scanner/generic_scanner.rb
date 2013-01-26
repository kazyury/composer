
require 'strscan'

module Composer::Scanner
	#= GenericScanner
	#  �V���v���Ȓ����؂�o���^�X�L���i
	#  �����̃t�@�C�����e��ǂݎ��A���O�Ɏw�肳�ꂽ���K�\��[reg]�Ƀ}�b�`����ꍇ�ɂ́A
	#  ���̐��K�\���Ɋ֘A�Â���ꂽtoken�ƂƂ��ɂ��̒l[value]��yield����B
	#  �t�@�C�����e�̑�������[reg,token]�̓o�^���ƂȂ�A�������reg�ɂ��}�b�`���Ȃ��ꍇ�ɂ�
	#  �g�[�N���FUNKNOWN��yield����B(�ŁAparse error �ƂȂ�)
	class GenericScanner
		BUILTIN_TOKENS={
			:WORD    =>/\A[\w\-]+/ ,							# �p����,�n�C�t��,�A���_�[�X�R�A�̘A��
			:NUMBER   =>/\A(\d+)[^\w-]/,					# �����̘A���{��WORD�B[ 123hoge ] �� [ 123-foo ] �̓}�b�`���Ȃ��Bgo_back�Ώ�
			:STRING   =>/\A"(?:[^"\\]+|\\.)*"/,
			:PATH     =>/\A[\w\-\/\.]+/,		# �p����,�n�C�t��,�A���_�[�X�R�A,�X���b�V��,�o�b�N�X���b�V��,�s���I�h�̘A��
			:DATE6    =>/\A[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9]/, # nn/nn/nn �`��
			:DATE8    =>/\A[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9]/ # nn/nn/nnnn �`��
		}

		def initialize(fname,parser)
			@parser=parser
			@scanner=StringScanner.new(File.read(fname))
			@tokens=[] # [ reg, token, go_back? ]
			@logger=Composer::SingletonLogger.instance
			@declare=nil
		end
		attr_accessor :declare

		# scan���Ɏg�p���鐳�K�\����token�̃y�A��ݒ肷��B
		# token���w�肵�Ȃ��ꍇ�ɂ́A���̐��K�\���Ƀ}�b�`���镔���͓ǂݔ�΂�
		def append_tokens(reg,token=nil,go_back=false)
			@tokens.push [reg,token,go_back]
		end

		# ������\�����󂯓����B
		# �������͑啶������������ʂ��邩�ۂ�(true : ��ʂ���)
		# �������ȍ~�͂��̕������̂��́B
		def reserved_word(case_sensitive,*words)
			words.each{|word|
				if case_sensitive
					reg=Regexp.new('\A('+word+')[^\w-]')
				else
					reg=Regexp.new('\A('+word+')[^\w-]',Regexp::IGNORECASE)
				end
				@tokens.push [reg, word.upcase.intern, true]
			}
		end

		# scan���Ɏg�p���鐳�K�\����token�̃y�A���`�ς݂�token��p���Đݒ肷��B(token�̂ݎw�肷��΂悢)
		def builtin_token(token)
			if reg=BUILTIN_TOKENS[token]
				if token==:NUMBER
					@tokens.push [reg,token,true]  # NUMBER ��go back �ΏہB
				else
					@tokens.push [reg,token,false]
				end
			else
				raise NoSuchReservedTokenError.new("#{token} is not defined.")
			end
		end

		def scan
			lineno=1
			@parser.scan_line=lineno
			# ���K�\����������}�b�`���Ȃ��ꍇ�̖������[�v����
			@tokens.push [/./,:UNKNOWN,false]

			if @declare 
				if matched=@scanner.scan(@declare)
					yield :DECLARE , matched
				else
					raise ScanUnmatchError.new( "DECLARATION was not in head of file " )
				end
			end

			until @scanner.eos?
				if @scanner.match?(/\A\n/)
					lineno+=1
					@parser.scan_line=lineno
				end
				@tokens.each{|reg_token|
					reg, token, go_back = reg_token
					@logger.debug("#{self.class}"){ "reg_token : #{reg} ,\t#{token}" }
					if matched=@scanner.scan(reg)
						@logger.debug("#{self.class}"){"[ #{reg} ] matched to [ #{matched} ] as [ #{token} ]."}
						if token
							# go_back ��TRUE�̏ꍇ�ɂ́A1�����]���ɓǂ�ł���̂œǂݖ߂��B
							if go_back
								matched=@scanner[1] # ()���݂̂��}�b�`�����f�[�^�Ƃ��Ēu������
								@scanner.pos-=1
							end

							@logger.debug("#{self.class}"){"yields #{token} #{matched}"}
							yield token, matched
							break # jump out @tokens.each
						else
							# token�̎w�肳��Ă��Ȃ����K�\���͓ǂݔ�΂�
							break # jump out @tokens.each
						end
					end
				}
			end
			yield false,false
		end
	end
end


