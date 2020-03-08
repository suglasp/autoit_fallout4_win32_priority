#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=fallout4_wg32.exe
#AutoIt3Wrapper_Outfile_x64=fallout4_wg64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <AutoItConstants.au3>
#include <WinAPI.au3>
#include <WinAPIProc.au3>

; --------------
; Pieter De Ridder aka Suglasp
; May 2018
;
; AutoIT Watch Guard script, to scale up Fallout4
;
; set Fallout4 on high priority for a machine with up to maximum 8 CPU cores (Octacore)
; Fallout4.exe priority scaler
; --------------


; global vars
Global $bHaveSeenFallout4 = False
Global $iTotalCPUCount    = EnvGet("NUMBER_OF_PROCESSORS")


; write a msg to stdout
Func WriteMsg($msg)
	ConsoleWrite($msg & @CRLF)
EndFunc




#Region CPU_Priority
; change process priority to Below Normal Class
Func SetCPUPriorityLow($iPID)
	SetCPUPriority($iPID, $BELOW_NORMAL_PRIORITY_CLASS)
EndFunc

; change process priority to Normal Class
Func SetCPUPriorityNormal($iPID)
	SetCPUPriority($iPID, $NORMAL_PRIORITY_CLASS)
EndFunc

; change process priority to High Class
Func SetCPUPriorityHigh($iPID)
	SetCPUPriority($iPID, $HIGH_PRIORITY_CLASS)
EndFunc

; change process priority to High Class
Func SetCPUPriority($iPID, $iPriority)
	If ($iPID > 0) Then
		Local $PROCESS_ALL_ACCESS = 0x1F0FFF

		Local $hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, False, $iPID)

		_WinAPI_SetPriorityClass($iPriority, $iPID)

		_WinAPI_CloseHandle($hProcess)
	EndIf
EndFunc
#EndRegion




#Region CPU_NUMA_Affinity

; set auto cpu affinity
Func SetAutoNUMAAffinityByName($strProcessName, $iCPUMod)

;~ ----  codes for up to 4 cores (Quadcore cpu)  ----
;~ 		CPU3 CPU2 CPU1 CPU0  Bin  Hex
;~ 		---- ---- ---- ----  ---  ---
;~ 		OFF  OFF  OFF  OFF = 0000 = 0   ( Let SysWow chose CPU )
;~ 		OFF  OFF  OFF  ON  = 0001 = 1
;~ 		OFF  OFF  ON   OFF = 0010 = 2
;~ 		OFF  OFF  ON   ON  = 0011 = 3         * CPU0 and CPU01
;~ 		OFF  ON   OFF  OFF = 0100 = 4
;~ 		OFF  ON   OFF  ON  = 0101 = 5
;~ 		OFF  ON   ON   OFF = 0110 = 6
;~ 		OFF  ON   ON   ON  = 0111 = 7
;~ 		ON   OFF  OFF  OFF = 1000 = 8
;~ 		ON   OFF  OFF  ON  = 1001 = 9
;~ 		ON   OFF  ON   OFF = 1010 = A  (10)
;~ 		ON   OFF  ON   ON  = 1011 = B  (11)
;~ 		ON   ON   OFF  OFF = 1100 = C  (12)   * CPU02 and CPU03
;~ 		ON   ON   OFF  ON  = 1101 = D  (13)
;~ 		ON   ON   ON   OFF = 1110 = E  (14)
;~ 		ON   ON   ON   ON  = 1111 = F  (15)


