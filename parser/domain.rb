
module Composer::TwsObj
	#= Domain
	#ドメインを表現するクラス。
	#
	#属性として以下を持つ。
	#- ドメイン名(name)
	#- 説明(description)
	#- ドメインマネージャ名(manager)
	#- 親ドメインの名称(parent)
	class Domain
		extend ::Composer::SensitiveAttr

		def initialize
			@name=nil
			@description=nil
			@manager=nil
			@parent=nil
			@logger=::Composer::SingletonLogger.instance
		end
		sensitive_accessor :name, :description, :manager, :parent

		#必須のドメイン名、ドメインマネージャ名が設定されているか?
		def set_enough?
			@name && @manager
		end
	end
end
