require 'erb'

module Composer::Face
	#= DefaultFace
	#組み込みのデフォルトのFace
	#Excel等で読み込むことを前提としたCSVフォーマットで一覧表を出力する。
	class DefaultFace
		include Composer::BaseMake
		
		#利用可能なテンプレートとその依存するパース結果のテーブル
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
		
		#DefautlFace#on_setup はinitialize時に呼び出される。
		def on_setup
			@templates=[]
		end

		#フォーマットに使用するテンプレートを指定する。
		#テンプレートとして有効な値は以下のとおり。
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

		#formatメソッドはFaceクラスで備えなければならないメソッド。
		#FrontEnd#convert時に、各Faceクラスのformatメソッドが呼び出される。
		#DefaultFace#formatは、事前にadd_templateで指定されたテンプレートを用いて、
		#フォーマット変換を行い、ファイルサフィックスを.csvしたファイルに出力する。
		def format
			@templates=VALID_TEMPLATES.keys if @templates.empty?
			@templates.each{|tmpl|
				@logger.info("#{self.class}"){"processing with template [ #{tmpl} ]."}
				erb_template="#{@my_dir}/#{tmpl}.erb"
				output_file ="#{@outfiles_dir}/#{tmpl}.csv"
				#依存関係の確認
				if VALID_TEMPLATES[tmpl].any?{|dep| self.__send__(dep).empty? }
					@logger.warn("#{self.class}"){"template [ #{tmpl} ] needs [ #{VALID_TEMPLATES[tmpl].join(' ')} ], but was empty. (ignore)"}
				else
					#依存関係OKの場合
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