;~ ----  codes for up to 16 cores (Hexadeca core cpu)  ----
;~       CPU1+CPU2   0000000000000011 = 03       (3) * CPU00 and CPU01
;~       CPU3+CPU4   0000000000001100 = 0C      (12) * CPU02 and CPU03
;~       CPU5+CPU6   0000000000110000 = 30      (48) * CPU04 and CPU05
;~       CPU7+CPU8   0000000011000000 = 60      (96) * CPU06 and CPU07
;
;~       CPU9+CPU10  0000001100000000 = 300    (768) * CPU08 and CPU09
;~      CPU11+CPU12  0000110000000000 = C00   (3072) * CPU10 and CPU11
;~      CPU13+CPU14  0011000000000000 = 3000 (12288) * CPU12 and CPU13
;~      CPU15+CPU16  1100000000000000 = C000 (49152) * CPU14 and CPU15

	Local $bSuccess = False
	Local $iPID = ProcessExists($strProcessName)
	Local $iCoreCount = EnvGet("NUMBER_OF_PROCESSORS")

	WriteMsg("")
	WriteMsg(" NR CPUS : " & $iCoreCount)
	WriteMsg(" PID     : " & $iPID & " (=" & $strProcessName & ")")
	WriteMsg("")

	If ($iPID > 0) Then
		Select
			Case $iCPUMod = 0
				ContinueCase                    ; CPU0 and CPU1  (Dual-Core pair)
			Case $iCPUMod = 1
				SetCPUAffinity($iPID, 3)
				WriteMsg("  Bound to CPU0 and CPU1")
				$bSuccess = True

			Case $iCPUMod = 2
				ContinueCase                    ; CPU2 and CPU3  (Quad-Core pair)
			Case $iCPUMod = 3
				If ($iCoreCount >= 3) Then
					SetCPUAffinity($iPID, 12)
					WriteMsg("  Bound to CPU2 and CPU3")
					$bSuccess = True
				EndIf

			Case $iCPUMod = 4
				ContinueCase                    ; CPU4 and CPU5  (Hex-Core pair)
			Case $iCPUMod = 5
				If ($iCoreCount >= 5) Then
					SetCPUAffinity($iPID, 48)
					WriteMsg("  Bound to CPU4 and CPU5")
					$bSuccess = True
				EndIf

			Case $iCPUMod = 6
				ContinueCase                    ; CPU6 and CPU7  (Octa-Core pair)
			Case $iCPUMod = 7
				If ($iCoreCount >= 7) Then
					SetCPUAffinity($iPID, 96)
					WriteMsg("  Bound to CPU6 and CPU7")
					$bSuccess = True
				EndIf
		EndSelect
	EndIf

	Return $bSuccess
EndFunc


; set low level Process CPU Affinity
Func SetCPUAffinity($iPID, $iCPUIndex)
	Local $PROCESS_ALL_ACCESS = 0x1F0FFF

	Local $hProcess = _WinAPI_OpenProcess($PROCESS_ALL_ACCESS, False, $iPID)

;~ 	Local $aMask = _WinAPI_GetProcessAffinityMask($hProcess)
;~ 	ShowCPUAffinity($aMask)

	_WinAPI_SetProcessAffinityMask($hProcess, $iCPUIndex)

	$aMask = _WinAPI_GetProcessAffinityMask($hProcess)
;~ 	ShowCPUAffinity($aMask)

	_WinAPI_CloseHandle($hProcess)
EndFunc
#EndRegion









Func Main()
	; set low priority for own script
	Sleep(500)
	SetCPUPriorityLow(ProcessExists(@ScriptName & ".exe"))

	; wait for Fallout 4 to become alive...
	While (Not $bHaveSeenFallout4)
		If (ProcessExists("fallout4.exe") > 0) Then
			$bHaveSeenFallout4 = True

			WriteMsg("Found Fallout4!")
		EndIf

		Sleep(1000) ; wait 1 second
	WEnd

	; okay, we have a fallout4 process running, change the game...
	If ($bHaveSeenFallout4) Then
		WriteMsg("Adjusting process priority...")

		Local $iFO4Pid = ProcessExists("Fallout4.exe")

		If ($iFO4Pid > 0) Then
			;SetCPUAffinity($iFO4Pid, 3) ; set to only first 2 cores
			SetCPUAffinity($iFO4Pid, 15) ; set to only first 4 cores
		EndIf

		SetCPUPriorityHigh($iFO4Pid)
	EndIf


	; wait for Fallout 4 to end...
;~ 	While ($bHaveSeenFallout4)
;~ 		If (ProcessExists("fallout4.exe") > 0) Then
;~ 			$bHaveSeenFallout4 = True
;~ 		Else
;~ 			$bHaveSeenFallout4 = False ; bail out of loop so we can restore all settings
;~ 		EndIf

;~ 		Sleep(10000) ; wait 10 seconds
;~ 	WEnd

	; restore Steam, in case for a in-home streaming machine!
;~ 	If ($bHaveSeenFallout4) Then
;~ 		WriteMsg("Restore process priority...")

;~ 		Local $iPIDSteam = "Steam.exe"

;~ 		SetCPUPriorityNormal("Steam.exe")
;~ 	EndIf


	; start new script instance after quitting
;~ 	WriteMsg("Init new instance...")
;~ 	Sleep(5000)

;~ 	Run(@ScriptDir & "\" & @ScriptName)


	; quit current script
	Exit 0
EndFunc






; ----- MAIN -----
Main()