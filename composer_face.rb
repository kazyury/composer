#!ruby -Ks

#:include: README
#:include: VERSION
#:include: TODO
require 'yaml'
require 'rexml/document'
require 'optparse'
require 'frontend'

#=UserInterface
#デフォルトのUI。CUI環境から実行することを想定している。
#(なお、Win32Binary版を使用している方は、以降の記述で、ruby composer_face.rb と記述している箇所を composer_face.exe と読み替えてください。)
#
#==composer_face, HOW TO USE ?
#
#何もオプションを与えずに実行するとUsage表示
# D:\sasaki\RubyScript\composer>ruby composer_face.rb
# composer_face [-x|-y] configuration
#
# / change your TWS composer's face.
#    -x, --use_XML                    Force to process configuration as XML.
#    -y, --use_YAML                   Force to process configuration as YAML.
#    -h, --help                       Show this message
#
#実行する際には、xml形式又はyaml形式の構成ファイルを指定する。(suffixにて自動判断。suffixが.yaml ,.xml で無い場合には、-x 又は -y オプションを使用する必要がある。)
#[ xml形式の構成ファイルを使用する場合 ]
# C:\home\RubyScript\composer>ruby composer_face.rb sample_config.xml
# I, [2008-08-02T01:04:28.296000 #4100]  INFO -- Composer::FrontEnd: original KCODE was       SJIS
# :(snip)
#
#or
#
#[ yaml形式の構成ファイルを使用する場合 ]
# C:\home\RubyScript\composer>ruby composer_face.rb sample_config.yaml
# I, [2008-08-02T01:05:27.343000 #5388]  INFO -- Composer::FrontEnd: original KCODE was       SJIS
# :(snip)
#
#
#==構成ファイルの書式
#構成ファイルは、YAML形式、XML形式を使用することができます。好きな方の形式を使用して下さい。機能的な差異はありません。
#
#===YAML形式の構成ファイル書式
#YAML仕様の詳細についてはWeb等を参照してください。恐らくなじみの無い方が多いでしょう。
#XML形式よりは柔軟な設定がしやすいため、yaml形式も採用しています。
# YAML Specification
# <URL:http://www.yaml.org/spec/>
# <URL:http://www.yaml.org/type/>
#
#==== Sample
# C:\home\RubyScript\composer>cat sample_config.yaml
# ---
# calendars: test\testdata\calendar_parser.in.0001
# jobs: test\testdata\job_parser.in.0001
# parameters: test\testdata\parameter_parser.in.0001
# prompts: test\testdata\prompt_parser.in.0001
# resources: test\testdata\resource_parser.in.0001
# schedules: test\testdata\schedule_parser.in.0001
# workstations: test\testdata\workstation_parser.in.0001
# faces:
#   - face: default_face
#   - face: stream_plan
#     prep:
#     -  - range_set
#        - "2006-01-01"
#        - "2006-02-01"
#   - face: jobnet
#     prep:
#     -  - outformat=
#        - svg
#     -  - stream_filter=
#        - S2_(JBA[^U]|JBT|JBI|JBX)
#     -  - draw_only_request=
#        - false
# log_level: 1
# use_cache: true
#
#==== Description
#yaml形式の構成ファイルは、総体としてはHashの形式になっています。
#HashのKeyとValueとして期待している形式は以下のとおりです。
#- calendars: CALENDAR定義情報ファイルへのパスを文字列として表現していることを期待
#- jobs: JOB定義情報ファイルへのパスを文字列として表現していることを期待
#- parameters: PARAMETER定義情報ファイルへのパスを文字列として表現していることを期待
#- prompts: PROMPTS定義情報ファイルへのパスを文字列として表現していることを期待
#- resources: RESOURCES定義情報ファイルへのパスを文字列として表現していることを期待
#- schedules: SCHEDULES定義情報ファイルへのパスを文字列として表現していることを期待
#- workstations: WORKSTATIONS定義情報ファイルへのパスを文字列として表現していることを期待
#- log_level:
#  0-4の数値を期待。
#  composer_face全体を通したログレベルの指定。
#  0(debug) > 1(info) > 2(warn) > 3(error) > 4(fatal)
#  の順にログ情報が抑制され、fatalを指定すると一切の情報を抑制する。お勧めは2(警告以上を印字)
#- use_cache: 
#  true 又は false を期待。
#  trueが指定されている場合、Composerが出力した各定義情報ファイルの解析結果を(使用可能ならば)解析済みのオブジェクトで代替する。
#  (trueを推奨)
#  使用可能である条件は以下のとおり。
#  - 既に解析済みの情報がcacheされていること。
#  - 既に解析済みの情報と、今回指定した定義情報の内容が同一であること。
#- faces:
#  出力に使用するface(faceとprepをKeyとして持つHash)の配列を期待。faces以下に格納されたfaceを順に出力する。
#  - face:
#    出力に使用するfaceの名称を文字列で指定します。どのようなfaceが使用可能かは、faceディレクトリ以下を参照してください。
#    組み込みのfaceについては、以下の3種のいずれかです。
#    * default_face
#    * stream_plan
#    * jobnet
#  - prep:
#    faceの出力開始前にfaceオブジェクトに与える事前準備情報を、メソッド名、引数×nの順に指定します。
#    ここは、いずれのfaceを使用するかにより異なってきます。組み込みFaceのうち、default_faceはprepを要しませんが、stream_planはrange_setが必ず必要です。
#    また、jobnetは最大4つのprepを指定できますが、何れも必須ではありません。詳細は各Faceの説明を参考にしてください。
#    * Composer::Face::DefaultFace
#    * Composer::Face::StreamPlan
#    * Composer::Face::Jobnet
#
#===XML形式の構成ファイル書式
#開発当初は、構成ファイルとしてYAML形式のみを採用していましたが、
#データの入れ子関係の分かりやすさ、メンテしやすさ(打鍵量は別として)、認知度を考慮して、
#XML形式の構成ファイルも処理可能としました。
#==== Sample
# C:\home\RubyScript\composer>cat sample_config.xml
# <?xml version="1.0" encoding="Shift_JIS" ?>
# <config>
#   <log_level    value="1" />
#   <use_cache    value="true" />
#   <calendars    value="test\\testdata\\calendar_parser.in.0001" />
#   <jobs         value="test\\testdata\\job_parser.in.0001" />
#   <parameters   value="test\\testdata\\parameter_parser.in.0001" />
#   <prompts      value="test\\testdata\\prompt_parser.in.0001" />
#   <resources    value="test\\testdata\\resource_parser.in.0001" />
#   <schedules    value="test\\testdata\\schedule_parser.in.0001" />
#   <workstations value="test\\testdata\\workstation_parser.in.0001" />
#   <faces>
#     <face value="default_face"></face>
#     <face value="stream_plan">
#       <prep method="range_set" values="2006-01-01 2006-02-01" />
#     </face>
#     <face value="jobnet">
#       <prep method="outformat="         values="svg" />
#       <prep method="stream_filter="     values="S2_(JBA[^U]|JBT|JBI|JBX)" />
#       <prep method="draw_only_request=" values="false" />
#     </face>
#   </faces>
# </config>
#==== Description
#見れば分かるというかたも多いかと思いますので、詳細は割愛します。
#
#==== Meanings...
#上記2種のサンプル構成ファイルの意味は以下のようになります。
#1. calendars,jobs,parameters,prompts,resources,schedules,workstations の定義情報は各々指定されたパスのファイルを使用する。
#2. 上記ファイルの解析結果を用いて、3種類のfaceで出力する。
#3. 最初に、'default_face'を用いて出力する。特に、出力前の準備(prep:)無し。
#4. 次に'stream_plan'を用いて出力する。出力前の準備(prep:)としてStreamPlanのrange_setメソッドに引数2006-01-01,2006-02-01を渡す。
#5. 最後に'jobnet'を用いて出力する。出力前の準備(prep:)として
#   * 出力ファイルフォーマット(outformat=)をsvgに設定
#   * 対象ジョブストリームを、S2_JBAUを除くS2_JBA始まり、S2_JBT.*、S2_JBI.*、S2_JBX.*のみにフィルタリング(stream_filter=)
#   * 出力対象として、REQUESTのみのジョブストリームは対象としない。(draw_only_request= "false")
#6. 全体としてログレベルは2(Warningは出力)
#7. キャッシュを使用可能ならば使用する。
class UserInterface
	include Composer

	def initialize(conf_path,conf_format) #:nodoc:
		@ap=FrontEnd.new
		@conf_path=conf_path
		@conf_format=conf_format
	end

	def run #:nodoc:
		unless @conf_format
			# オプションでフォーマットが指定されていない場合には拡張子から判断
			guess_format_and_run(@conf_path)
		else
			if @conf_format==:YAML
				run_with_yaml(@conf_path)
			elsif @conf_format==:XML
				run_with_xml(@conf_path)
			end
		end
	end

	:private
	def guess_format_and_run(confpath)
		case File.extname(confpath)
		when /\.xml/i
			run_with_xml(confpath)
		when /\.yaml/i
			run_with_yaml(confpath)
		else
			raise "configfile(#{confpath})'s suffix is not yaml nor xml.use -x or -y option."
		end
	end

	def run_with_xml(cfg) #:nodoc:
		doc=REXML::Document.new(File.new(cfg))
		root=doc.root
		# 各々先頭1件のみ取得(あれば)
		@ap.log_level=root.elements["log_level"].attributes["value"].to_i      if root.elements["log_level"]
		@ap.use_cache=root.elements["use_cache"].attributes["value"]           if root.elements["use_cache"]
		@ap.tws_level=root.elements["tws_level"].attributes["value"]           if root.elements["tws_level"]
		@ap.calendars_def=root.elements["calendars"].attributes["value"]       if root.elements["calendars"]
		@ap.jobs_def=root.elements["jobs"].attributes["value"]                 if root.elements["jobs"]
		@ap.parameters_def=root.elements["parameters"].attributes["value"]     if root.elements["parameters"]
		@ap.prompts_def=root.elements["prompts"].attributes["value"]           if root.elements["prompts"]
		@ap.resources_def=root.elements["resources"].attributes["value"]       if root.elements["resources"]
		@ap.schedules_def=root.elements["schedules"].attributes["value"]       if root.elements["schedules"]
		@ap.workstations_def=root.elements["workstations"].attributes["value"] if root.elements["workstations"]
		@ap.parse
		root.elements.each("faces/face"){|face|
			@ap.face=face.attributes["value"]
			face.elements.each("prep"){|prep|
				meth=prep.attributes["method"]
				args=prep.attributes["values"].split(" ")
				@ap.prepare meth,*args
			}
			@ap.convert
		}
	end

	def run_with_yaml(cfg) #:nodoc:
		File.open(cfg){|f| @config=YAML.load(f) }
		@ap.use_cache=@config["use_cache"] if @config.include?("use_cache")
		@ap.log_level=@config["log_level"].to_i if @config["log_level"]
		@ap.tws_level=@config["tws_level"] if @config["tws_level"]
		@ap.jobs_def=@config["jobs"] if @config["jobs"]
		@ap.calendars_def=@config["calendars"] if @config["calendars"]
		@ap.parameters_def=@config["parameters"] if @config["parameters"]
		@ap.prompts_def=@config["prompts"] if @config["prompts"]
		@ap.resources_def=@config["resources"] if @config["resources"]
		@ap.schedules_def=@config["schedules"] if @config["schedules"]
		@ap.workstations_def=@config["workstations"] if @config["workstations"]
		@ap.parse
		faces=@config["faces"]
		unless faces.empty?
			faces.each{|face_def|
				@ap.face=face_def["face"]
				if prep_stmts=face_def["prep"]
					prep_stmts.each{|arg|
						@ap.prepare(*arg)
					}
				end
				@ap.convert
			}
		end
	end

end

config_format=nil

opt=OptionParser.new
opt.banner ="composer_face [-x|-y] configuration \n\n"
opt.banner+=" / change your TWS composer's face."

opt.on('-x','--use_XML' ,"Force to process configuration as XML."){|v| config_format=:XML}
opt.on('-y','--use_YAML',"Force to process configuration as YAML."){|v| config_format=:YAML}
opt.on('-h','--help'    ,'Show this message'){|v| puts opt ; exit }

if ARGV.size==0
	puts opt
	exit
end
opt.parse!(ARGV)

if ARGV.size==0 || ! File.exist?(ARGV[0])
	puts opt
	exit
end

ui=UserInterface.new(ARGV[0],config_format)
ui.run

