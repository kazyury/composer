#
# DO NOT MODIFY!!!!
# This file is automatically generated by racc 1.4.5
# from racc grammer file "job_parser82.y".
#

require 'racc/parser'


module Composer

  module Parser

    class JobParser < Racc::Parser

##### racc 1.4.5 generates ###

racc_reduce_table = [
 0, 0, :racc_error,
 2, 17, :_reduce_none,
 0, 18, :_reduce_none,
 2, 18, :_reduce_none,
 2, 19, :_reduce_4,
 1, 20, :_reduce_5,
 3, 20, :_reduce_6,
 1, 21, :_reduce_none,
 2, 21, :_reduce_none,
 2, 22, :_reduce_9,
 2, 22, :_reduce_10,
 2, 22, :_reduce_11,
 2, 22, :_reduce_12,
 2, 22, :_reduce_13,
 2, 22, :_reduce_14,
 2, 22, :_reduce_15,
 1, 22, :_reduce_16,
 2, 22, :_reduce_17,
 4, 22, :_reduce_18,
 0, 23, :_reduce_none,
 2, 23, :_reduce_20,
 4, 23, :_reduce_21,
 0, 24, :_reduce_none,
 2, 24, :_reduce_23 ]

racc_reduce_n = 24

racc_shift_n = 38

racc_action_table = [
    13,    14,    15,     1,    16,    17,    10,    12,    13,    14,
    15,    21,    16,    17,    10,    12,    20,    26,    22,    23,
    19,     8,    25,     5,    24,     9,    27,    28,     4,    31,
    32,    34,    35,    36,    37 ]

racc_action_check = [
     7,     7,     7,     0,     7,     7,     7,     7,    18,    18,
    18,    10,    18,    18,    18,    18,    10,    14,    12,    12,
     9,     4,    14,     3,    13,     5,    16,    17,     2,    28,
    30,    31,    32,    34,    36 ]

racc_action_pointer = [
    -1,   nil,    28,     9,    21,    10,   nil,    -5,   nil,     6,
     3,   nil,     5,    11,     9,   nil,    13,    13,     3,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,    26,   nil,
    28,    17,    19,   nil,    18,   nil,    20,   nil ]

racc_action_default = [
   -24,    -2,   -24,    -1,   -24,    -5,    -3,   -24,    38,   -24,
   -24,    -7,   -24,   -24,   -24,   -16,   -24,   -24,    -4,    -6,
   -10,    -9,   -14,   -13,   -15,   -11,   -12,   -17,   -19,    -8,
   -22,   -24,   -24,   -18,   -20,   -23,   -24,   -21 ]

racc_goto_table = [
    11,    18,     6,     7,     3,     2,    30,    33,   nil,   nil,
   nil,    29 ]

racc_goto_check = [
     6,     5,     3,     4,     2,     1,     7,     8,   nil,   nil,
   nil,     6 ]

racc_goto_pointer = [
   nil,     5,     3,    -1,     0,    -6,    -7,   -22,   -23 ]

racc_goto_default = [
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil ]

racc_token_table = {
 false => 0,
 Object.new => 1,
 :ABENDPROMPT => 2,
 :AFTER => 3,
 :DECLARE => 4,
 :DESCRIPTION => 5,
 :DOCOMMAND => 6,
 :INTERACTIVE => 7,
 :PATH => 8,
 :RCCONDSUCC => 9,
 :RECOVERY => 10,
 :SCRIPTNAME => 11,
 :STREAMLOGON => 12,
 :STRING => 13,
 :WORD => 14,
 "#" => 15 }

racc_use_result_var = true

racc_nt_base = 16

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
'ABENDPROMPT',
'AFTER',
'DECLARE',
'DESCRIPTION',
'DOCOMMAND',
'INTERACTIVE',
'PATH',
'RCCONDSUCC',
'RECOVERY',
'SCRIPTNAME',
'STREAMLOGON',
'STRING',
'WORD',
'"#"',
'$start',
'jobs',
'stmts',
'job',
'name',
'jobdescs',
'jobdesc',
'rcvjobstmt',
'rcvprmptstmt']

Racc_debug_parser = true

##### racc system variables end #####

 # reduce 0 omitted

 # reduce 1 omitted

 # reduce 2 omitted

 # reduce 3 omitted

module_eval <<'.,.,', 'job_parser82.y', 16
  def _reduce_4( val, _values, result )
								@logger.warn("#{self.class}"){ "JOB is not set enough. [ #{@job.inspect} ]"} unless @job.set_enough?
								@logger.info("#{self.class}"){ "JOB [ #{@job.name} ] was reduced." }
								@jobs.push @job
								@job=::Composer::TwsObj::Job.new
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 18
  def _reduce_5( val, _values, result )
 @job.name = val[0]
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 25
  def _reduce_6( val, _values, result )
								@job.wkstation = val[0]
								@job.name = val[2]
								result=val.join('')
   result
  end
.,.,

 # reduce 7 omitted

 # reduce 8 omitted

module_eval <<'.,.,', 'job_parser82.y', 30
  def _reduce_9( val, _values, result )
 @job.scriptname = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 32
  def _reduce_10( val, _values, result )
 @job.scriptname = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 34
  def _reduce_11( val, _values, result )
 @job.docommand = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 36
  def _reduce_12( val, _values, result )
 @job.docommand = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 38
  def _reduce_13( val, _values, result )
 @job.streamlogon = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 40
  def _reduce_14( val, _values, result )
 @job.streamlogon = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 42
  def _reduce_15( val, _values, result )
 @job.description = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 44
  def _reduce_16( val, _values, result )
 @job.interactive=true
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 46
  def _reduce_17( val, _values, result )
 @job.rccondsucc=val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 48
  def _reduce_18( val, _values, result )
 @job.recovery = is_valid?(['STOP','CONTINUE','RERUN'],val[1])
   result
  end
.,.,

 # reduce 19 omitted

module_eval <<'.,.,', 'job_parser82.y', 52
  def _reduce_20( val, _values, result )
 @job.recovery_job_name = val[1]
   result
  end
.,.,

module_eval <<'.,.,', 'job_parser82.y', 58
  def _reduce_21( val, _values, result )
								@job.recovery_job_wkstation = val[1]
								@job.recovery_job_name = val[3]
   result
  end
.,.,

 # reduce 22 omitted

module_eval <<'.,.,', 'job_parser82.y', 61
  def _reduce_23( val, _values, result )
 @job.abendprompt = val[1]
   result
  end
.,.,

 def _reduce_none( val, _values, result )
  result
 end

    end   # class JobParser

  end   # module Parser

end   # module Composer
