

module Composer::Scanner
	#= ModeSwitchableScanner
	#  スキャン対象tokenを動的に切り替えられるスキャナ
	#  基本的にはGenericScannerと同様の動作となるが、scanner.swith(:MODE) でスキャンモードを切り替える。
	#  モードは事前にonブロック内で登録する。
	#  その正規表現に関連づけられたtokenとともにその値[value]をyieldする。
	#  ファイル内容の走査順は[reg,token]の登録順となり、いずれのregにもマッチしない場合には
	#  トークン：UNKNOWNをyieldする。(で、parse error となる)
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
			@tokens=@mode_frame[@mode] # 指定されたフレームをカレントに
			if @tokens.empty?
				@mode_frame[mode]=@mode_frame[:DEFAULT].dup
				@tokens=@mode_frame[@mode]
			end
			yield self
			@mode_frame.merge!({ mode => @tokens })
			@mode=:DEFAULT							# 抜けるときは、:DEFAULTに戻す。
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

		# scan時に使用する正規表現とtokenのペアを定義済みのtokenを用いて設定する。(tokenのみ指定すればよい)
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
			# 正規表現が何れもマッチしない場合の無限ループ避け
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
							# go_back がTRUEの場合には、1文字余分に読んでいるので読み戻す。
							if go_back
								matched=@scanner[1] # ()内のみをマッチしたデータとして置き換え
								@scanner.pos-=1
							end

							@logger.debug("#{self.class}"){"yields #{token} #{matched}"}
							yield token, matched
							break # jump out @tokens.each
						else
							# tokenの指定されていない正規表現は読み飛ばし
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


