require 'erb'

module Composer::Face
	#= DefaultFace
	#�g�ݍ��݂̃f�t�H���g��Face
	#Excel���œǂݍ��ނ��Ƃ�O��Ƃ���CSV�t�H�[�}�b�g�ňꗗ�\���o�͂���B
	class DefaultFace
		include Composer::BaseMake
		
		#���p�\�ȃe���v���[�g�Ƃ��̈ˑ�����p�[�X���ʂ̃e�[�u��
		VALID_TEMPLATES={
			"default_calendar" => [:calendars],
			"default_cpuclass" => [:cpuclasses],
			"default_cpuname" => [:cpunames],
			"default_domain" => [:domains],
			"default_job" => [:jobs],
			"default_parameter" => [:parameters],
			"default_prompt" => [:prompts],
			"default_resource" => [:resources],
			"default_schedule" => [:schedules]
		}
		
		#DefautlFace#on_setup ��initialize���ɌĂяo�����B
		def on_setup
			@templates=[]
		end

		#�t�H�[�}�b�g�Ɏg�p����e���v���[�g���w�肷��B
		#�e���v���[�g�Ƃ��ėL���Ȓl�͈ȉ��̂Ƃ���B
		#- default_calendar
		#- default_cpuclass
		#- default_cpuname
		#- default_domain
		#- default_job
		#- default_parameter
		#- default_prompt
		#- default_resource
		#- default_schedule
		def add_template(*tmpls)
			tmpls.each{|tmpl|
				if VALID_TEMPLATES.keys.include? tmpl.downcase
					@logger.info("#{self.class}"){"template [ #{tmpl} ] is set."}
					@templates.push tmpl.downcase
				else
					@logger.warn("#{self.class}"){"template should [ #{valid_templates.join(' ')} ],but was [ #{tmpl} ]"}
				end
			}
			@templates.flatten!
		end

		#format���\�b�h��Face�N���X�Ŕ����Ȃ���΂Ȃ�Ȃ����\�b�h�B
		#FrontEnd#convert���ɁA�eFace�N���X��format���\�b�h���Ăяo�����B
		#DefaultFace#format�́A���O��add_template�Ŏw�肳�ꂽ�e���v���[�g��p���āA
		#�t�H�[�}�b�g�ϊ����s���A�t�@�C���T�t�B�b�N�X��.csv�����t�@�C���ɏo�͂���B
		def format
			@templates=VALID_TEMPLATES.keys if @templates.empty?
			@templates.each{|tmpl|
				@logger.info("#{self.class}"){"processing with template [ #{tmpl} ]."}
				erb_template="#{@my_dir}/#{tmpl}.erb"
				output_file ="#{@outfiles_dir}/#{tmpl}.csv"
				#�ˑ��֌W�̊m�F
				if VALID_TEMPLATES[tmpl].any?{|dep| self.__send__(dep).empty? }
					@logger.warn("#{self.class}"){"template [ #{tmpl} ] needs [ #{VALID_TEMPLATES[tmpl].join(' ')} ], but was empty. (ignore)"}
				else
					#�ˑ��֌WOK�̏ꍇ
					if File.file?(erb_template)
						format=File.read(erb_template)
						File.open(output_file,'w'){|f| f.puts ERB.new(format,0,"-").result(binding) }
					else
						@logger.error("#{self.class}"){"template file [ #{erb_template} ] does not exist."}
					end
				end
			}
		end
	end
end

