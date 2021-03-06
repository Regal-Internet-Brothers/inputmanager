Strict

Public

#If HOST = "winnt" And TARGET = "glfw" Or TARGET = "stdcpp"
	#INPUTMANAGER_USE_XINPUT = True
#End

' Imports:
Import regal.inputmanager

#If INPUTMANAGER_USE_XINPUT
	Import regal.xinput
#End

Import mojo

' Classes:
Class Application Extends App Final
	' Constructor(s):
	Method OnCreate:Int()
		#If INPUTMANAGER_USE_XINPUT
			XInputInit()
		#End
		
		SetUpdateRate(0)
		
		Input = New InputManager()
		
		A = ControllerButton(JOY_A)
		
		Input.AddButton(A)
		
		' Return the default response.
		Return 0
	End
	
	' Methods:
	Method OnUpdate:Int()
		Input.Update()
		
		If (A.Down) Then
			Print("A pressed.")
		Endif
		
		' Return the default response.
		Return 0
	End
	
	Method OnRender:Int()
		Cls(105.0, 105.0, 105.0)
		
		' Return the default response.
		Return 0
	End
	
	' Fields:
	Field Input:InputManager
	Field A:InputButton
End

' Functions:
Function Main:Int()
	New Application()
	
	#If INPUTMANAGER_USE_XINPUT
		XInputDeinit()
	#End
	
	' Return the default response.
	Return 0
End