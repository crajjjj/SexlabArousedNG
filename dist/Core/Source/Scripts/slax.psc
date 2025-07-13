Scriptname slax
import Debug

Function WriteLog(String asMessage, Int aiPriority = 0) Global
	String asModName = "SLOANG"
	Utility.SetINIBool("bEnableTrace:Papyrus", true)
	if OpenUserLog(asModName)
		Debug.Trace(asModName + " Debugging Started.")
		Debug.TraceUser(asModName,"[---"+ asModName +" DEBUG LOG STARTED---]")
	endif
	String sPrefix
	if aiPriority == 2
		sPrefix = "(!ERROR!) "
	elseif aiPriority == 1
		sPrefix = "(!) "
	else
		sPrefix = "(i) "
	endif

	asMessage = sPrefix + asMessage
	
	Debug.TraceUser(asModName, asMessage, aiPriority)
EndFunction

Bool Function DebugSpam_IsEnabled() Global
    Int enabled = StorageUtil.GetIntValue(None, "slax_EnableDebugSpam")
    Return 0 != enabled
EndFunction

Int Function DebugSpam_GetSeverity() Global
    Return StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127)
EndFunction


Function DebugSpam_SetInfo() Global
    StorageUtil.SetIntValue(None, "slax_EnableDebugSpam", 1)
    StorageUtil.SetIntValue(None, "slax_TraceSpamSeverity", 0)
EndFunction

Function DebugSpam_SetWarning() Global
    StorageUtil.SetIntValue(None, "slax_EnableDebugSpam", 1)
    StorageUtil.SetIntValue(None, "slax_TraceSpamSeverity", 1)
EndFunction

Function DebugSpam_SetError() Global
    StorageUtil.SetIntValue(None, "slax_EnableDebugSpam", 1)
    StorageUtil.SetIntValue(None, "slax_TraceSpamSeverity", 2)
EndFunction

Function DebugSpam_SetAlert() Global
    StorageUtil.SetIntValue(None, "slax_EnableDebugSpam", 1)
    StorageUtil.SetIntValue(None, "slax_TraceSpamSeverity", 3)
EndFunction

Function DebugSpam_Off_AlertsOn() Global
    StorageUtil.SetIntValue(None, "slax_EnableDebugSpam", 0)
    StorageUtil.SetIntValue(None, "slax_TraceSpamSeverity", 3)
EndFunction

Function DebugSpam_Off() Global
    StorageUtil.SetIntValue(None, "slax_EnableDebugSpam", 0)
    StorageUtil.SetIntValue(None, "slax_TraceSpamSeverity", 4)
EndFunction


Function EnableDebugSpam(Bool enable) Global
    StorageUtil.SetIntValue(None, "slax_EnableDebugSpam", enable as Int)
EndFunction

Function Notify(String txtMsg) Global
	If StorageUtil.GetIntValue(None, "slax_EnableDebugSpam")
		Debug.Notification(txtMsg)
	EndIf
EndFunction

Function MessageBox(String txtMsg) Global
	If StorageUtil.GetIntValue(None, "slax_EnableDebugSpam")
		Debug.MessageBox(txtMsg)
	EndIf
EndFunction


; Debug Trace severity levels:
; 0: info, 1: warning, 2: error, (3: alert - not a Bethesda value)
; Only messages of at least enabled level are logged.
;
Function EnableTraceSpam(int severity = 0) Global
    StorageUtil.SetIntValue(None, "slax_TraceSpamSeverity", severity)
EndFunction

Function DisableTraceSpam() Global
    StorageUtil.SetIntValue(None, "slax_TraceSpamSeverity", 127)
EndFunction

Function Trace(Int severity, String txtMsg) Global
	If severity >= StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127)
        WriteLog(txtMsg)
    EndIf
EndFunction

; Yes, I know these messages are severity filtered twice as implemented. (tdt?)
; This allows Debug.Trace to be swapped for direct file logging, or a text buffer, or anything you like without changing the callers.
Function Info(String txtMsg) Global
	; If StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127) <= 0
    ;     WriteLog(txtMsg)
    ; EndIf
    WriteLog(txtMsg)
EndFunction

Function InfoConditional(String txtMsg, Bool condition) Global
	If condition && StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127) <= 0
        WriteLog(txtMsg)
    EndIf
EndFunction

Function Warning(String txtMsg) Global
	; If StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127) <= 1
    ;    WriteLog(txtMsg,1)
    ; EndIf
    WriteLog(txtMsg,1)
EndFunction

Function WarningConditional(String txtMsg, Bool condition) Global
	If condition && StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127) <= 1
       WriteLog(txtMsg,1)
    EndIf
