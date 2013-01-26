#
# DO NOT MODIFY!!!!
# This file is automatically generated by racc 1.4.5
# from racc grammer file "parameter_parser82.y".
#

require 'racc/parser'


module Composer

  module Parser

    class ParameterParser < Racc::Parser

##### racc 1.4.5 generates ###

racc_reduce_table = [
 0, 0, :racc_error,
 2, 6, :_reduce_none,
 0, 7, :_reduce_none,
 2, 7, :_reduce_none,
 2, 8, :_reduce_4,
 1, 9, :_reduce_5,
 1, 10, :_reduce_6 ]

racc_reduce_n = 7

racc_shift_n = 11

racc_action_table = [
     1,     4,     5,     8,     9 ]

racc_action_check = [
     0,     2,     3,     4,     7 ]

racc_action_pointer = [
    -2,   nil,     1,    -2,     3,   nil,   nil,     1,   nil,   nil,
   nil ]

racc_action_default = [
    -7,    -2,    -7,    -1,    -7,    -5,    -3,    -7,    11,    -6,
    -4 ]

racc_goto_table = [
     2,     3,     6,     7,    10 ]

racc_goto_check = [
     1,     2,     3,     4,     5 ]

racc_goto_pointer = [
   nil,     0,     0,    -1,     0,    -3 ]

racc_goto_default = [
   nil,   nil,   nil,   nil,   nil,   nil ]

racc_token_table = {
 false => 0,
 Object.new => 1,
 :DECLARE => 2,
 :STRING => 3,
 :WORD => 4 }

racc_use_result_var = true

racc_nt_base = 5

Racc_arg = [
 racc_action_table,
 racc_action_check,
 racc_action_default,
 racc_action_pointer,
 racc_goto_table,
 racc_goto_check,
 racc_goto_default,
 racc_goto_pointer,
 racc_nt_base,
 racc_reduce_table,
 racc_token_table,
 racc_shift_n,
 racc_reduce_n,
 racc_use_result_var ]

Racc_token_to_s_table = [
'$end',
'error',
'DECLARE',
'STRING',
'WORD',
'$start',
'params',
'stmts',
'param',
'name',
'value']

Racc_debug_parser = true

##### racc system variables end #####

 # reduce 0 omitted

 # reduce 1 omitted

 # reduce 2 omitted

 # reduce 3 omitted

module_eval <<'.,.,', 'parameter_parser82.y', 16
  def _reduce_4( val, _values, result )
							@logger.warn("#{self.class}"){ "PARAMETER is not set enough. [ #{@parameter.inspect} ]"} unless @parameter.set_enough?
							@logger.info("#{self.class}"){ "PARAMETER [ #{@parameter.name} ] was reduced." }
							@parameters.push @parameter
							@parameter=::Composer::TwsObj::Parameter.new
   result
  end
.,.,

module_eval <<'.,.,', 'parameter_parser82.y', 18
  def _reduce_5( val, _values, result )
 @parameter.name=val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'parameter_parser82.y', 21
  def _reduce_6( val, _values, result )
 @parameter.value=val[0]
   result
  end
.,.,

 def _reduce_none( val, _values, result )
  result
 end

    end   # class ParameterParser

  end   # module Parser

end   # module Composer