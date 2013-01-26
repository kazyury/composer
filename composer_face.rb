#!ruby -Ks

#:include: README
#:include: VERSION
#:include: TODO
require 'yaml'
require 'rexml/document'
require 'optparse'
require 'frontend'

#=UserInterface
#�f�t�H���g��UI�BCUI��������s���邱�Ƃ�z�肵�Ă���B
#(�Ȃ��AWin32Binary�ł��g�p���Ă�����́A�ȍ~�̋L�q�ŁAruby composer_face.rb �ƋL�q���Ă���ӏ��� composer_face.exe �Ɠǂݑւ��Ă��������B)
#
#==composer_face, HOW TO USE ?
#
#�����I�v�V������^�����Ɏ��s�����Usage�\��
# D:\sasaki\RubyScript\composer>ruby composer_face.rb
# composer_face [-x|-y] configuration
#
# / change your TWS composer's face.
#    -x, --use_XML                    Force to process configuration as XML.
#    -y, --use_YAML                   Force to process configuration as YAML.
#    -h, --help                       Show this message
#
#���s����ۂɂ́Axml�`������yaml�`���̍\���t�@�C�����w�肷��B(suffix�ɂĎ������f�Bsuffix��.yaml ,.xml �Ŗ����ꍇ�ɂ́A-x ���� -y �I�v�V�������g�p����K�v������B)
#[ xml�`���̍\���t�@�C�����g�p����ꍇ ]
# C:\home\RubyScript\composer>ruby composer_face.rb sample_config.xml
# I, [2008-08-02T01:04:28.296000 #4100]  INFO -- Composer::FrontEnd: original KCODE was       SJIS
# :(snip)
#
#or
#
#[ yaml�`���̍\���t�@�C�����g�p����ꍇ ]
# C:\home\RubyScript\composer>ruby composer_face.rb sample_config.yaml
# I, [2008-08-02T01:05:27.343000 #5388]  INFO -- Composer::FrontEnd: original KCODE was       SJIS
# :(snip)
#
#
#==�\���t�@�C���̏���
#�\���t�@�C���́AYAML�`���AXML�`�����g�p���邱�Ƃ��ł��܂��B�D���ȕ��̌`�����g�p���ĉ������B�@�\�I�ȍ��ق͂���܂���B
#
#===YAML�`���̍\���t�@�C������
#YAML�d�l�̏ڍׂɂ��Ă�Web�����Q�Ƃ��Ă��������B���炭�Ȃ��݂̖������������ł��傤�B
#XML�`�����͏_��Ȑݒ肪���₷�����߁Ayaml�`�����̗p���Ă��܂��B
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
#yaml�`���̍\���t�@�C���́A���̂Ƃ��Ă�Hash�̌`���ɂȂ��Ă��܂��B
#Hash��Key��Value�Ƃ��Ċ��҂��Ă���`���͈ȉ��̂Ƃ���ł��B
#- calendars: CALENDAR��`���t�@�C���ւ̃p�X�𕶎���Ƃ��ĕ\�����Ă��邱�Ƃ�����
#- jobs: JOB��`���t�@�C���ւ̃p�X�𕶎���Ƃ��ĕ\�����Ă��邱�Ƃ�����
#- parameters: PARAMETER��`���t�@�C���ւ̃p�X�𕶎���Ƃ��ĕ\�����Ă��邱�Ƃ�����
#- prompts: PROMPTS��`���t�@�C���ւ̃p�X�𕶎���Ƃ��ĕ\�����Ă��邱�Ƃ�����
#- resources: RESOURCES��`���t�@�C���ւ̃p�X�𕶎���Ƃ��ĕ\�����Ă��邱�Ƃ�����
#- schedules: SCHEDULES��`���t�@�C���ւ̃p�X�𕶎���Ƃ��ĕ\�����Ă��邱�Ƃ�����
#- workstations: WORKSTATIONS��`���t�@�C���ւ̃p�X�𕶎���Ƃ��ĕ\�����Ă��邱�Ƃ�����
#- log_level:
#  0-4�̐��l�����ҁB
#  composer_face�S�̂�ʂ������O���x���̎w��B
#  0(debug) > 1(info) > 2(warn) > 3(error) > 4(fatal)
#  �̏��Ƀ��O��񂪗}������Afatal���w�肷��ƈ�؂̏���}������B�����߂�2(�x���ȏ����)
#- use_cache: 
#  true ���� false �����ҁB
#  true���w�肳��Ă���ꍇ�AComposer���o�͂����e��`���t�@�C���̉�͌��ʂ�(�g�p�\�Ȃ��)��͍ς݂̃I�u�W�F�N�g�ő�ւ���B
#  (true�𐄏�)
#  �g�p�\�ł�������͈ȉ��̂Ƃ���B
#  - ���ɉ�͍ς݂̏��cache����Ă��邱�ƁB
#  - ���ɉ�͍ς݂̏��ƁA����w�肵����`���̓��e������ł��邱�ƁB
#- faces:
#  �o�͂Ɏg�p����face(face��prep��Key�Ƃ��Ď���Hash)�̔z������ҁBfaces�ȉ��Ɋi�[���ꂽface�����ɏo�͂���B
#  - face:
#    �o�͂Ɏg�p����face�̖��̂𕶎���Ŏw�肵�܂��B�ǂ̂悤��face���g�p�\���́Aface�f�B���N�g���ȉ����Q�Ƃ��Ă��������B
#    �g�ݍ��݂�face�ɂ��ẮA�ȉ���3��̂����ꂩ�ł��B
#    * default_face
#    * stream_plan
#    * jobnet
#  - prep:
#    face�̏o�͊J�n�O��face�I�u�W�F�N�g�ɗ^���鎖�O���������A���\�b�h���A�����~n�̏��Ɏw�肵�܂��B
#    �����́A�������face���g�p���邩�ɂ��قȂ��Ă��܂��B�g�ݍ���Face�̂����Adefault_face��prep��v���܂��񂪁Astream_plan��range_set���K���K�v�ł��B
#    �܂��Ajobnet�͍ő�4��prep���w��ł��܂����A������K�{�ł͂���܂���B�ڍׂ͊eFace�̐������Q�l�ɂ��Ă��������B
#    * Composer::Face::DefaultFace
#    * Composer::Face::StreamPlan
#    * Composer::Face::Jobnet
#
#===XML�`���̍\���t�@�C������
#�J�������́A�\���t�@�C���Ƃ���YAML�`���݂̂��̗p���Ă��܂������A
#�f�[�^�̓���q�֌W�̕�����₷���A�����e���₷��(�Ō��ʂ͕ʂƂ���)�A�F�m�x���l�����āA
#XML�`���̍\���t�@�C���������\�Ƃ��܂����B
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
#����Ε�����Ƃ����������������Ǝv���܂��̂ŁA�ڍׂ͊������܂��B
#
#==== Meanings...
#��L2��̃T���v���\���t�@�C���̈Ӗ��͈ȉ��̂悤�ɂȂ�܂��B
#1. calendars,jobs,parameters,prompts,resources,schedules,workstations �̒�`���͊e�X�w�肳�ꂽ�p�X�̃t�@�C�����g�p����B
#2. ��L�t�@�C���̉�͌��ʂ�p���āA3��ނ�face�ŏo�͂���B
#3. �ŏ��ɁA'default_face'��p���ďo�͂���B���ɁA�o�͑O�̏���(prep:)�����B
#4. ����'stream_plan'��p���ďo�͂���B�o�͑O�̏���(prep:)�Ƃ���StreamPlan��range_set���\�b�h�Ɉ���2006-01-01,2006-02-01��n���B
#5. �Ō��'jobnet'��p���ďo�͂���B�o�͑O�̏���(prep:)�Ƃ���
#   * �o�̓t�@�C���t�H�[�}�b�g(outformat=)��svg�ɐݒ�
#   * �ΏۃW���u�X�g���[�����AS2_JBAU������S2_JBA�n�܂�AS2_JBT.*�AS2_JBI.*�AS2_JBX.*�݂̂Ƀt�B���^�����O(stream_filter=)
#   * �o�͑ΏۂƂ��āAREQUEST�݂̂̃W���u�X�g���[���͑ΏۂƂ��Ȃ��B(draw_only_request= "false")
#6. �S�̂Ƃ��ă��O���x����2(Warning�͏o��)
#7. �L���b�V�����g�p�\�Ȃ�Ύg�p����B
class UserInterface
	include Composer

	def initialize(conf_path,conf_format) #:nodoc:
		@ap=FrontEnd.new
		@conf_path=conf_path
		@conf_format=conf_format
	end

	def run #:nodoc:
		unless @conf_format
			# �I�v�V�����Ńt�H�[�}�b�g���w�肳��Ă��Ȃ��ꍇ�ɂ͊g���q���画�f
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
		# �e�X�擪1���̂ݎ擾(�����)
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