EndFunction

Function Error(String txtMsg) Global
	; If StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127) <= 2
    ;     WriteLog(txtMsg,2)
    ; EndIf
     WriteLog(txtMsg,2)
EndFunction

Function ErrorConditional(String txtMsg, Bool condition) Global
	If condition && StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127) <= 2
        WriteLog(txtMsg,2)
    EndIf
EndFunction

Function Spam(String txtMsg) Global
    WriteLog(txtMsg)
EndFunction

Function Alert(String txtMsg) Global
    If StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127) <= 3
        WriteLog(txtMsg,2)
        Debug.MessageBox(txtMsg)
    EndIf
EndFunction

Function AlertConditional(String txtMsg, Bool condition) Global
    If condition && StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127) <= 3
        WriteLog(txtMsg,2)
        Debug.MessageBox(txtMsg)
    EndIf
EndFunction

Function DumpStackConditional(String txtMsg, Bool condition) Global ; Must set info level to see these
    If condition && StorageUtil.GetIntValue(None, "slax_TraceSpamSeverity", 127) <= 0
        Debug.TraceStack(txtMsg, 2)
    EndIf
EndFunction

String Function FormatFloat_N2(Float value) Global
    Return FormatDecimal_x100((value * 100) as Int)
EndFunction

String Function FormatFloat_N1(Float value) Global
    Return FormatDecimal_x10((value * 10) as Int)
EndFunction

String Function FormatFloat_N0(Float value) Global
    Return "" + ((value+0.5) as Int)
EndFunction

String Function FormatFloatPercent_N0(Float value) Global
    Return "" + ((value+0.5) as Int) + "%"
EndFunction

String Function FormatFloatPercent_N1(Float value) Global
    Return FormatDecimal_x10((value * 10) as Int) + "%"
EndFunction



; Format single-digit fixed point integer as string.
String Function FormatDecimal_x10(Int value) Global
{Format an integer in fixed point format with a single digit of precision.}

    String sign = ""
    If value < 0
        sign = "-"
        value = -value
    EndIf
    
	Int x10 = value / 10
	Int remainder = value - (x10 * 10)
	
	return sign + (x10 as String) + "." + remainder
	
EndFunction


; Format two-digit fixed point integer as string.
String Function FormatDecimal_x100(Int value) Global
{Format an integer in fixed point format with two digits of precision.}

    String sign = ""
    If value < 0
        sign = "-"
        value = -value
    EndIf
    
	Int x10 = value / 10  ; e.g. 12456 => 12345
	Int x100 = x10 / 10   ; 123456 => 1234
	Int remainder1 = value - (x10 * 10) ; 123456 - 123450
	Int remainder2 = x10 - (x100 * 10) ; 12345 - 12340
	
	return sign + (x100 as String) + "." + remainder2 + remainder1
	
EndFunction


; Format integer  with at least two digits, add leading zero if needed.
String Function FormatDecimal_00(Int value) Global

    String out = ""
    If value < 0
        out = "-"
        value = -value
    EndIf
    
    If value < 10
        out += "0"
    EndIf
    
    return out + value
    
EndFunction


; Format integer  with at least three digits, add leading zeros if needed.
String Function FormatDecimal_000(Int value) Global

    String out = ""
    If value < 0
        out = "-"
        value = -value
    EndIf
    
    If value < 100
        out += "0"
    EndIf
    If value < 10
        out += "0"
    EndIf
    
    return out + value
    
EndFunction        


String Function FormatHex(Int value) Global

    String out = ""
    Int shift = 32
    
    While shift
    
        shift -= 4
        Int digit = Math.LogicalAnd(Math.RightShift(value, shift), 15)
        If digit < 10
            out += digit
        ElseIf 10 == digit
            out += "A"
        ElseIf 11 == digit
            out += "B"
        ElseIf 12 == digit
            out += "C"
        ElseIf 13 == digit
            out += "D"
        ElseIf 14 == digit
            out += "E"
        Else
            out += "F"
        EndIf
    
    EndWhile

    Return out
    
EndFunction

int function CountNonNullElements(sla_PluginBase[] arr) Global
    if !arr
        return 0
    endif
    int count = 0
    int i = 0
    while i < arr.length
        if arr[i]
            count += 1
        endif
        i += 1
    endwhile
    return count
endFunction

int function FindFirstFreeIndex(sla_PluginBase[] arr) Global
    if !arr
        return -1
    endif
    int i = 0
    while i < arr.length
        if !arr[i]
            return i ;
        endif
        i += 1
    endwhile
    return -1 ; no free slot found
endFunction
