Strict

Public

' Preprocessor related:
' Nothing so far.

' Imports:
Import inputmanager

' Check if 'JoyPresent' should be implemented:
#If INPUT_GLFW_TARGET
	#INPUTMANAGER_JOYPRESENT_IMPLEMENTED = True
#End

' External bindings:
Extern

' Constant variable(s):
' Nothing so far.

' Global variable(s):
#If INPUT_GLFW_TARGET
	' General:
	Global GLFW_PRESENT:Int
	
	' Joystick IDs:
	#Rem
	Global GLFW_JOYSTICK_1:Int
	Global GLFW_JOYSTICK_2:Int
	Global GLFW_JOYSTICK_3:Int
	Global GLFW_JOYSTICK_4:Int
	Global GLFW_JOYSTICK_5:Int
	Global GLFW_JOYSTICK_6:Int
	Global GLFW_JOYSTICK_7:Int
	Global GLFW_JOYSTICK_8:Int
	Global GLFW_JOYSTICK_9:Int
	Global GLFW_JOYSTICK_10:Int
	Global GLFW_JOYSTICK_11:Int
	Global GLFW_JOYSTICK_12:Int
	Global GLFW_JOYSTICK_13:Int
	Global GLFW_JOYSTICK_14:Int
	Global GLFW_JOYSTICK_15:Int
	Global GLFW_JOYSTICK_16:Int
	Global GLFW_JOYSTICK_LAST:Int
	#End
	
	#If INPUTMANAGER_GLFW3
		Function _GLFW_JoyPresent:Int(JoyID:Int)="glfwJoystickPresent"
	#Else
		Function GLFW_GetJoyParam:Int(JoyID:Int, Param:Int)="glfwGetJoystickParam"
	#End
#End

' Functions:

' Check the implementation-flag, just in case:
#If INPUTMANAGER_JOYPRESENT_IMPLEMENTED
	Function JoyPresent:Bool(JoyID:Int)
		#If INPUTMANAGER_GLFW_TARGET
			#If Not INPUTMANAGER_GLFW3
				If (GLFW_GetJoyParam(JoyID, GLFW_PRESENT) = 1) Then ' GL_TRUE
					Return True
				Endif
			#Else
				If (_GLFW_JoyPresent(JoyID) = 1) Then ' GL_TRUE
					Return True
				Endif
			#End
		#End
		
		' Return the default response.
		Return False
	End
#End

Public