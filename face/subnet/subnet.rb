require 'erb'

module Composer::Face
	#= Subnet
  #
  #Jobnetを連結部分グラフに分割し、それぞれのグラフごとのジョブネットを出力する。
  #要するに、依存関係のあるジョブネット毎に分割する。
	#
	#当Faceでは以下の設定が可能。
	#- デフォルトの出力形式はsvgであるが、outformat=(str) メソッドにて出力形式を指定することが可能。
	#  選択可能な出力形式はgraphvizの仕様に従う。(例. jpg, gif, ps 等々)
	#
	#== 例.
	#  frontend.face='jobnet'                               #=> faceとしてJobnetを使用。
	#  frontend.prepare(:outformat=,'jpg')                  #=> 出力ファイルフォーマットはJPG(デフォルトはsvg)
	#  frontend.convert                                     #=> outfiles/jobnet.dot 及び、 outfiles/jobnet.svg が出力される。
	#
	#== 描画内容
	#- ジョブストリームは、四角形にて表現する。
	#- ジョブストリーム間に依存関係がある場合には、先行ジョブストリームから、後行ジョブストリームに向けた→で表現する。
	#- ジョブストリームを表現する四角形内部には、基本的には　"ストリーム名(改行)@ワークステーション名"　を出力する。
	#  ただし、ワークステーション名又はストリーム名で先行ジョブストリームがフィルタリングされている場合、その先行ジョブストリームは "ワークステーション名#ストリーム名"で表現する。
	#- AT句、UNTIL句、DEADLINE句が指定されたジョブストリームには、それぞれ a HHMM u HHMM d HHMM をその名称に追加で出力する。
	#- ON句がREQUESTのみのジョブストリームは破線で表現する。
	#
	#== その他
	#その他の留意事項については、 Jobnet に準じます。
	class Subnet
		include Composer::BaseMake

		def on_setup
			@outformat="svg"
			@source_buffer=nil
			@f_schedules=nil
		end
		#デフォルトは"svg"。出力ファイルフォーマットを示す文字列を設定する。
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
      # Islandsだけは特別扱い
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

    # 解析済みのschedulesを連結部分グラフに分割する。
    # 最初の1件はschedulesの先頭を用いるが、深さ優先探索を行い全ての道を辿る。
    # また、1ノードのみの部分グラフ達は、ひとつのグラフ上(Islands)に表現する。
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

    # 深さ優先探索にて連結部分グラフ構成ノードを走査する。
    # つまり、自分自身のfollows に登録されているジョブストリーム、自分自身にfollowしているジョブストリームを再帰的に辿る。
    # - 注意!!! buffer にも、@source にもTwsObj::Scheduleが格納されている。
    def graph_search(buffer,sched)

			@logger.debug(self.class){"graph_search with [#{buffer.join(',')}], #{sched}"}
      if sched 
        # 取ってくる対象が指定されていれば、@sourceより探して、取得する。
        # ここでくるschedは、実際にはComposer::TwsObj::Followなので、TwsObj::Scheduleに変換する。
        temp=@source.find{|x| x.shortname == sched.shortname}
        unless temp
          @logger.warn(self.class){"#{sched.shortname} was not found.Ignored."}
          return buffer
        end
        sched=temp
      else # 取ってくる対象が指定されていなければ、任意の1JSを取得する。
        sched=@source.shift
      end
      buffer.push sched
      @source.delete(sched)
			@logger.debug(self.class){"processing #{sched.shortname}"}

      # JSがfollowしているものがあり、かつbufferに入っていない場合には、そのfollowしているものについて再帰的に取得
      if has_follows?(sched)
        has_follows(sched).each do |n|
          @logger.debug(self.class){"#{sched.shortname} follows #{n.shortname}"}
          buffer=graph_search(buffer,n) unless buffer.collect{|x| x.shortname}.include?(n.shortname)
        end
      end
      # このJSにfollowしているものがあり、かつbufferに入っていない場合には、そのfollowしているものについて再帰的に取得
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

	
