Strict

Public

' Preprocessor related:
' Nothing so far.

' Imports:
Import external

' Functions:
#If Not INPUTMANAGER_JOYPRESENT_IMPLEMENTED
	' This command will assume no hardware is plugged in.
	Function JoyPresent:Bool(JoyID:Int)
		' Return the default response.
		Return False
	End
#End