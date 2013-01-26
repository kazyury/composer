
module Composer::TwsObj
	#= CpuName
	#単一のワークステーションを表現するクラス。
	#
	#属性として以下を持つ。
	#- ワークステーション名(name)
	#- 説明(description)
	#- OSのタイプ(os)
	#- ホスト名又はIPアドレス(node)
	#- スケジューラーがワークステーション上での通信に使用するTCPポート番号(tcpaddr)
	#- 着信SSL接続をlistenするのに使用されるポート(secureaddr)
	#- ワークステーションの時間帯(timezone)
	#- ワークステーションのスケジューラー・ドメイン名(domain)
	#- エージェントのホスト・ワークステーションの名前(host)
	#- 拡張エージェントとネットワーク・エージェントのアクセス方式(access)
	#- ワークステーションのタイプ(type)
	#- ワークステーション定義を無視するか否か(ignore)
	#- 始動時にワークステーション間のリンクを開くかどうか(autolink)
	#- ワークステーションとマスター・ドメイン・マネージャーとの間にファイアウォールが存在するか否か(behindfirewall)
	#- エージェントが完全状況または部分状況のどちらで更新されるか(fullstatus)
	#- ワークステーションの SSL 認証のタイプ(securitylevel)
	#- エージェントがすべての依存関係を追跡するのか否か(resolvedep)
	#- エージェントとの通信を扱うための、ドメイン・マネージャーのMailmanサーバーID(server)
	class CpuName
		extend ::Composer::SensitiveAttr

		def initialize
			@name=nil
			@description=nil
			@os=nil
			@node=nil
			@tcpaddr=nil
			@secureaddr=nil
			@timezone=nil
			@domain=nil
			@host=nil
			@access=nil
			@type=nil
			@ignore=nil
			@autolink=nil
			@behindfirewall=nil
			@fullstatus=nil
			@resolvedep=nil
			@server=nil
			@securitylevel=nil
			@logger=::Composer::SingletonLogger.instance
		end
		sensitive_accessor :secureaddr, :name, :description, :os, :node, :tcpaddr, :timezone, :domain, :host, :access, :type, :ignore, :autolink, :fullstatus, :resolvedep, :server, :behindfirewall, :securitylevel

		#ignoreが指定されていたらtrue
		def ignore?
			@ignore ? true : false
		end

		# autolinkがONで定義されていたらtrue
		def autolink?
			return false unless @autolink
			@autolink.upcase=='ON' ? true : false
		end

		# behindfirewallがONで定義されていたらtrue
		def behindfirewall?
			return false unless @behindfirewall
			@behindfirewall.upcase=='ON' ? true : false
		end

		# fullstatusがONで定義されていたらtrue
		def fullstatus?
			return false unless @fullstatus
			@fullstatus.upcase=='ON' ? true : false
		end

		# resolvedepがONで定義されていたらtrue
		def resolvedep?
			return false unless @resolvedep
			@resolvedep.upcase=='ON' ? true : false
		end

		#必須のワークステーション名、OSタイプ、ホスト名が設定されているか?
		def set_enough?
			@name && @os && @node
		end
	end
end

