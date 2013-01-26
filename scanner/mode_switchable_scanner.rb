

module Composer::Scanner
	#= ModeSwitchableScanner
	#  �X�L�����Ώ�token�𓮓I�ɐ؂�ւ�����X�L���i
	#  ��{�I�ɂ�GenericScanner�Ɠ��l�̓���ƂȂ邪�Ascanner.swith(:MODE) �ŃX�L�������[�h��؂�ւ���B
	#  ���[�h�͎��O��on�u���b�N���œo�^����B
	#  ���̐��K�\���Ɋ֘A�Â���ꂽtoken�ƂƂ��ɂ��̒l[value]��yield����B
	#  �t�@�C�����e�̑�������[reg,token]�̓o�^���ƂȂ�A�������reg�ɂ��}�b�`���Ȃ��ꍇ�ɂ�
	#  �g�[�N���FUNKNOWN��yield����B(�ŁAparse error �ƂȂ�)
	class ModeSwitchableScanner < GenericScanner

		def initialize(fname,parser)
			super
			@mode=:DEFAULT
			@mode_frame={:DEFAULT=>[]}
			@mode_frame.default=[]
		end
		attr_reader :mode, :mode_frame, :tokens


		def switch(mode)
			@tokens=@mode_frame[mode]
			raise 'empty tokens' if @tokens.empty?
			@mode=mode
		end

		def on(mode=:DEFAULT)
			@mode=mode
			@tokens=@mode_frame[@mode] # �w�肳�ꂽ�t���[�����J�����g��
			if @tokens.empty?
				@mode_frame[mode]=@mode_frame[:DEFAULT].dup
				@tokens=@mode_frame[@mode]
			end
			yield self
			@mode_frame.merge!({ mode => @tokens })
			@mode=:DEFAULT							# ������Ƃ��́A:DEFAULT�ɖ߂��B
			@tokens=@mode_frame[@mode]
		end

		def append_tokens(reg,token=nil,go_back=false)
			@tokens=@mode_frame[@mode]
			super
			regist_default_token(reg,token,go_back) if @mode==:DEFAULT
		end

		def reserved_word(case_sensitive,*words)
			@tokens=@mode_frame[@mode]
			words.each{|word|
				if case_sensitive
					reg=Regexp.new('\A('+word+')[^\w-]')
				else
					reg=Regexp.new('\A('+word+')[^\w-]',Regexp::IGNORECASE)
				end
				@tokens.push [reg, word.upcase.intern, true]
				regist_default_token(reg,word.upcase.intern,true) if @mode==:DEFAULT
			}
		end

		# scan���Ɏg�p���鐳�K�\����token�̃y�A���`�ς݂�token��p���Đݒ肷��B(token�̂ݎw�肷��΂悢)
		def builtin_token(token)
			@tokens=@mode_frame[@mode]
			super
			if @mode==:DEFAULT
				if token==:NUMBER
					regist_default_token(BUILTIN_TOKENS[token],token,true)
				else
					regist_default_token(BUILTIN_TOKENS[token],token,false)
				end
			end
		end

		def scan
			lineno=1
			@parser.scan_line=lineno
			# ���K�\����������}�b�`���Ȃ��ꍇ�̖������[�v����
			@mode_frame[:DEFAULT].push [/./,:UNKNOWN,false]
			regist_default_token(/./,:UNKNOWN,false)

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
				@mode_frame[@mode].each{|reg_token|
					reg, token, go_back = reg_token
#					@logger.debug("#{self.class}"){ "#{reg},#{token}   rest is #{@scanner.rest}" }
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
							break
						end
					end
				}
			end # of until
			yield false,false
		end

		:private
		def regist_default_token(reg,token,go_back)
			@mode_frame.each{|mode,frame|
				next if mode==:DEFAULT
				frame.push [ reg,token,go_back ]
			}
		end
	end
end


