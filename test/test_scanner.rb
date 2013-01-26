#!ruby

$:.unshift('..')
require 'test/unit'
require 'racc/parser'
require 'singleton_logger'
require 'errors'
require 'utils'
require 'scanner/generic_scanner'
require 'scanner/mode_switchable_scanner'

class TestScanner < Test::Unit::TestCase
	include Composer::ParserUtils
  def setup
		logger=Composer::SingletonLogger.instance
		logger.level=Logger::DEBUG
  end

	# basically,target mode is :DEFAULT
  def test_scanner_001
		infile='./testdata/mode_switchable_scanner.in.0001'
    scanner = Composer::Scanner::ModeSwitchableScanner.new(infile,self)
		assert_equal(:DEFAULT,scanner.mode)

		scanner.append_tokens(/\A\*.*?$/          ,:LINECOMMENT) # schedule �ł͍s�R�����g���ӎ�����B
		assert_equal([[/\A\*.*?$/,:LINECOMMENT,false]],scanner.mode_frame[:DEFAULT])

		scanner.reserved_word(false,"ABENDPROMPT")
		assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(ABENDPROMPT)[^\w-]/i,:ABENDPROMPT,true]],scanner.mode_frame[:DEFAULT])

		scanner.builtin_token(:WORD)
		assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(ABENDPROMPT)[^\w-]/i,:ABENDPROMPT,true],[/\A[\w\-]+/,:WORD,false]],scanner.mode_frame[:DEFAULT])
  end

	# with mode_switchable_scanner.on(:mode){|s| ... }
	# you can choose a mode to regist tokens.
  def test_scanner_002
		infile='./testdata/mode_switchable_scanner.in.0001'
    scanner = Composer::Scanner::ModeSwitchableScanner.new(infile,self)
		assert_equal(:DEFAULT,scanner.mode)

		scanner.append_tokens(/\A\*.*?$/,:LINECOMMENT)
		assert_equal([[/\A\*.*?$/,:LINECOMMENT,false]],scanner.mode_frame[:DEFAULT])

		scanner.on(:ANOTHER_MODE){|s|
			assert_equal(:ANOTHER_MODE,s.mode)
			# �V�������[�h�̏ꍇ�ɂ�:DEFAULT���R�s�[�B
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false]],scanner.mode_frame[:DEFAULT])
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false]],scanner.mode_frame[:ANOTHER_MODE])

			s.reserved_word(false,"ABENDPROMPT")
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false]],scanner.mode_frame[:DEFAULT])
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(ABENDPROMPT)[^\w-]/i,:ABENDPROMPT,true]],scanner.mode_frame[:ANOTHER_MODE])
		}

		scanner.on(:YAMODE){|s|
			assert_equal(:YAMODE,s.mode)
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false]],scanner.mode_frame[:DEFAULT])
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(ABENDPROMPT)[^\w-]/i,:ABENDPROMPT,true]],scanner.mode_frame[:ANOTHER_MODE])
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false]],scanner.mode_frame[:YAMODE])

			s.reserved_word(false,"HI")
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false]],scanner.mode_frame[:DEFAULT])
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(ABENDPROMPT)[^\w-]/i,:ABENDPROMPT,true]],scanner.mode_frame[:ANOTHER_MODE])
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(HI)[^\w-]/i,:HI,true]],scanner.mode_frame[:YAMODE])
		}

		# on �����w��̏ꍇ�ɂ�:DEFAULT���g�p�B
		scanner.on(){|s|
			assert_equal(:DEFAULT,s.mode)
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false]],scanner.mode_frame[:DEFAULT])
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(ABENDPROMPT)[^\w-]/i,:ABENDPROMPT,true]],scanner.mode_frame[:ANOTHER_MODE])
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(HI)[^\w-]/i,:HI,true]],scanner.mode_frame[:YAMODE])

			# :DEFAULT�֒ǉ��������e�͑���Frame�ɂ��ǉ�����B
			s.reserved_word(false,"GO")
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(GO)[^\w-]/i,:GO,true]],scanner.mode_frame[:DEFAULT])
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(ABENDPROMPT)[^\w-]/i,:ABENDPROMPT,true],[/\A(GO)[^\w-]/i,:GO,true]],scanner.mode_frame[:ANOTHER_MODE])
			assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A(HI)[^\w-]/i,:HI,true],[/\A(GO)[^\w-]/i,:GO,true]],scanner.mode_frame[:YAMODE])
		}
  end

	# now,let's scan.
  def test_scanner_003
		infile='./testdata/mode_switchable_scanner.in.0001'
    scanner = Composer::Scanner::ModeSwitchableScanner.new(infile,self)
		scanner.on(:COMMENTABLE){|s|
			s.append_tokens(/\A\*.*?$/,:LINECOMMENT)
		}
		scanner.append_tokens(/\A\*.*?$/) # on���g��Ȃ��ꍇ�ɂ�:DEFAULT�B(�ǂݔ�΂��ΏہB)
		assert_equal([[/\A\*.*?$/,:LINECOMMENT,false],[/\A\*.*?$/,nil,false]],scanner.mode_frame[:COMMENTABLE])
		assert_equal([[/\A\*.*?$/,nil,false]],scanner.mode_frame[:DEFAULT])
		scanner.append_tokens(/\A\s+/)
		scanner.append_tokens(/\A<<(.+?)>>/)		# << >> �`���̓R�����g
		scanner.append_tokens(/\A\w+/,:WORD)

		# :DEFAULT���[�h�̂܂܂̏ꍇ�A�s�R�����g��ǂݔ�΂��̂ōŏ��̃g�[�N���́A:WORD(schedule)�ɂȂ�
		assert_equal(:DEFAULT,scanner.mode)
		stuck=[]
		scanner.scan{|token,val| stuck.push [token,val] }
		assert_equal(:WORD,stuck[0][0])
		assert_equal('schedule',stuck[0][1])
  end
	
	# now,let's scan part2.
  def test_scanner_004
		infile='./testdata/mode_switchable_scanner.in.0001'
    scanner = Composer::Scanner::ModeSwitchableScanner.new(infile,self)
		scanner.on(:COMMENTABLE){|s|
			s.append_tokens(/\A\*.*?$/,:LINECOMMENT)
		}
		scanner.append_tokens(/\A\*.*?$/) # on���g��Ȃ��ꍇ�ɂ�:DEFAULT�B(�ǂݔ�΂��ΏہB)
		scanner.append_tokens(/\A\s+/)
		scanner.append_tokens(/\A<<(.+?)>>/)		# << >> �`���̓R�����g
		scanner.append_tokens(/\A\w+/,:WORD)

		# :COMMENTABLE���[�h�͍s�R�����g�𖳎����Ȃ��̂ŁA�ŏ��̃g�[�N���́A:LINECOMMENT�ɂȂ�
		scanner.switch(:COMMENTABLE)
		assert_equal(:COMMENTABLE,scanner.mode)
		stuck=[]
		scanner.scan{|token,val| stuck.push [token,val] }
		assert_equal(:LINECOMMENT,stuck[0][0])
		assert_equal('****************************************',stuck[0][1])
		assert_equal(:LINECOMMENT,stuck[13][0])
		assert_equal('* This comment is to be ignored',stuck[13][1])
  end
	
	# now,let's scan part3. switch mode with scan progressing
  def test_scanner_005
		infile='./testdata/mode_switchable_scanner.in.0001'
    scanner = Composer::Scanner::ModeSwitchableScanner.new(infile,self)
		scanner.on(:COMMENTABLE){|s|
			s.append_tokens(/\A\*.*?$/,:LINECOMMENT)
		}
		scanner.append_tokens(/\A\*.*?$/) # on���g��Ȃ��ꍇ�ɂ�:DEFAULT�B(�ǂݔ�΂��ΏہB)
		scanner.append_tokens(/\A\s+/)
		scanner.append_tokens(/\A<<(.+?)>>/)		# << >> �`���̓R�����g
		scanner.append_tokens(/\A\w+/,:WORD)

		# �ŏ���COMMENTABLE�ŁBSCHEDULE��ǂݍ��񂾂�FDEFAULT�ɁB
		# �㔼�̍s�R�����g�͖�������邱�ƂɂȂ�B
		scanner.switch(:COMMENTABLE)
		assert_equal(:COMMENTABLE,scanner.mode)
		stuck=[]
		scanner.scan{|token,val| 
			scanner.switch(:DEFAULT) if val=='schedule'
			scanner.switch(:COMMENTABLE) if val=='end'
			stuck.push [ token, val ]
		}
		assert_equal(:COMMENTABLE,scanner.mode)

		assert_equal(:LINECOMMENT,stuck[0][0])
		assert_equal('****************************************',stuck[0][1])
		assert_not_equal(:LINECOMMENT,stuck[13][0])
		assert_not_equal('* This comment is to be ignored',stuck[13][1])
  end
end
