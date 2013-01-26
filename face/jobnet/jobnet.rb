require 'erb'

module Composer::Face
	#= Jobnet
	#解析したジョブストリームのFOLLOWSを元に、ジョブストリーム間の依存関係をJobnet図として視覚化する。
	#視覚化する際にはgraphvizがインストールされていることが前提となる。
	#
	#=== graphviz公式サイト(http://www.graphviz.org/)
	#graphvizはCPL(Common Public License)に従って配布されている。
	#当バージョンでの稼動確認環境は、
	# dot - Graphviz version 2.12 (Mon Dec  4 22:04:37 UTC 2006)
	#
	#当Faceでは以下の設定が可能。
	#- デフォルトの出力形式はsvgであるが、outformat=(str) メソッドにて出力形式を指定することが可能。
	#  選択可能な出力形式はgraphvizの仕様に従う。(例. jpg, gif, ps 等々)
	#- 出力対象のジョブストリームを、ワークステーション名、ストリーム名にてフィルタリングすることが可能。
	#  (wkstation_filter=(str),stream_filter=(str))
	#- SCHEDULEにてON句としてREQUESTのみが定義されているストリームを出力対象とするか否か。
	#  (draw_only_request=(bool) true:出力する。false:出力しない。)
	#
	#== 例.
	#  frontend.face='jobnet'                               #=> faceとしてJobnetを使用。
	#  frontend.prepare(:outformat=,'jpg')                  #=> 出力ファイルフォーマットはJPG(デフォルトはsvg)
	#  frontend.prepare(:wkstation_filter=,'RV00000')       #=> ワークステーション名がRV00000から始まるもののみを出力(デフォルトは全て)
	#  frontend.prepare(:stream_filter=,'STR_(A|B|C)\w')    #=> ストリーム名がSTR_から始まり、その後A又はB又はC　が続き、その後の文字も英数字であるもの(デフォルトは全て)
	#  frontend.prepare(:draw_only_request=,true)           #=> ON句がREQUESTのみのストリームも出力する(ただし、破線で出力)。(デフォルトは出力しない)
	#  frontend.convert                                     #=> outfiles/jobnet.dot 及び、 outfiles/jobnet.svg が出力される。
	#
	#== 描画内容
	#- ジョブストリームは、四角形にて表現する。
	#- ジョブストリーム間に依存関係がある場合には、先行ジョブストリームから、後行ジョブストリームに向けた→で表現する。
	#- ジョブストリームを表現する四角形内部には、基本的には　"ストリーム名(改行)@ワークステーション名"　を出力する。
	#  ただし、ワークステーション名又はストリーム名で先行ジョブストリームがフィルタリングされている場合、その先行ジョブストリームは "ワークステーション名#ストリーム名"で表現する。
	#- AT句、UNTIL句、DEADLINE句が指定されたジョブストリームには、それぞれ a HHMM u HHMM d HHMM をその名称に追加で出力する。
	#- ON句がREQUESTのみのジョブストリームは破線で表現する。(draw_only_request=trueの場合のみ)
	#
	#== 依存関係
	#- graphvizがインストールされているマシン上で実行すること。(graphvizがインストールされていない場合、dotファイルのみをoutfilesディレクトリに出力)
	#- Scheduleがparseされていること
	#
	#== 注意点
	#大量のストリーム(約7,000ストリーム)を画像ファイル化する際には、非常に大量のメモリ(1Gのメモリでも不足した。)を要求するため、
	#デフォルトの出力形式を比較的小さなメモリしか要求しないsvg形式としている。
	#ただし、使用しているSVG viewerによっては大きなsvgファイルを参照できない場合があるので注意。
	#
	#( 参考- SVG viewer )
	#- Inkscape ( 公式サイト http://www.inkscape.org/ ) : スタンドアロンのSVG Viewer
	#- Adobe SVG Viewer ( 公式サイト http://www.adobe.com/jp/svg/ ) : Webブラウザ(IE)のplugin
	#- Mozilla Firefox ( 公式サイト http://www.mozilla.com/en-US/ ) : Webブラウザ
	class Jobnet
		include Composer::BaseMake

		def on_setup
			@outformat="svg"
			@wkstation_filter=nil
			@stream_filter=nil
			@draw_only_request=false
			@f_schedules=nil
		end
		#デフォルトは"svg"。出力ファイルフォーマットを示す文字列を設定する。
		attr_accessor :outformat
		#デフォルトはnil。何らかの文字を設定した場合、ワークステーション名の先頭から指定された文字(を正規表現としてあつかい)にマッチするストリームのみを出力対象とする。
		attr_accessor :wkstation_filter
		#デフォルトはnil。何らかの文字を設定した場合、ストリーム名の先頭から指定された文字(を正規表現としてあつかい)にマッチするストリームのみを出力対象とする。
		attr_accessor :stream_filter
		#デフォルトはfalse。trueを設定した場合には、REQUESTしかON句に指定されていないストリームも出力対象とする。
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

	
