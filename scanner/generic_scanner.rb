
require 'strscan'

module Composer::Scanner
	#= GenericScanner
	#  シンプルな逐次切り出し型スキャナ
	#  引数のファイル内容を読み取り、事前に指定された正規表現[reg]にマッチする場合には、
	#  その正規表現に関連づけられたtokenとともにその値[value]をyieldする。
	#  ファイル内容の走査順は[reg,token]の登録順となり、いずれのregにもマッチしない場合には
	#  トークン：UNKNOWNをyieldする。(で、parse error となる)
	class GenericScanner
		BUILTIN_TOKENS={
			:WORD    =>/\A[\w\-]+/ ,							# 英数字,ハイフン,アンダースコアの連続
			:NUMBER   =>/\A(\d+)[^\w-]/,					# 数字の連続＋非WORD。[ 123hoge ] や [ 123-foo ] はマッチしない。go_back対象
			:STRING   =>/\A"(?:[^"\\]+|\\.)*"/,
			:PATH     =>/\A[\w\-\/\.]+/,		# 英数字,ハイフン,アンダースコア,スラッシュ,バックスラッシュ,ピリオドの連続
			:DATE6    =>/\A[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9]/, # nn/nn/nn 形式
			:DATE8    =>/\A[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9]/ # nn/nn/nnnn 形式
		}

		def initialize(fname,parser)
			@parser=parser
			@scanner=StringScanner.new(File.read(fname))
			@tokens=[] # [ reg, token, go_back? ]
			@logger=Composer::SingletonLogger.instance
			@declare=nil
		end
		attr_accessor :declare

		# scan時に使用する正規表現とtokenのペアを設定する。
		# tokenを指定しない場合には、その正規表現にマッチする部分は読み飛ばし
		def append_tokens(reg,token=nil,go_back=false)
			@tokens.push [reg,token,go_back]
		end

		# いわゆる予約語を受け入れる。
		# 第一引数は大文字小文字を区別するか否か(true : 区別する)
		# 第二引数以降はその文字そのもの。
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

		# scan時に使用する正規表現とtokenのペアを定義済みのtokenを用いて設定する。(tokenのみ指定すればよい)
		def builtin_token(token)
			if reg=BUILTIN_TOKENS[token]
				if token==:NUMBER
					@tokens.push [reg,token,true]  # NUMBER はgo back 対象。
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
			# 正規表現が何れもマッチしない場合の無限ループ避け
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
							break # jump out @tokens.each
						end
					end
				}
			end
			yield false,false
		end
	end
end


