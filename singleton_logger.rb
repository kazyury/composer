
require 'singleton'
require 'forwardable'
require 'logger'

module Composer
	# Composer�̊e�����ŋ��ʂŎg�p����Logger�C���^�t�F�[�X
	# Singleton�Ȃ̂őS������1��Logger�I�u�W�F�N�g���Q�Ƃ���B
	# ( �g�����̗� )
	#		Class Hoge
	#			def initialize
	#				@logger=SingletonLogger.instance  <------+
	#			end                                        |
	#		end                                          |
	#		attr_reader :logger                          |
	# 	                                             |����̃C���X�^���X���w���B 
	#		class Foo                                    |
	#			def initialize                             |
	#				@logger=SingletonLogger.instance  <------+
	#			end
	#		end
	#		attr_reader :logger
	#
	#		hogelogger=Hoge.new.logger
	#		foo_logger=Foo.new.logger
	#
	#		hogelogger.level=Logger::FATAL #=>foo_logger�̃��O���x����FATAL�ɕύX
	class SingletonLogger
		include Singleton
		extend Forwardable
		
		def initialize
			@logger=Logger.new(STDOUT)
		end

		def_delegators(:@logger,"datetime_format","datetime_format=")
		def_delegators(:@logger,"debug?","info?","warn?","error?","fatal?","debug","info","warn","error","fatal")
		def_delegators(:@logger,"level","level=","sev_threshold","sev_threshold=","progname","progname=" )

		def _dump(l); ''; end
		def self._load(obj)
			self.instance
		end

	end
end

