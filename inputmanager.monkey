Strict

Public

#Rem
	DESCRIPTION:
		* This module was developed as an attempt at device-neutral input handling.
		
		Currently, this module is based on Mojo's standard input functionality.
		
		This module still needs a number of improvements,
		but this should work well for normal use. This framework may be remade at a later date,
		the 'Stream' I/O really isn't the best, and because of it, I can't really rework this.
		This mainly has to do with button atlases, as well as how buttons are created and managed.
		
		I'll probably overhaul this when I have the time. One major design choice I'd like to
		make down the road is a switch to proper polymorphism. I'd also like to make the buttons
		connect with devices, rather than managers.
		
		There's a lot to work on here, but this model still works rather well.
		You can set up your buttons once (Likely in your own "controller" class) with a single initialization routine.
		
		After that, you'll be able to hold that manager within your main game class, and update it with your 'OnUpdate' routine.
		In terms of my own usage, I have game-objects which allow me to pass around controllers,
		as well as synchronize their states between game instances if needed (Online multiplayer).
	TODO:
		* Optimize just about everything.
		* Switch some uses of floating-point to integral. (A bit problematic with the current framework)
		* Integrate 'typetool' functionality further.
		* Look into the ability to press and/or hold both triggers at the same time.
		* Add an XInput backend as a controller alternative. (Could fix the trigger issue)
		* Overhaul the 'InputButton' class.
#End

' Preprocessor related:
#INPUTMANAGER_IMPLEMENTED = True

' If this is a standard game-target, enable the main functionality:
#If BRL_GAMETARGET_IMPLEMENTED
	#INPUTMANAGER_ENABLED = True
#End

#If TARGET = "glfw" Or TARGET = "sexy"
	' This preprocessor variable is only defined when we're on a GLFW or GLFW-compatible target.
	#INPUTMANAGER_GLFW_TARGET = True
	
	#If GLFW_VERSION And GLFW_VERSION = 3
		#INPUTMANAGER_GLFW3 = True
	#Else
		#INPUTMANAGER_GLFW3 = False
	#End
#End

#If HOST = "winnt" And LANG = "cpp" And TARGET <> "win8"
	#INPUTMANAGER_USE_XINPUT = True
#End

#If INPUTMANAGER_USE_XINPUT
	#INPUTMANAGER_OPTIMIZE_MEMORY = False
	#INPUTMANAGER_XNA_FIXES = False
#End

#Rem
	When this is enabled, input-devices get data from the standard storage-agnostic commands.
	And if this is disabled, in-line checking will be preferred.
	
	This is not a rule, but a guideline for this module. Some situations do not use this variable.
#End

#INPUTMANAGER_ABSTRACTED_DATA_COLLECTION = False ' True

#Rem
	This will try to optimize performance when 'INPUTMANAGER_OPTIMIZE_MEMORY' is disabled.
	The downside to this is that you're either limited to the minimum of the "hit" and "down"
	array sizes (If 'INPUTMANAGER_OPTIMIZE_MEMORY' is enabled), or just the "hit" array's size.
	
	This can work well, though, as the "hit" and "down" arrays tend to be the same size.
	
	Use this feature at your own risk.
#End

#INPUTMANAGER_SINGLE_PASS_DETECTION = False

#Rem
	Keeping this enabled is a very good idea, even if 'INPUTMANAGER_SINGLE_PASS_DETECTION' is disabled,
	as it doesn't affect anything in those situations, anyway. (This might be useful to me in the future)
#End

#INPUTMANAGER_SINGLE_PASS_DETECTION_SAFETY = True

' If this is enabled, the 'JoyHat' command will work exactly like BlitzBasic's implementation.
#INPUTMANAGER_JOYHAT_AUTHENTIC = False ' True

#If INPUTMANAGER_ENABLED
	' Target specific defaults:
	#If TARGET = "xna" Or INPUTMANAGER_GLFW_TARGET Or TARGET = "android" Or TARGET = "psm" ' Or TARGET = "ios"
		#INPUTMANAGER_CONTROLLERS_SUPPORTED = True
	#Else
		#INPUTMANAGER_CONTROLLERS_SUPPORTED = False
	#End
	
	' Configuration related:
	#If CONFIG = "release" ' "debug"
		#INPUTMANAGER_CONTROLLERS_SAFE = True
	#Else
		#INPUTMANAGER_CONTROLLERS_SAFE = False
	#End
	
	' General defaults:
	#INPUTMANAGER_MAX_CONTROLLERS = False ' True
	#INPUTMANAGER_CONTROLLERS_MAXBUTTONS = False ' True
	#INPUTMANAGER_CONTROLLERS_OPTIMIZE_AVAILABILITY_CHECK = True
	#INPUTMANAGER_CONTROLLERS_COPY_UNUSED_TRIGGER_DATA = False ' True
	#INPUTMANAGER_CONTROLLERS_INTUITIVE_TRIGGERS = False
#End

#If Not FLAG_CONSOLEMODE ' TARGET = "android"
	#INPUTMANAGER_OPTIMIZE_MEMORY = False ' True
#Else
	#INPUTMANAGER_OPTIMIZE_MEMORY = False
#End

#If TARGET = "xna"
	#Rem
		This fixes an odd issue with 'JoyZ' on the XNA target.
		
		Basically, Monkey's trigger / 'JoyZ'
		functionality is different per-target.
		
		Because of this, XNA's XInput setup doesn't return a negative
		version on the first value from 'JoyZ' when reading the second.
		
		The standard GLFW targets (On the other hand) use such a setup.
		So, since I can't really fix this on the GLFW targets,
		I need to make the XNA target produce different information.
	#End
	
	#INPUTMANAGER_XNA_FIXES = True
#End

' Imports (Public):

' Internal:
Import external
Import fallbacks

' External:
Import regal.vector

Import mojo.keycodes

' Imports (Private):
Private

' External:
Import regal.util

Import regal.typetool

' Check if we're using a standard game-target:
#If BRL_GAMETARGET_IMPLEMENTED
	' Everything checks out, import 'mojo' normally.
	Import mojo.input
	
	' Standard 'autofit' functionality.
	Import regal.autofit ' autofit
#Else
	' We're on a non-standard/non-game target, import 'mojoemulator'.
	Import regal.mojoemulator.app
#End

#If INPUTMANAGER_USE_XINPUT
	Import regal.xinput
#End

' This is for stream I/O, not for input-devices.
Import regal.ioelement

Public

' Constant variable(s):

' Joy / Controller key codes:
Const JOY_LEFTANALOG:= ControllerDevice.JOY_LEFTANALOG
Const JOY_RIGHTANALOG:= ControllerDevice.JOY_RIGHTANALOG
Const JOY_TRIGGERS:= ControllerDevice.JOY_TRIGGERS
Const JOY_LEFTTRIGGER:= ControllerDevice.JOY_LEFTTRIGGER
Const JOY_RIGHTTRIGGER:= ControllerDevice.JOY_RIGHTTRIGGER
Const JOY_HAT:= ControllerDevice.JOY_HAT

' Mouse related:
Const MOUSE_DATA:= MouseDevice.MOUSE_DATA

' Shorthand:
Const INPUT_DEVICE_KEYBOARD:= InputManager.DEVICE_KEYBOARD
Const INPUT_DEVICE_MOUSE:= InputManager.DEVICE_MOUSE
Const INPUT_DEVICE_CONTROLLER:= InputManager.DEVICE_CONTROLLER

' Interfaces:

' This inteface is used for detecting when a controller is formally activated.
Interface ControllerActivationCallback
	' Methods:
	Method OnControllerActivation:Void(ControllerID:UShort, InputManager:InputManager)
End

' This interface is used for detecting a button press on any available device.
' Standard behavior is for the input-manager to remove your 'ButtonPressCallBack' after it has been used once.
' In addition, the input-manager will ignore input when awaiting a button-press.
Interface ButtonPressCallBack
	' Methods:
	
	' The 'KeyCode' argument is device specific, and the 'DeviceID' argument is based on the devices' 'DEVICE_ID' constants.
	Method OnButtonPress:Void(KeyCode:Int, DeviceID:UShort)
End

' Classes:

' This class acts as a hub for input-device management, and by-extension, button management.
Class InputManager
	' Constant variable(s):
	
	' General:
	Const AUTO:= UTIL_AUTO
	
	Const ARRAY_TYPE_HIT:Bool = True
	Const ARRAY_TYPE_DOWN:Bool = False
	
	' Device types:
	Const DEVICE_UNKNOWN:= InputDevice.DEVICE_ID
	Const DEVICE_KEYBOARD:= KeyboardDevice.DEVICE_ID
	Const DEVICE_MOUSE:= MouseDevice.DEVICE_ID
	Const DEVICE_CONTROLLER:= ControllerDevice.DEVICE_ID
	
	' Controller related:
	#If Not INPUTMANAGER_USE_XINPUT
		#If INPUTMANAGER_MAX_CONTROLLERS And INPUTMANAGER_GLFW_TARGET
			Const CONTROLLER_COUNT:UShort = 16
		#Else
			#If ANDROID_OUYA_BUILD Or INPUTMANAGER_GLFW_TARGET
				Const CONTROLLER_COUNT:UShort = 4
			#Else
				Const CONTROLLER_COUNT:UShort = 1
			#End
		#End
	#Else
		Const CONTROLLER_COUNT:UShort = 4 ' UShort(XUSER_MAX_COUNT)
	#End
	
	Const CONTROLLER_PRIMARY:= ControllerDevice.CONTROLLER_PRIMARY
	
	' Defaults:
	Const Default_ControllerCount:= CONTROLLER_COUNT
	
	' Global variable(s):
	' Nothing so far.
	
	' Functions:
	Function Flush:Bool(IMStack:Stack<InputManager>)
		' Check for errors:
		If (IMStack = Null) Then
			Return False
		Endif
		
		For Local Manager:= Eachin IMStack
			If (Not Manager.FlushButtons()) Then
				Return False
			Endif
		Next
		
		' Return the default response.
		Return True
	End
	
	Function RealControllerCount:UShort()
		Return ControllerDevice.HardwareCount()
	End
	
	' Constructor(s):
	Method New(ControllerCount:UShort=Default_ControllerCount, ControllerActivationCallback:ControllerActivationCallback=Null, ControllerActivationStack:Stack<Int>=Null)
		Buttons = New Stack<InputButton>()
		Mice = New Stack<MouseDevice>()
		Keyboards = New Stack<KeyboardDevice>()
		
		Mice.Push(New MouseDevice(Self))
		Keyboards.Push(New KeyboardDevice(Self))
		
		'#If INPUTMANAGER_CONTROLLERS_SUPPORTED
			' Create the controller list.
			Controllers = New Stack<ControllerDevice>()
			
			' Create any needed controller objects/devices:
			Controllers.Push(New ControllerDevice(Self, 0, ControllerActivationCallback, ControllerActivationStack))
			
			#If ANDROID_OUYA_BUILD Or INPUTMANAGER_GLFW_TARGET
				' Add the remaining controllers:
				For Local I:= 1 Until ControllerCount
					Controllers.Push(New ControllerDevice(Self, I, ControllerActivationCallback, ControllerActivationStack))
				Next
			#End
		'#End
	End
	
	' Destructor(s):
	Method Free:Bool()
		#Rem
			If (Mouse <> Null) Then
				Mouse.Free(); Mouse = Null
			Endif
			
			If (Keyboard <> Null) Then
				Keyboard.Free(); Keyboard = Null
			Endif
		#End
		
		If (Mice <> Null) Then
			For Local M:= Eachin Mice
				M.Free()
			Next
			
			Mice.Clear();
			
			'Mice = Null
		Endif
		
		If (Keyboards <> Null) Then
			For Local K:= Eachin Keyboards
				K.Free()
			Next
			
			Keyboards.Clear()
			
			'Keyboards = Null
		Endif
		
		#If INPUTMANAGER_CONTROLLERS_SUPPORTED
			If (Controllers <> Null) Then
				For Local C:= Eachin Controllers
					C.Free()
				Next
				
				Controllers.Clear()
				
				'Controllers = Null
			Endif
		#End
		
		' Return the default response.
		Return True
	End
	
	' This is just a wrapper for 'Free':
	Method Discard:Bool()
		Return Free()
	End
	
	' Methods (Public):	
	Method AddAtlases:Bool(BAStack:Stack<ButtonAtlas>)
		For Local BA:= Eachin BAStack
			If (Not AddAtlas(BA)) Then
				Return False
			Endif
		Next
		
		' Return the default response.
		Return True
	End
	
	Method AddAtlas:Bool(BA:ButtonAtlas)
		Return AddButtons(BA)
	End
	
	Method AddButtons:Bool(BA:ButtonAtlas)
		Return AddButtons(BA.Buttons)
	End
	
	Method AddButtons:Bool(BA:InputButton[])
		For Local B:= Eachin BA
			If (Not AddButton(B)) Then
				Return False
			Endif
		Next
		
		' Return the default response.
		Return True
	End
	
	Method AddButtons:Bool(BStack:Stack<InputButton>)
		For Local B:= Eachin BStack
			If (Not AddButton(B)) Then
				Return False
			Endif
		Next
		
		' Return the default response.
		Return True
	End
	
	Method AddButton:Bool(B:InputButton)
		' Check for errors:
		If (B = Null) Then Return False
		If (Buttons = Null) Then Return False
		
		' Add the designated button to the button-list.
		If (Not Buttons.Contains(B)) Then
			Buttons.Push(B)
			
			B.Parent = Self
		Endif
		
		' Return the default response.
		Return True
	End
	
	Method RemoveButton:Bool(B:InputButton)
		' Check for errors:
		If (Buttons = Null) Then Return False
		If (B = Null) Then Return False
		If (B.Parent <> Self) Then Return False
		
		' Remove the designated button from the button-list.
		Buttons.RemoveEach(B)
		
		B.Parent = Null
		
		' Return the default response.
		Return True
	End
	
	Method RemoveButtons:Bool(BStack:Stack<InputButton>)
		For Local B:= Eachin BStack
			If (Not RemoveButton(B)) Then
				Return False
			Endif
		Next
		
		' Return the default response.
		Return True
	End
	
	Method RemoveButtons:Bool(BA:ButtonAtlas)
		Return RemoveButtons(BA.Buttons)
	End
	
	' This command effectively removes all internal ties to the specified button.
	' Obviously, this does not remove any external references you may have of the specified button.
	' You must handle those references yourself.
	Method ReleaseButton:Bool(B:InputButton)
		' Check for errors:
		If (B = Null) Then
			Return False
		Endif
		
		' Remove the atlases attached to this button.
		B.RemoveAtlases()
		
		' Execute the main removal routine, then return its response.
		Return RemoveButton(B)
	End
	
	Method RemoveAtlas:Bool(BA:ButtonAtlas)
		Return RemoveButtons(BA)
	End
	
	Method RemoveAtlases:Bool(BAStack:Stack<ButtonAtlas>)
		For Local BA:= Eachin BAStack
			If (Not RemoveAtlas(BA)) Then
				Return False
			Endif
		Next
		
		' Return the default response.
		Return True
	End
	
	Method RemovePressCallBack:Bool()
		Self.PressCallBack = Null
		
		' Return the default response.
		Return True
	End
	
	Method Update:Void()
		FlushButtons()
		
		UpdateDevices()
		UpdateButtons()
		
		Return
	End
	
	Method FlushButtons:Bool()
		If (Buttons <> Null) Then
			For Local B:= Eachin Buttons
				B.Flush()
			Next
			
			Return True
		Endif
		
		' Return the default response.
		Return False
	End
	
	' This is just a quick wrapper for 'FlushButtons'.
	Method Flush:Bool()
		Return FlushButtons()
	End
	
	Method UpdateButtons:Void()		
		For Local B:= Eachin Buttons
			Local Device:InputDevice = Null
			
			Select B.Device
				Case DEVICE_KEYBOARD
					Device = Keyboard(B.SubDevice)
				Case DEVICE_MOUSE
					Device = Mouse(B.SubDevice)
				Case DEVICE_CONTROLLER
					Device = Controller(B.SubDevice)
				Default
					' If we were unable to find
					' a device, skip this button.
					Continue
			End Select
			
			' Update the button using the device specified.
			Device.UpdateButton(B)
		Next
		
		Return
	End
	
	Method UpdateDevices:Void()
		UpdateMice()
		UpdateKeyboards()
		UpdateControllers()
		
		Return
	End
	
	Method UpdateMice:Void()
		If (Mice = Null) Then Return
		
		For Local M:= Eachin Mice
			M.Update()
		Next
	End
	
	Method UpdateKeyboards:Void()
		If (Keyboards = Null) Then Return
		
		For Local K:= Eachin Keyboards
			K.Update()
		Next
		
		Return
	End
	
	Method UpdateControllers:Void()
		If (Controllers = Null) Then Return
		
		For Local C:= Eachin Controllers
			C.Update()
		Next
		
		Return
	End
	
	' This is based on the 'ControllerDevice' class's 'PluggedIn' property, this may not represent actual hardware:
	' For exact hardware detection, use the 'ControllerDevice' class's 'HardwareCount' command, or use 'JoyCount'.
	Method ControllersPluggedIn:Int(Controllers:Int=CONTROLLER_COUNT, Offset:Int=CONTROLLER_PRIMARY)
		' Local variable(s):
		Local Count:Int = 0
		
		For Local ControllerID:= Offset Until Controllers
			Local C:= Controller(ControllerID)
			
				If (C <> Null And C.PluggedIn) Then
					Count += 1
			#If INPUTMANAGER_CONTROLLERS_OPTIMIZE_AVAILABILITY_CHECK
				Else
					Return Count
			#End
				Endif
		Next
		
		' Return the number of controllers we have plugged in.
		Return Count
	End
	
	' Properties:
	
	' Device interfaces:
	
	' For now, these properties just use 'Int':
	Method Controller:ControllerDevice(Index:Int=0) Property
		'Return GenericUtilities<ControllerDevice>.IndexOfStack(Controllers, Index)
		Return Controllers.Get(Index)
	End
	
	Method Mouse:MouseDevice(Index:Int=0) Property
		'Return GenericUtilities<MouseDevice>.IndexOfStack(Mice, Index)
		Return Mice.Get(Index)
	End
	
	Method Keyboard:KeyboardDevice(Index:Int=0) Property
		'Return GenericUtilities<KeyboardDevice>.IndexOfStack(Keyboards, Index)
		Return Keyboards.Get(Index)
	End
	
	' Other:
	Method AwaitingButtonPress:Bool() Property
		Return (PressCallBack <> Null)
	End
	
	' Fields (Public):
	
	' Containers:
	Field Mice:Stack<MouseDevice>
	Field Keyboards:Stack<KeyboardDevice>
	
	'#If INPUTMANAGER_CONTROLLERS_SUPPORTED
	Field Controllers:Stack<ControllerDevice>
	'#End
	
	Field Buttons:Stack<InputButton>
	
	' This object will be reset every time it is used.
	' Set this whenever you want to check for a button press on any device,
	' usually without that press actually going through.
	Field PressCallBack:ButtonPressCallBack
	
	' Fields (Private):
	Private
	
	' Nothing so far.
	
	Public
End

' Input devices:
Class InputDevice
	' Constant variable(s):
	Const AUTO:= InputManager.AUTO
	
	Const DEVICE_ID:UShort = 65535 ' -1
	
	Const ARRAY_TYPE_HIT:= InputManager.ARRAY_TYPE_HIT
	Const ARRAY_TYPE_DOWN:= InputManager.ARRAY_TYPE_DOWN
	
	' Constructor(s):
	Method New(Parent:InputManager, HitArraySize:Int, DownArraySize:Int, SubDeviceID:UShort=0)
		Self.Parent = Parent
		
		#If Not INPUTMANAGER_OPTIMIZE_MEMORY
			If (HitArraySize > 0) Then
				HitArray = New Int[HitArraySize]
			Endif
			
			If (DownArraySize > 0) Then
				DownArray = New Int[DownArraySize]
			Endif
		#End
		
		Self.SubDeviceID = SubDeviceID
	End
	
	' Destructor(s) (Abstract):
	' Nothing so far.
	
	' Destructor(s) (Implemented):
	Method Free:Bool()
		' Set the parent to 'Null'.
		Parent = Null
		
		' Return the default response.
		Return True
	End
	
	' This command just wraps 'Free':
	Method Discard:Bool()
		Return Free()
	End
	
	' Methods:
	
	' The following commands are used to abstract the user from the underlying storage system of this device.
	Method GetValue:Void(B:InputButton)
		' Local variable(s):
		Local Code:= B.KeyCode
		Local HitValue:Int, DownValue:Int
		
		' This small routine grabs the button/key states,
		' from wherever the preprocessor specifies:
		#If INPUTMANAGER_ABSTRACTED_DATA_COLLECTION
			HitValue = GetHitValue(Code)
			DownValue = GetDownValue(Code)
		#Else
			#If Not INPUTMANAGER_OPTIMIZE_MEMORY
				HitValue = HitArray[Code]
				DownValue = DownArray[Code]
			#Else
				HitValue = Get_Device_HitState(Code)
				DownValue = Get_Device_DownState(Code)
			#End
		#End
		
		' Check if our parent is awaiting a button press:
		If (Parent.AwaitingButtonPress) Then
			If (HitValue > 0 Or DownValue > 0) Then
				' Execute the button-press call-back.
				Parent.PressCallBack.OnButtonPress(Code, DeviceID)
				
				' Tell our parent to remove its call-back.
				Parent.RemovePressCallBack()
			Endif
			
			' This 'Return' is here instead of above as a fail-safe.
			' Either way, we don't want buttons getting data they shouldn't.
			' So, we need to return if we reach this point.
			Return
		Endif
		
		' Everything's normal, assign the state information.
		B.HitValue = HitValue
		B.DownValue = DownValue
		
		Return
	End
	
	Method GetHitValue:Int(Code:Int)
		#If INPUTMANAGER_OPTIMIZE_MEMORY
			Return Get_Device_HitState(Code)
		#Else
			Return HitArray[Code]
		#End
	End
	
	Method GetDownValue:Int(Code:Int)
		#If INPUTMANAGER_OPTIMIZE_MEMORY
			Return Get_Device_DownState(Code)
		#Else
			Return DownArray[Code]
		#End
	End
	
	' As a rule of thumb with this command, if a name ends in "_Out", then it's about the destination. Otherwise, it's about the source.
	Method OutputToArrays:Void(Hit_Out:Int[], Down_Out:Int[], Hit_Out_Offset:ULong=0, Down_Out_Offset:ULong=0, Hit_Offset:ULong=0, Down_Offset:ULong=0, Hit_Out_Length:Int=AUTO, Down_Out_Length:Int=AUTO, Hit_Length:Int=AUTO, Down_Length:Int=AUTO)
		OutputToArray(Hit_Out, ARRAY_TYPE_HIT, Hit_Out_Offset, Hit_Offset, Hit_Out_Length, Hit_Length)
		OutputToArray(Down_Out, ARRAY_TYPE_DOWN, Down_Out_Offset, Down_Offset, Down_Out_Length, Down_Length)
		
		Return
	End
	
	' The output-array in this command is referenced as "Output", and the source-array is referenced as "Source". This is consistent for every situation.
	' This function was implemented with the 'util' module's standard 'CopyArray' functionality as a base, and in some cases uses it directly.
	Method OutputToArray:Bool(Output:Int[], ArrayType:Bool=ARRAY_TYPE_HIT, Output_Offset:ULong=0, Source_Offset:ULong=0, Source_Length:Int=AUTO, Output_Length:Int=AUTO)
		#If INPUTMANAGER_ENABLED
			#If INPUTMANAGER_OPTIMIZE_MEMORY
				If (Output_Length = AUTO) Then
					Output_Length = Output.Length()
				Else
					Output_Length = Min(Output_Length, Output.Length())
				Endif
			#End
		#Else
			#If INPUTMANAGER_OPTIMIZE_MEMORY
				' We were unable to perform this operation, tell the user.
				Return False
			#End
		#End
		
		'If (ArrayType = ARRAY_TYPE_HIT) Then
		If (ArrayType) Then
			#If Not INPUTMANAGER_OPTIMIZE_MEMORY
				GenericUtilities<Int>.CopyArray(HitArray, Output, Source_Offset, Output_Offset, Source_Length, Output_Length, False)
			#Else
				#If INPUTMANAGER_ENABLED
					If (Source_Length = AUTO) Then
						Source_Length = HitArraySize
					Else
						Source_Length = Min(Source_Length, HitArraySize)
					Endif
					
					For Local I:= 0 Until Min(Source_Length, Output_Length)
						Output[I+Output_Offset] = Get_Device_HitState(I+Source_Offset)
					Next
				#End
			#End
		Else 'If (ArrayType = ARRAY_TYPE_DOWN) Then
			#If Not INPUTMANAGER_OPTIMIZE_MEMORY
				GenericUtilities<Int>.CopyArray(DownArray, Output, Source_Offset, Output_Offset, Source_Length, Output_Length, False)
			#Else
				#If INPUTMANAGER_ENABLED
					If (Source_Length = AUTO) Then
						Source_Length = DownArraySize
					Else
						Source_Length = Min(Source_Length, DownArraySize)
					Endif
					
					For Local I:= 0 Until Min(Source_Length, Output_Length)
						Output[I+Output_Offset] = Get_Device_DownState(I+Source_Offset)
					Next
				#End
			#End
		Endif
		
		' Return the default response.
		Return True
	End
	
	' Input related:
	Method Detect:Bool()
		#If INPUTMANAGER_ENABLED
			' Local variable(s):
			' Nothing so far.
			
			#If Not INPUTMANAGER_OPTIMIZE_MEMORY
				#If INPUTMANAGER_SINGLE_PASS_DETECTION
					For Local I:= 0 Until 
					
					#If INPUTMANAGER_SINGLE_PASS_DETECTION_SAFETY
						Min(HitArraySize, DownArraySize)
					#Else
						HitArraySize
					#End
				#End
				
				#If Not INPUTMANAGER_SINGLE_PASS_DETECTION
					For Local I:= 0 Until HitArraySize ' HIT_ARRAY_SIZE
				#End
					
					' Iterate through the hit-array:
					HitArray[I] = Get_Device_HitState(I)
					
				#If Not INPUTMANAGER_SINGLE_PASS_DETECTION
					Next
				#End
				
				' Iterate through the down-array:
				#If Not INPUTMANAGER_SINGLE_PASS_DETECTION
					For Local I:= 0 Until DownArraySize ' DOWN_ARRAY_SIZE
				#End
					
					DownArray[I] = Get_Device_DownState(I)
					
				#If Not INPUTMANAGER_SINGLE_PASS_DETECTION
					Next
				#End
				
				#If INPUTMANAGER_SINGLE_PASS_DETECTION
					Next
				#End
			#End
			
			' Return the default response.
			Return True
		#Else
			' Return the default response.
			Return False
		#End
	End
	
	Method Get_Device_HitState:Int(Code:Int)
		' In the event this isn't reimplemented, return zero.
		Return 0
	End
	
	Method Get_Device_DownState:Int(Code:Int)
		' In the event this isn't reimplemented, return zero.
		Return 0
	End
	
	Method UpdateButton:Void(B:InputButton)
		GetValue(B)
		
		Return
	End
	
	Method Update:Void()
		'#If Not INPUTMANAGER_OPTIMIZE_MEMORY
		Flush()
		Detect()
		'#End
		
		Return
	End
	
	Method Flush:Bool()
		#If Not INPUTMANAGER_OPTIMIZE_MEMORY
			' Flush the "hit" and "down" arrays:
			If (HitArray.Length() > 0) Then
				For Local I:= 0 Until HitArray.Length()
					HitArray[I] = 0
				Next
			Else
				Return False
			Endif
			
			If (DownArray.Length() > 0) Then
				For Local I:= 0 Until DownArray.Length()
					DownArray[I] = 0
				Next
			Else
				Return False
			Endif
		#End
		
		' Return the default response.
		Return True
	End
	
	' Properties:
	Method HitArraySize:Int() Property
		#If Not INPUTMANAGER_OPTIMIZE_MEMORY
			Return HitArray.Length()
		#Else
			Return 0
		#End
	End
	
	Method DownArraySize:Int() Property
		#If Not INPUTMANAGER_OPTIMIZE_MEMORY
			Return DownArray.Length()
		#Else
			Return 0
		#End
	End
	
	#Rem
		This property generally should be reimplemented per-device.
		But, since this isn't used by much, re-implementing this isn't required.
	#End
	
	Method DeviceID:UShort() Property
		Return DEVICE_ID
	End
	
	' Fields:
	Field Parent:InputManager
	Field SubDeviceID:UShort
	
	#If Not INPUTMANAGER_OPTIMIZE_MEMORY
		' Button / Key state arrays:
		Field HitArray:Int[]
		Field DownArray:Int[]
	#End
	
	' Booleans / Flags:
	Field Activated:Bool
End

Class KeyboardDevice Extends InputDevice Final
	' Constant variable(s):
	
	' This is currently a placeholder.
	Const KEYBOARD_PRIMARY:Int		= 0
	
	Const DEVICE_ID:UShort			= 0
	
	Const HIT_ARRAY_SIZE:Int		= 256
	Const DOWN_ARRAY_SIZE:Int		= HIT_ARRAY_SIZE ' 256
	
	' Defaults:
	Const Default_Activated:Bool = True
	
	' Constructor(s):
	Method New(Parent:InputManager, KeyboardID:Int=KEYBOARD_PRIMARY)
		Super.New(Parent, HIT_ARRAY_SIZE, DOWN_ARRAY_SIZE, KeyboardID)
		
		Self.Activated = Default_Activated
	End
	
	' Methods:
	
	' Input related:
	#If INPUTMANAGER_ENABLED
		Method Get_Device_HitState:Int(KeyCode:Int)
			Return KeyHit(KeyCode)
		End
		
		Method Get_Device_DownState:Int(KeyCode:Int)
			Return KeyDown(KeyCode)
		End
		
		Method Detect_KeyHit:Int(KeyCode:Int)
			Return Get_Device_HitState(KeyCode)
		End
		
		Method Detect_KeyDown:Int(KeyCode:Int)
			Return Get_Device_DownState(KeyCode)
		End
	#End
	
	' Properties:
	#If INPUTMANAGER_OPTIMIZE_MEMORY
		Method HitArraySize:Int() Property
			Return HIT_ARRAY_SIZE
		End
		
		Method DownArraySize:Int() Property
			Return DOWN_ARRAY_SIZE
		End
	#End
	
	Method DeviceID:UShort() Property
		Return DEVICE_ID
	End
	
	' Fields:
	' Nothing so far.
End

Class MouseDevice Extends InputDevice Final
	' Constant variable(s):
	
	' Most systems don't support multi-mouse setups, but maybe some-day...
	Const MOUSE_PRIMARY:Int			= 0
	
	Const DEVICE_ID:UShort			= 1
	
	Const HIT_ARRAY_SIZE:Int		= 3
	Const DOWN_ARRAY_SIZE:Int		= HIT_ARRAY_SIZE ' 3
	
	' Other key / button codes:
	Const MOUSE_DATA:= MOUSE_MIDDLE + 1
	
	' Defaults:
	Const Default_LimitPosition:Bool = True
	Const Default_Activated:Bool = True
	
	' Constructor(s):
	Method New(Parent:InputManager, MouseID:Int=MOUSE_PRIMARY)
		Super.New(Parent, HIT_ARRAY_SIZE, DOWN_ARRAY_SIZE, MouseID)
		
		Self.LimitPosition = Default_LimitPosition
		Self.Activated = Default_Activated
	End
	
	' Destructor(s):
	Method Free:Bool()
		' Call the super-class's implementation.
		If (Not Super.Free()) Then Return False
		
		' Nothing else so far.
		
		' Return the default response.
		Return True
	End
	
	' Methods:
		
	' Input related:
	#If INPUTMANAGER_ENABLED
		Method Get_Device_HitState:Int(MouseCode:Int)
			Return MouseHit(MouseCode)
		End
		
		Method Get_Device_DownState:Int(MouseCode:Int)
			Return MouseDown(MouseCode)
		End
		
		Method Detect_MouseHit:Int(MouseCode:Int)
			Return Get_Device_HitState(MouseCode)
		End
		
		Method Detect_MouseDown:Int(MouseCode:Int)
			Return Get_Device_DownState(MouseCode)
		End
	#End
	
	Method UpdateButton:Void(B:InputButton)
		Select B.KeyCode
			Case MOUSE_DATA
				'#If Not INPUTMANAGER_OPTIMIZE_MEMORY
				B.X = X ' HitArray[MOUSE_LEFT]
				B.Y = Y ' DownArray[MOUSE_LEFT]
				'#End
			Default
				GetValue(B)
		End Select
		
		Return
	End
	
	' Properties:
	#If INPUTMANAGER_OPTIMIZE_MEMORY
		Method HitArraySize:Int() Property
			Return HIT_ARRAY_SIZE
		End
		
		Method DownArraySize:Int() Property
			Return DOWN_ARRAY_SIZE
		End
	#End
	
	Method X:Float() Property
		Return X(LimitPosition)
	End
	
	Method Y:Float() Property
		Return Y(LimitPosition)
	End
	
	Method X:Float(Limit:Bool) Property
		#If INPUTMANAGER_ENABLED
			#If AUTOFIT_IMPLEMENTED
				Return VMouseX(Limit)
			#Else
				Return RealX
			#End
		#Else
			Return 0.0
		#End
	End
	
	Method Y:Float(Limit:Bool) Property
		#If INPUTMANAGER_ENABLED
			#If AUTOFIT_IMPLEMENTED
				Return VMouseY(Limit)
			#Else
				Return RealY
			#End
		#Else
			Return 0.0
		#End
	End
	
	Method RealX:Float() Property
		#If INPUTMANAGER_ENABLED
			Return MouseX()
		#Else
			Return 0.0
		#End
	End
	
	Method RealY:Float() Property
		#If INPUTMANAGER_ENABLED
			Return MouseY()
		#Else
			Return 0.0
		#End
	End
	
	Method DeviceID:UShort() Property
		Return DEVICE_ID
	End
	
	' Fields:
	Field LimitPosition:Bool
End

Class ControllerDevice Extends InputDevice Final
	' Constant variable(s):
	Const CONTROLLER_PRIMARY:Int	= 0
	
	#If INPUTMANAGER_CONTROLLERS_MAXBUTTONS
		Const MAXIMUM_CONTROLLER_BUTTONS:Int		= 32
	#Else
		Const MAXIMUM_CONTROLLER_BUTTONS:Int		= 16
	#End
	
	Const DEVICE_ID:UShort = 2
	
	Const HIT_ARRAY_SIZE:Int		= MAXIMUM_CONTROLLER_BUTTONS
	Const DOWN_ARRAY_SIZE:Int		= MAXIMUM_CONTROLLER_BUTTONS ' HIT_ARRAY_SIZE
	
	' Other key / button codes:
	Const JOY_LEFTANALOG:Int = MAXIMUM_CONTROLLER_BUTTONS+1
	Const JOY_RIGHTANALOG:Int = MAXIMUM_CONTROLLER_BUTTONS+2
	Const JOY_TRIGGERS:Int = MAXIMUM_CONTROLLER_BUTTONS+3
	
	' These are for those who want to separate triggers (Not the best approach, but it works):
	Const JOY_LEFTTRIGGER:Int = MAXIMUM_CONTROLLER_BUTTONS+4
	Const JOY_RIGHTTRIGGER:Int = MAXIMUM_CONTROLLER_BUTTONS+5
	
	' These will give the user directional values for the controller/joypad's "D-Pad":
	
	' This will give you X and Y values based on the "D-Pad"'s buttons.
	' This can be useful for games which use 'JOY_LEFTANALOG'.
	Const JOY_HAT:Int = MAXIMUM_CONTROLLER_BUTTONS+6
	
	#Rem
		This will give you the exact direction/rotation of the "D-Pad" (In degrees).
		The extracted data is stored in the 'InputButton' object's 'X' variable/property.
		
		This effect is more accurate to the actual 'JoyHat' command,
		but may not be what you're looking for.
	#End
	
	Const JOY_HAT_DIRECTION:Int = MAXIMUM_CONTROLLER_BUTTONS+7
	
	' Defaults:
	
	' See the 'MaximumTriggerLogSize' field's comments for details.
	Const Default_MaximumTriggerLogSize:Int = 8 ' 16
	
	Const Default_TriggerUp_BeginThreshold:Float = 0.75
	
	' Booleans / Flags:
	Const Default_Activated:Bool = False
	
	' Button / Key codes:
	Const DEFAULT_ACTIVATION_BUTTON:= JOY_A
	
	' Global variable(s):
	
	' XInput related:
	#If INPUTMANAGER_USE_XINPUT
		Global XInputDevices:XInputDevice[InputManager.CONTROLLER_COUNT] ' XUSER_MAX_COUNT
	#End
	
	' Functions (Public):
	Function HardwarePluggedIn:Bool(ControllerID:UShort)
		#If Not INPUTMANAGER_USE_XINPUT
			Return JoyPresent(ControllerID)
		#Else
			Return EnableXInputDevice(ControllerID)
		#End
	End
	
	' This is just a quick wrapper for the 'JoyCount' command:
	Function HardwareCount:UShort()
		Return JoyCount()
	End
	
	' Functions (Private):
	Private
	
	#If INPUTMANAGER_USE_XINPUT
		Function EnableXInputDevice:Bool(ControllerID:UShort)
			If (XInputDevice.DevicePluggedIn(ControllerID)) Then
				Local Device:= GetXInputDevice(ControllerID)
				
				If (Device = Null) Then
					XInputDevices[ControllerID] = New XInputDevice(ControllerID)
				Endif
				
				Return True
			Endif
			
			Return False
		End
		
		Function GetXInputDevice:XInputDevice(ControllerID:UShort)
			Return XInputDevices[ControllerID]
		End
		
		Function JoyX:Float(Axis:Int=0, ControllerID:Int=0)
			Local Device:= GetXInputDevice(ControllerID)
			
			If (Device = Null) Then
				Return 0.0
			Endif
			
			Return Device.JoyX(Axis)
		End
		
		Function JoyY:Float(Axis:Int=0, ControllerID:Int=0)
			Local Device:= GetXInputDevice(ControllerID)
			
			If (Device = Null) Then
				Return 0.0
			Endif
			
			Return Device.JoyY(Axis)
		End
		
		Function JoyZ:Float(Axis:Int=0, ControllerID:Int=0)
			Local Device:= GetXInputDevice(ControllerID)
			
			If (Device = Null) Then
				Return 0.0
			Endif
			
			Return Device.JoyZ(Axis)
		End
		
		Function JoyHit:Int(MojoButton:Int, ControllerID:Int=0)
			Local Device:= GetXInputDevice(ControllerID)
			
			If (Device = Null) Then
				Return 0
			Endif
			
			Return Device.JoyHit(MojoButton)
		End
		
		Function JoyDown:Int(MojoButton:Int, ControllerID:Int=0)
			Local Device:= GetXInputDevice(ControllerID)
			
			If (Device = Null) Then
				Return 0
			Endif
			
			Return Device.JoyDown(MojoButton)
		End
	#End
	
	Public
	
	' Constructor(s):
	Method New(Parent:InputManager, ControllerID:UShort=CONTROLLER_PRIMARY, ActivationCallback:ControllerActivationCallback, ActivationStack:Stack<Int>=Null, MaximumTriggerLogSize:Int=Default_MaximumTriggerLogSize, TriggerUp_BeginThreshold:Float=Default_TriggerUp_BeginThreshold)
		Super.New(Parent, HIT_ARRAY_SIZE, DOWN_ARRAY_SIZE, ControllerID)
		
		Construct()
		
		Self.ActivationCallback = ActivationCallback
		Self.ActivationStack = ActivationStack
		
		Self.LeftTriggerLog = New FloatDeque()
		Self.RightTriggerLog = New FloatDeque()
		
		Self.TriggerUp_BeginThreshold = TriggerUp_BeginThreshold
		Self.TriggerUp_EndThreshold = 1.0-TriggerUp_BeginThreshold
		
		Self.MaximumTriggerLogSize = MaximumTriggerLogSize
		
		#If INPUTMANAGER_USE_XINPUT
			EnableXInputDevice(ControllerID)
		#End
	End
	
	Method Construct:Void()
		Self.MainAnalog = New Vector2D<Float>()
		Self.SecondAnalog = New Vector2D<Float>()
		Self.Triggers = New Vector2D<Float>()
		
		Self.Activated = Default_Activated
		
		Return
	End
	
	' Methods:
	
	' Input related:
	Method Detect:Bool()
		' Call the super-class's implementation.
		Super.Detect()
		
		#If INPUTMANAGER_ENABLED
			#If INPUTMANAGER_USE_XINPUT
				Local XInputGamepad:= GetXInputDevice(ControllerID)
				
				If (XInputGamepad = Null) Then
					Return False
				Endif
				
				XInputGamepad.Detect()
			#End
			
			If (Activated) Then
				' Analog detection (The Y axis is inverted for the sake of translation):
				MainAnalog.X = JoyX(0, ControllerID)
				MainAnalog.Y = -JoyY(0, ControllerID)
				
				SecondAnalog.X = JoyX(1, ControllerID)
				SecondAnalog.Y = -JoyY(1, ControllerID)
				
				#If INPUTMANAGER_XNA_FIXES
					Local TX:= JoyZ(0, ControllerID)
					Local TY:= JoyZ(1, ControllerID)
					
					If (TX > TY) Then
						Triggers.X = TX
						Triggers.Y = -TX
					Elseif (TY > TX) Then
						Triggers.X = -TY
						Triggers.Y = TY
					Else
						Triggers.X = 0.0
						Triggers.Y = 0.0
					Endif
				#Else
					Triggers.X = JoyZ(0, ControllerID)
					Triggers.Y = JoyZ(1, ControllerID)
				#End
				
				If (LeftTriggerLog.Length() >= MaximumTriggerLogSize) Then
					' Remove the last element of the trigger-log.
					LeftTriggerLog.PopLast()
				Endif
				
				If (RightTriggerLog.Length() >= MaximumTriggerLogSize) Then
					' Remove the last element of the trigger-log.
					RightTriggerLog.PopLast()
				Endif
				
				'If (Triggers.X > 0.0) Then
				LeftTriggerLog.PushLast(Triggers.X)
				'Endif
				
				'If (Triggers.Y > 0.0) Then
				RightTriggerLog.PushLast(Triggers.Y)
				'Endif
				
				LeftTrigger_UpState = LeftTriggerUp()
				RightTrigger_UpState = RightTriggerUp()
			Else
				If (ActivationStack <> Null) Then
					For Local Entry:= Eachin ActivationStack
						#If Not INPUTMANAGER_OPTIMIZE_MEMORY
							If (HitArray[Entry] > 0) Then
						#Else
							If (Detect_JoyHit(Entry)) Then
						#End
								Activate()
							
								Exit
							Endif
					Next
				Else
					#If Not INPUTMANAGER_OPTIMIZE_MEMORY
						If (HitArray[DEFAULT_ACTIVATION_BUTTON] > 0) Then
					#Else
						If (Detect_JoyHit(DEFAULT_ACTIVATION_BUTTON) > 0) Then
					#End
							Activate()
						Endif
				Endif
			Endif
			
			' Return the default response.
			Return True
		#Else
			' Return the default response.
			Return False
		#End
	End
	
	#If INPUTMANAGER_ENABLED
		Method Get_Device_HitState:Int(Button:Int)
			Return Detect_JoyHit(Button, ControllerID)
		End
		
		Method Get_Device_DownState:Int(Button:Int)
			Return Detect_JoyDown(Button, ControllerID)
		End
		
		Method Detect_JoyHit:Int(Button:Int, Controller:Int)
			' Check if safe-mode is enabled for controllers:
			#If INPUTMANAGER_CONTROLLERS_SAFE
				' Check for errors:
				If (InvalidInput(Button, Controller)) Then
					' The input-data could not be retrieved, return zero.
					Return 0
				Endif
			#End
			
			#If INPUTMANAGER_CONTROLLERS_MAXBUTTONS
				Return KeyHit(JoyToKey(Button, Controller))
			#Else
				Return JoyHit(Button, Controller)
			#End
		End
		
		Method Detect_JoyDown:Int(Button:Int, Controller:Int)
			' Check if safe-mode is enabled for controllers:
			#If INPUTMANAGER_CONTROLLERS_SAFE
				' Check for errors:
				If (InvalidInput(Button, Controller)) Then
					' The input-data could not be retrieved, return zero.
					Return 0
				Endif
			#End
			
			#If INPUTMANAGER_CONTROLLERS_MAXBUTTONS
				Return KeyDown(JoyToKey(Button, Controller))
			#Else
				Return JoyDown(Button, Controller)
			#End
		End
		
		Method JoyToKey:Int(Button:Int, Controller:Int)
			' Translate the input into a standard key-code.
			Return KEY_JOY0 + (Controller*MAXIMUM_CONTROLLER_BUTTONS) + Button
		End
		
		Method InvalidInput:Bool(Button:Int, Controller:Int)
			Return ((Controller < 0 Or Controller >= InputManager.CONTROLLER_COUNT) Or (Button < 0 Or Button >= MAXIMUM_CONTROLLER_BUTTONS))
		End
		
		' These are just shorthand for the main implementations:
		Method Detect_JoyHit:Int(Button:Int)
			Return Get_Device_HitState(Button)
		End
		
		Method Detect_JoyDown:Int(Button:Int)
			Return Get_Device_DownState(Button)
		End
		
		Method JoyToKey:Int(Button:Int)
			Return JoyToKey(Button, ControllerID)
		End
		
		Method InvalidInput:Bool(Button:Int)
			Return InvalidInput(Button, ControllerID)
		End
	#End
	
	Method Activate:Void()
		' Set the activation flag to 'True'.
		Activated = True
		
		If (ActivationCallback <> Null) Then
			' Call the activation call-back.
			ActivationCallback.OnControllerActivation(ControllerID, Parent)
			
			' Set the activation call-back to 'Null'.
			ActivationCallback = Null
		Endif
		
		' Set the activation list to 'Null'.
		ActivationStack = Null
		
		Return
	End
	
	Method UpdateButton:Void(B:InputButton)
		Select B.KeyCode
			Case JOY_LEFTANALOG
				B.X = MainAnalog.X
				B.Y = MainAnalog.Y
			Case JOY_RIGHTANALOG
				B.X = SecondAnalog.X
				B.Y = SecondAnalog.Y
			Case JOY_TRIGGERS
				B.X = Triggers.X
				B.Y = Triggers.Y
				
				CopyTriggerHitState(B)
			Case JOY_LEFTTRIGGER
				B.X = Triggers.X
				
				#If INPUTMANAGER_CONTROLLERS_COPY_UNUSED_TRIGGER_DATA
					B.Y = B.X
				#End
				
				CopyTriggerHitState(B)
			Case JOY_RIGHTTRIGGER
				#If INPUTMANAGER_CONTROLLERS_INTUITIVE_TRIGGERS
					B.X = Triggers.Y
				#Else
					B.Y = Triggers.Y
				#End
				
				#If INPUTMANAGER_CONTROLLERS_COPY_UNUSED_TRIGGER_DATA
					#If INPUTMANAGER_CONTROLLERS_INTUITIVE_TRIGGERS
						B.Y = B.X
					#Else
						B.X = B.Y
					#End
				#End
				
				CopyTriggerHitState(B)
			Case JOY_HAT
				#If Not INPUTMANAGER_OPTIMIZE_MEMORY
					B.X = Joy_DPadDirection(DownArray[JOY_LEFT], DownArray[JOY_RIGHT])
					B.Y = Joy_DPadDirection(DownArray[JOY_DOWN], DownArray[JOY_UP])
				#Else
					B.X = Joy_DPadX(ControllerID)
					B.Y = Joy_DPadY(ControllerID)
				#End
			Case JOY_HAT_DIRECTION
				#If Not INPUTMANAGER_OPTIMIZE_MEMORY
					B.X = JoyHat(DownArray[JOY_UP], DownArray[JOY_DOWN], DownArray[JOY_LEFT], DownArray[JOY_RIGHT])
				#Else
					B.X = JoyHat(ControllerID)
				#End
			Default
				GetValue(B)
		End Select
		
		Return
	End
	
	' These routines are based on the standard input-logging this class uses for trigger-data:
	Method CopyTriggerHitState:Void(B:InputButton)
		B.LeftHit = LeftTrigger_UpState
		B.RightHit = RightTrigger_UpState
		
		Return
	End
	
	Method LeftTriggerUp:Bool()
		Return LeftTriggerUp(TriggerUp_BeginThreshold, TriggerUp_EndThreshold)
	End
	
	Method LeftTriggerUp:Bool(BeginThreshold:Float)
		Return LeftTriggerUp(BeginThreshold, 1.0-BeginThreshold)
	End
	
	Method LeftTriggerUp:Bool(BeginThreshold:Float, EndThreshold:Float)
		Return TriggerUp(LeftTriggerLog, BeginThreshold, EndThreshold)
	End
	
	Method RightTriggerUp:Bool()
		Return RightTriggerUp(TriggerUp_BeginThreshold, TriggerUp_EndThreshold)
	End
	
	Method RightTriggerUp:Bool(BeginThreshold:Float)
		Return RightTriggerUp(BeginThreshold, 1.0-BeginThreshold)
	End
	
	Method RightTriggerUp:Bool(BeginThreshold:Float, EndThreshold:Float)
		Return TriggerUp(RightTriggerLog, BeginThreshold, EndThreshold)
	End
	
	Method TriggerUp:Bool(TriggerLog:FloatDeque, BeginThreshold:Float)
		Return TriggerUp(TriggerLog, BeginThreshold, 1.0-BeginThreshold)
	End
	
	Method TriggerUp:Bool(TriggerLog:FloatDeque, BeginThreshold:Float, EndThreshold:Float)
		' Constant variable(s):
		Const STATE_DEFAULT:Bool = False
		Const STATE_WAITING_FOR_UP:Bool = True
		
		' Local variable(s):
		Local CloseEarly:Bool = True
		
		' Check if we should even bother continuing:
		For Local I:= 0 Until TriggerLog.Length()
			' Check if we have an entry worth using:
			If (TriggerLog.Get(I) <= EndThreshold) Then
				' We were able to find a trigger-state in the snapshot,
				' which was not a held or intermediate state.
				CloseEarly = False
				
				' No further checking is required;
				' exit the current loop here.
				Exit
			Endif
		Next
		
		' Check if we should close early:
		If (CloseEarly) Then
			Return False
		Endif
		
		' This will be the state of the main loop.
		Local State:= STATE_DEFAULT
		
		While (Not TriggerLog.IsEmpty())
			' Grab the next trigger-entry from the trigger-log specified.
			Local Trigger:= TriggerLog.PopFirst()
			
			Select State
				Case STATE_DEFAULT
					' Before we can detect if the trigger has stopped being held,
					' we first need to be sure it actually was held:
					If (Trigger >= BeginThreshold) Then
						' We found a valid trigger-state,
						' enter the next phase of the loop.
						State = STATE_WAITING_FOR_UP
					Endif
				Case STATE_WAITING_FOR_UP
					' Now that we know that the trigger had been held,
					' we need to check if the trigger has been released:
					If (Trigger <= EndThreshold) Then
						' The trigger was confirmed to have
						' been released, return this information.
						Return True
					Endif
			End Select
		Wend
		
		' Return the default response;
		' if this point was reached, we were
		' unable to find a valid trigger-press.
		Return False
	End
	
	' Properties:
	Method ControllerID:UShort() Property
		Return SubDeviceID
	End
	
	Method ControllerID:Void(Value:UShort) Property
		SubDeviceID = Value
		
		Return
	End
	
	#If INPUTMANAGER_OPTIMIZE_MEMORY
		Method HitArraySize:Int() Property
			Return HIT_ARRAY_SIZE
		End
		
		Method DownArraySize:Int() Property
			Return DOWN_ARRAY_SIZE
		End
	#End
	
	Method DeviceID:UShort() Property
		Return DEVICE_ID
	End
	
	#Rem
		This is currently based on the 'Activated' field.
		This does not represent the hardware's configuration.
		This will still return 'True', even if the
		hardware isn't actually connected.
	#End
	
	Method PluggedIn:Bool() Property
		'Return HardwarePluggedIn
		Return Activated
	End
	
	Method HardwarePluggedIn:Bool() Property
		Return HardwarePluggedIn(ControllerID)
	End
	
	' Fields (Public):
	
	' Analog vectors:
	Field MainAnalog:Vector2D<Float>
	Field SecondAnalog:Vector2D<Float>
	Field Triggers:Vector2D<Float>
	
	' An object acting as a call-back for controller activation.
	Field ActivationCallback:ControllerActivationCallback
	
	' A list of key/button codes used for activation.
	Field ActivationStack:Stack<Int>
	
	' This represents the maximum size of the trigger-logs' frame-snapshots.
	Field MaximumTriggerLogSize:Int
	
	Field LeftTrigger_UpState:Bool
	Field RightTrigger_UpState:Bool
	
	' Fields (Private):
	Private
	
	Field LeftTriggerLog:FloatDeque
	Field RightTriggerLog:FloatDeque
	
	' This is used to detect if a trigger-press has potentially began.
	Field TriggerUp_BeginThreshold:Float
	
	' This is mainly used for detecting if a trigger-press has ended.
	Field TriggerUp_EndThreshold:Float
	
	Public
End

' Button-atlases
#If IOELEMENT_IMPLEMENTED
Class ButtonAtlas Implements SerializableElement
#Else
Class ButtonAtlas
#End
	' Constant variable(s):
	
	' I/O related:
	Const IOVersion:Int = 1
	
	' Modes:
	Const MODE_INCLUSIVE:Byte = 1 ' Basically acts as 'And'.
	Const MODE_EXCLUSIVE:Byte = 2 ' Basically acts as 'Or'.
	
	' Defaults:
	Const Default_CloneStack:Bool = False
	
	' Constructor(s):	
	Method New(Buttons:Stack<InputButton>=Null, Mode:Byte=MODE_EXCLUSIVE)
		Construct(Mode, Buttons)
	End
	
	Method New(Button:InputButton, Mode:Byte=MODE_EXCLUSIVE)
		Local BStack:= New Stack<InputButton>()
		
		BStack.Push(Button)
		
		Construct(Mode, BStack, False)
	End
	
	Method New(Buttons:InputButton[], Mode:Byte=MODE_EXCLUSIVE)
		Construct(Mode, Buttons)
	End
	
	Method Construct:Void(Mode:Byte=MODE_EXCLUSIVE, Buttons:InputButton[])
		Construct(Mode, New Stack<InputButton>(Buttons), False)
		
		Return
	End
	
	Method Construct:Void(Mode:Byte=MODE_EXCLUSIVE, Buttons:Stack<InputButton>, CloneStack:Bool=Default_CloneStack)
		Self.Mode = Mode
		
		If (CloneStack) Then
			Self.Buttons = New Stack<InputButton>(Buttons.ToArray())
		Else
			Self.Buttons = Buttons
		Endif
		
		If (Self.Buttons = Null) Then
			Self.Buttons = New Stack<InputButton>()
		Endif
		
		Return
	End
	
	' Methods:
	Method Load:Bool(S:Stream)
		' Check for errors:
		If (S = Null) Then Return False
		If (S.Eof()) Then Return False
		
		' Local variable(s):
		Local Version:Int = IOVersion
		Local ButtonsAvailable:Bool = False
		Local ButtonCount:Int = 0
		
		' Format variable(s):				' |Data Type|
		Local Mode:= MODE_EXCLUSIVE			'	Byte
		
		' Load the I/O version from the stream.
		Version = S.ReadInt()
		
		Select Version
			Default
				Mode = S.ReadByte()
		End Select
		
		ButtonsAvailable = IOElement.ReadBool(S)
		
		If (ButtonsAvailable) Then
			Select IOVersion
				Default
					ButtonCount = S.ReadInt()
			End Select
			
			If (ButtonCount > 0) Then
				If (Buttons = Null) Then
					Buttons = New Stack<InputButton>()
				Endif
				
				For Local BIndex:= 1 To ButtonCount
					Local B:InputButton = New InputButton()
					
					B.Load(S)
					
					Buttons.Push(B)
				Next
			Endif
		Endif
		
		Construct(Mode, Buttons)
		
		' Return the default response.
		Return True
	End
	
	Method Save:Bool(S:Stream)
		' Check for errors:
		If (S = Null) Then Return False
		'If (S.Eof()) Then Return False
		
		' Local variable(s):
		
		' The last requirement is just acting as a bit of a fail-safe.
		Local ButtonsAvailable:Bool = (Buttons <> Null And Not Buttons.IsEmpty())
		
		S.WriteInt(IOVersion)
		
		Select IOVersion
			Default
				S.WriteByte(Mode)
		End Select
		
		IOElement.WriteBool(S, ButtonsAvailable)
		
		If (ButtonsAvailable) Then
			Select IOVersion
				Default
					S.WriteInt(Buttons.Length())
			End Select
			
			For Local B:= Eachin Buttons
				B.Save(S)
			Next
		Endif
		
		' Return the default response.
		Return True
	End
	
	' Properties:
	Method Hit:Bool() Property
		Select Mode
			Case MODE_INCLUSIVE
				' Local variable(s):
				Local ButtonCount:= Buttons.Length()
				
				' Check if we have more than one button to work with (Done for optimization purposes):
				If (ButtonCount > 1) Then
					' The reason for having multiple 'For' loops is because we need to
					' check against the 'Down' state of the other buttons,
					' and the 'Hit' state of the current button:
					For Local B:= Eachin Buttons
						Local Response:Bool = True
						
						' Check if the other buttons are being held down:
						For Local CompareButton:= Eachin Buttons
							' Make sure we're not checking against the current-button.
							If (CompareButton = B) Then Continue
							
							' Check if the current comparison-button is being held down:
							If (Not CompareButton.Down) Then
								' Tell the main loop to skip the current iteration.
								' This has to be done like this due to the nature of sub-loops.
								Response = False
								
								' Exit the current sub-loop.
								Exit
							Endif
						Next
						
						' Check if we can return at this point:
						If (Response) Then
							If (B.Hit) Then
								Return True
							Endif
						Endif
					Next
				Elseif (ButtonCount = 1) Then
					' Local variable(s):
					Local B:= Buttons.Top()
					
					' Since we only have one button, check against it specifically.
					Return (B.Hit)
				Endif
			Case MODE_EXCLUSIVE
				For Local B:= Eachin Buttons
					If (B.Hit) Then
						Return True
					Endif
				Next
		End Select
		
		' Return the default response.
		Return False
	End
	
	Method Down:Bool() Property
		Select Mode
			Case MODE_INCLUSIVE
				' Unlike the 'Hit' command, we don't need
				' to check both states of the current button:
				For Local B:= Eachin Buttons
					If (Not B.Down) Then
						Return False
					Endif
				Next
			Case MODE_EXCLUSIVE
				For Local B:= Eachin Buttons
					If (B.Down) Then
						Return True
					Endif
				Next
		End Select
		
		' Return the default response.
		Return False
	End
	
	' Fields:
	Field Buttons:Stack<InputButton>
	Field Mode:Byte
End

' 'InputButtons' are used for external device-agnostic interaction with an 'InputManager' object.
' This class does not reference any external objects which are not directly related to it.
' Therefore, this is effectively a dummy class. Dependencies like
#If IOELEMENT_IMPLEMENTED
Class InputButton Extends Vector2D<Float> Implements SerializableElement
#Else
Class InputButton Extends Vector2D<Float>
#End
	' Constant variable(s):
	
	' File-version related:
	Const IOVersion:Int = 2
	
	' Supported I/O versions:
	Const IOVersion_Initial:Int = 1
	
	' Global variable(s):
	
	' Defaults:
	Global Default_ButtonThreshold:Float = 0.75
	Global Default_CloneAtlasStack:Bool = False
	
	' Constructor(s):
	Method New(KeyCode:Int=0, Device:UShort=INPUT_DEVICE_KEYBOARD, SubDevice:UShort=0, ButtonThreshold:Float=Default_ButtonThreshold, InvertLeftValue:Bool=False, InvertRightValue:Bool=False, Atlases:Stack<ButtonAtlas>=Null, CloneAtlasStack:Bool=Default_CloneAtlasStack)
		Super.New()
		
		Construct(KeyCode, Device, SubDevice, ButtonThreshold, InvertLeftValue, InvertRightValue, Atlases, CloneAtlasStack)
	End
	
	Method Construct:Void(KeyCode:Int, Device:UShort=INPUT_DEVICE_KEYBOARD, SubDevice:UShort=0, ButtonThreshold:Float=Default_ButtonThreshold, InvertLeftValue:Bool=False, InvertRightValue:Bool=False, Atlases:Stack<ButtonAtlas>=Null, CloneAtlasStack:Bool=Default_CloneAtlasStack)
		Self.KeyCode = KeyCode
		Self.Device = Device
		Self.SubDevice = SubDevice
		Self.ButtonThreshold = ButtonThreshold
		
		Self.LeftValueIsInverted = InvertLeftValue
		Self.RightValueIsInverted = InvertRightValue
		
		If (Atlases <> Null) Then
			If (CloneAtlasStack) Then
				' This isn't the best of setups, but it works well enough.
				Self.Atlases = New Stack<ButtonAtlas>(Atlases.ToArray())
			Else
				Self.Atlases = Atlases
			Endif
		Endif
		
		Return
	End
	
	' Destructor(s):
	
	' Assuming a parent exists, this will execute
	' this object's parent's 'RemoveButton' command.
	' This command may prove unreliable under certain circumstances.
	Method Unbind:Bool(ApplyToAtlases:Bool=True)
		' Check if we have a parent to work with:
		If (Parent <> Null) Then
			If (ApplyToAtlases) Then
				If (Not ClearAtlases(Parent)) Then
					Return False
				Endif
			Endif
			
			Return Parent.RemoveButton(Self)
		Endif
		
		' Return the default response.
		Return False
	End
	
	' Methods:
	
	' Button-atlas related:
	
	' By not specifying a parent-object for these commands, you're telling this module that this has/will be taken care of.
	' Not specifying such an object will not cause this object's 'Parent' to be used. Keep this in mind while using these commands.
	Method AddAtlases:Bool(AStack:Stack<ButtonAtlas>, Parent:InputManager=Null)
		For Local A:= Eachin AStack
			If (Not AddAtlas(A, Parent)) Then
				Return False
			Endif
		Next
		
		' Return the default response.
		Return True
	End
	
	Method AddAtlas:Bool(AStack:Stack<ButtonAtlas>, Parent:InputManager=Null)
		Return AddAtlas(AStack, Parent)
	End
	
	Method AddAtlas:Bool(A:ButtonAtlas, Parent:InputManager=Null)
		' Check for errors:
		If (A = Null) Then
			Return False
		Endif
		
		CreateAtlasStack()
				
		Atlases.Push(A)
		
		If (Parent <> Null) Then
			Parent.AddAtlas(A)
		Endif
		
		' Return the default response.
		Return True
	End
	
	Method AddAtlas:Bool(B:InputButton, Parent:InputManager=Null)
		Return AddAtlas(New ButtonAtlas(B, ButtonAtlas.MODE_INCLUSIVE), Parent)
	End
	
	Method AddAtlas:Bool(BArray:InputButton[], Mode:Int=ButtonAtlas.MODE_EXCLUSIVE, Parent:InputManager=Null)
		Return AddAtlas(New ButtonAtlas(BArray, Mode), Parent)
	End
	
	Method RemoveAtlases:Bool(AStack:Stack<ButtonAtlas>, Parent:InputManager=Null)
		For Local A:= Eachin AStack
			If (Not RemoveAtlas(A, Parent)) Then
				Return False
			Endif
		Next
		
		' Return the default response.
		Return True
	End
	
	Method RemoveAtlases:Bool()
		Return ClearAtlases()
	End
	
	Method RemoveAtlas:Bool(AStack:Stack<ButtonAtlas>, Parent:InputManager=Null)
		Return RemoveAtlases(AStack, Parent)
	End
	
	Method RemoveAtlas:Bool(A:ButtonAtlas, Parent:InputManager=Null)
		' Check for errors:
		If (A = Null) Then Return False
		If (Atlases = Null) Then Return False
		
		If (Parent <> Null) Then
			Parent.RemoveAtlas(A)
		Endif
		
		Atlases.RemoveEach(A)
		
		' Return the default response.
		Return True
	End
	
	' This command removes all currently available atlases from this button:
	Method ClearAtlases:Bool()
		Return ClearAtlases(Self.Parent)
	End
	
	Method ClearAtlases:Bool(Parent:InputManager)
		' Check for errors:
		If (Atlases = Null) Then
			Return False
		Endif
		
		If (Parent = Null) Then
			Return False
		Endif
		
		For Local A:= Eachin Atlases
			RemoveAtlas(A, Parent)
		Next
		
		' Return the default response.
		Return True
	End
	
	Method CreateAtlasStack:Void()
		If (Atlases <> Null) Then
			'ClearAtlases()
			
			Return
		Endif
		
		Atlases = New Stack<ButtonAtlas>()
		
		Return
	End
	
	' I/O related:
	
	' State synchronization methods:
	#Rem
	Method Read:Bool(S:Stream)
		' Check for errors:
		If (S = Null Or S.Eof()) Then Return False
		
		HitValue = S.ReadFloat()
		DownValue = S.ReadFloat()
		
		' Return the default response.
		Return True
	End
	
	Method Write:Bool(S:Stream)
		' Check for errors:
		If (S = Null) Then Return False
		
		S.WriteFloat(HitValue)
		S.WriteFloat(DownValue)
		
		' Return the default response.
		Return True
	End
	#End
	
	' File I/O methods:
	Method Load:Bool(S:Stream)
		If (S = Null) Then Return False
		If (S.Eof()) Then Return False
		
		' Local variable(s):
		Local AtlasCount:Int = 0
		
		' Format variables:										' |Data Type|
		Local Version:= IOVersion								'	Short
		Local KeyCode:Int = 0									'	Int
		Local Device:UShort = 0									'	Short
		Local SubDevice:UShort = 0								'	Short
		Local ButtonThreshold:Float = Default_ButtonThreshold	'	Float
		Local InvertLeftValue:Bool = False						'	Bool
		Local InvertRightValue:Bool = False						'	Bool
		
		' Read the version number.
		Version = S.ReadShort()
		
		' Check if the version specified is supported:
		If (Version > IOVersion) Then
			DebugError("The file-version specified ("+Version+") was greater than the maximum supported specification ("+IOVersion+").")
			
			Return False
		Endif
		
		' Get the key-code from the stream.
		KeyCode = S.ReadInt()
		
		' Load the device info from the stream:
		
		' Check the format version:
		Select Version
			' I'm using 16-bit integers for the sake of future-proofing:
			Default
				Device = S.ReadShort()
				SubDevice = S.ReadShort()
		End Select
		
		' Read the button-activation threshold:
		
		' Check the format version:
		Select Version
			Case IOVersion_Initial
				ButtonThreshold = S.ReadFloat()
			Default
				ButtonThreshold = (Float(S.ReadByte())/100.0)
		End Select
		
		' Write the inversion flags:
		InvertLeftValue = IOElement.ReadBool(S)
		InvertRightValue = IOElement.ReadBool(S)
		
		Local AtlasesAvailable:= IOElement.ReadBool(S)
		
		If (AtlasesAvailable) Then
			AtlasCount = S.ReadInt()
			
			' Because we can't really count on 
			If (AtlasCount > 0) Then
				If (Atlases <> Null) Then
					Atlases.Clear()
				Else
					CreateAtlasStack()
				Endif
				
				For Local AIndex:= 1 To AtlasCount
					Local A:= New ButtonAtlas()
					
					A.Load(S)
					
					AddAtlas(A, Self.Parent)
				Next
			Endif
		Endif
		
		Construct(KeyCode, Device, SubDevice, ButtonThreshold, InvertLeftValue, InvertRightValue) ' The atlas-list has already been handled.
		
		' Return the default response.
		Return True
	End
	
	Method Save:Bool(S:Stream)
		' Check for errors:
		If (S = Null) Then Return False
		'If (S.Eof()) Then Return False
		
		' Local variable(s):
		
		' The last requirement is just a fail-safe.
		Local AtlasesAvailable:Bool = (Atlases <> Null And Not Atlases.IsEmpty())
		
		' Write the version number to the stream.
		S.WriteShort(IOVersion)
		
		S.WriteInt(KeyCode)
		
		' Just future-proofing:
		
		' Write the device and sub-device to the stream:
		Select IOVersion
			Default
				S.WriteShort(Device)
				S.WriteShort(SubDevice)
		End Select
		
		' Write the button-threshold to the stream:
		Select IOVersion
			Case IOVersion_Initial
				S.WriteFloat(ButtonThreshold)
			Default
				S.WriteByte(Byte(ButtonThreshold * 100.0))
		End Select
		
		' Write the inversion flags:
		IOElement.WriteBool(S, LeftValueIsInverted)
		IOElement.WriteBool(S, RightValueIsInverted)
		
		' Write a flag specifying if he have atlases.
		IOElement.WriteBool(S, AtlasesAvailable)
		
		If (AtlasesAvailable) Then
			S.WriteInt(Atlases.Length())
			
			For Local A:= Eachin Atlases
				A.Save(S)
			Next
		Endif
		
		' Return the default response.
		Return True
	End
	
	' Other:
	Method Flush:Bool()
		Zero()
		
		LeftHit = False
		RightHit = False
		
		' Return the default response.
		Return True
	End
	
	Method InvertOutput:Void()
		LeftValueIsInverted = Not LeftValueIsInverted
		RightValueIsInverted = Not RightValueIsInverted
		
		Return
	End
	
	' Properties (Public):
	#Rem
		Method ToInt:Int() Property
			Return Down
		End
	#End
	
	Method Hit:Bool() Property
		If (LeftValue < ButtonThreshold) Then
			If (Atlases <> Null) Then
				For Local BAtlas:= Eachin Atlases
					If (BAtlas.Hit) Then
						Return True
					Endif
				Next
			Endif
			
			' If this point is reached, fall-back to 'LeftHit'.
			Return LeftHit
		Endif
		
		' Return the default response.
		Return True
	End
	
	Method Down:Bool() Property
		If (RightValue < ButtonThreshold) Then
			If (Atlases <> Null) Then
				For Local BAtlas:= Eachin Atlases
					If (BAtlas.Down()) Then
						Return True
					Endif
				Next
			Endif
			
			' If this point is reached, a valid atlas could not be used.
			Return False
		Endif
		
		' Return the default response.
		Return True
	End
	
	#Rem
		These are generally used for routines where a single
		button potentially represents multiple actions.
		
		Basically, use these for movement routines:
	#End
	
	Method LeftDown:Bool() Property
		Return Hit()
	End
	
	Method RightDown:Bool() Property
		Return Down()
	End
	
	Method Pressed:Int() Property
		Return TimesPressed
	End
	
	Method TimesPressed:Int() Property
		Return Int(Value) ' Abs(Int(Floor(Value)))
	End
		
	Method LeftValue:Float() Property
		' Local variable(s):
		Local Response:Float = HitValue
		
		If (LeftValueIsInverted) Then
			Response = -Response
		Endif
		
		Return Response
	End
	
	Method LeftValue:Void(Input:Float) Property
		Self.HitValue = Input
		
		Return
	End
	
	Method RightValue:Float() Property
		' Local variable(s):
		Local Response:Float = DownValue
		
		If (RightValueIsInverted) Then
			Response = -Response
		Endif
		
		Return Response
	End
	
	Method RightValue:Void(Input:Float) Property
		Self.DownValue = Input
		
		Return
	End
	
	' Property wrappers:
	Method Value:Float() Property
		Return LeftValue()
	End
	
	Method Value:Void(Input:Float) Property
		LeftValue(Input)
		
		Return
	End
	
	Method X:Float() Property
		Return LeftValue()
	End
	
	Method X:Void(Input:Float) Property
		LeftValue(Input)
		
		Return
	End
	
	Method Y:Float() Property
		Return RightValue()
	End
	
	Method Y:Void(Input:Float) Property
		RightValue(Input)
		
		Return
	End
	
	Method Parent:InputManager() Property
		Return Self._Parent
	End
	
	' The values returned by the assigned device (Before effects; inversion, etc):
	Method HitValue:Float() Property
		Return Super.X
	End
	
	Method DownValue:Float() Property
		Return Super.Y
	End
	
	Method HitValue:Void(Input:Float) Property
		Super.X(Input)
		
		Return
	End
	
	Method DownValue:Void(Input:Float) Property
		Super.Y(Input)
		
		Return
	End
	
	' Properties (Private):
	Private
	
	Method Parent:Void(Value:InputManager) Property
		Self._Parent = Value
		
		Return
	End
	
	Public
	
	' Fields (Public):
	
	' The index used when dealing with a device's input arrays.
	Field KeyCode:Int
	
	' The device this button corresponds to.
	Field Device:UShort
	
	' The sub-device this button corresponds to.
	' A good example of sub-devices is when dealing with multiple physical devices (Controllers, for example).
	Field SubDevice:UShort
	
	' The activation threshold for floating-point data.
	Field ButtonThreshold:Float
	
	' The inversion states for both value-properties.
	Field LeftValueIsInverted:Bool
	Field RightValueIsInverted:Bool
	
	Field LeftHit:Bool
	Field RightHit:Bool
	
	' A list of aliases for this button to be activated.
	Field Atlases:Stack<ButtonAtlas>
	
	' Fields (Private):
	Private
	
	Field _Parent:InputManager
	
	Public
End

' Functions:

' Button generators:
Function MouseButton:InputButton(MouseCode:Int, ButtonThreshold:Float=InputButton.Default_ButtonThreshold, SubDevice:UShort=MouseDevice.MOUSE_PRIMARY, InvertLeftValue:Bool=False, InvertRightValue:Bool=False)
	Return New InputButton(MouseCode, INPUT_DEVICE_MOUSE, SubDevice, ButtonThreshold, InvertLeftValue, InvertRightValue)
End

Function KeyboardButton:InputButton(KeyCode:Int, ButtonThreshold:Float=InputButton.Default_ButtonThreshold, SubDevice:UShort=KeyboardDevice.KEYBOARD_PRIMARY, InvertLeftValue:Bool=False, InvertRightValue:Bool=False)
	Return New InputButton(KeyCode, INPUT_DEVICE_KEYBOARD, SubDevice, ButtonThreshold, InvertLeftValue, InvertRightValue)
End

Function ControllerButton:InputButton(ButtonCode:Int, ControllerID:UShort=ControllerDevice.CONTROLLER_PRIMARY, ButtonThreshold:Float=InputButton.Default_ButtonThreshold, InvertLeftValue:Bool=False, InvertRightValue:Bool=False)
	Return New InputButton(ButtonCode, INPUT_DEVICE_CONTROLLER, ControllerID, ButtonThreshold, InvertLeftValue, InvertRightValue)
End

' General:

' This function works similarly to BlitzBasic's implementation:
Function JoyHat:Float(ControllerID:UShort=ControllerDevice.CONTROLLER_PRIMARY)
	#If Not INPUTMANAGER_USE_XINPUT
		Return JoyHat(JoyDown(JOY_UP, ControllerID), JoyDown(JOY_DOWN, ControllerID), JoyDown(JOY_LEFT, ControllerID), JoyDown(JOY_RIGHT, ControllerID))
	#Else
		Return JoyHat(ControllerDevice.GetXInputDevice(ControllerID))
	#End
End

Function JoyHat:Float(Up:Int, Down:Int, Left:Int, Right:Int)
	' Local variable(s):
	Local X:Float = 0.0
	Local Y:Float = 0.0
	
	#If INPUTMANAGER_JOYHAT_AUTHENTIC
		' This is here because for some reason
		' BlitzBasic returns -1.0 if nothing was pressed.
		Local InputFound:Bool = False
	#End
	
	' The following input code is based on
	' the 'Joy_DPadX' and 'Joy_DPadY' commands
	' (Those aren't used for optimization reasons):
	If (Up > 0) Then
		Y = 1.0
		
		#If INPUTMANAGER_JOYHAT_AUTHENTIC
			InputFound = True
		#End
	Elseif (Down > 0) Then
		Y = -1.0
		
		#If INPUTMANAGER_JOYHAT_AUTHENTIC
			InputFound = True
		#End
	Endif
	
	If (Left > 0) Then
		X = -1.0
		
		#If INPUTMANAGER_JOYHAT_AUTHENTIC
			InputFound = True
		#End
	Elseif (Right > 0) Then
		X = 1.0
		
		#If INPUTMANAGER_JOYHAT_AUTHENTIC
			InputFound = True
		#End
	Endif
	
	#If INPUTMANAGER_JOYHAT_AUTHENTIC
		If (InputFound) Then
	#End
			' Calculate the proper angle of the D-pad.
			Return (360.0+ATan2(X, Y)) Mod 360.0
	#If INPUTMANAGER_JOYHAT_AUTHENTIC
		Endif
	#End
	
	#If INPUTMANAGER_JOYHAT_AUTHENTIC
		' Return the default response.
		Return -1.0
	#End
End

Function Joy_DPadX:Float(ControllerID:UShort=ControllerDevice.CONTROLLER_PRIMARY)
	Return Joy_DPadDirection(JoyDown(JOY_LEFT, ControllerID), JoyDown(JOY_RIGHT, ControllerID))
End

Function Joy_DPadY:Float(ControllerID:UShort=ControllerDevice.CONTROLLER_PRIMARY)
	Return Joy_DPadDirection(JoyDown(JOY_DOWN, ControllerID), JoyDown(JOY_UP, ControllerID))
End

Function Joy_DPadDirection:Float(Left:Int, Right:Int)
	If (Left > 0) Then
		Return -1.0
	Elseif (Right > 0) Then
		Return 1.0
	Endif
	
	' Return the default response.
	Return 0.0
End

' XInput extensions:
#If INPUTMANAGER_USE_XINPUT
	Function JoyHat:Float(Device:XInputDevice)
		Return JoyHat(Int(Device.ButtonDown(XINPUT_GAMEPAD_DPAD_UP)), Int(Device.ButtonDown(XINPUT_GAMEPAD_DPAD_DOWN)), Int(Device.ButtonDown(XINPUT_GAMEPAD_DPAD_LEFT)), Int(Device.ButtonDown(XINPUT_GAMEPAD_DPAD_RIGHT)))
	End
	
	Function Joy_DPadX:Float(Device:XInputDevice)
		Return Joy_DPadDirection(Int(Device.ButtonDown(XINPUT_GAMEPAD_DPAD_LEFT)), Int(Device.ButtonDown(XINPUT_GAMEPAD_DPAD_RIGHT)))
	End
	
	Function Joy_DPadY:Float(Device:XInputDevice)
		Return Joy_DPadDirection(Int(Device.ButtonDown(XINPUT_GAMEPAD_DPAD_DOWN)), Int(Device.ButtonDown(XINPUT_GAMEPAD_DPAD_UP)))
	End
#End

#Rem
	This command will accurately represent the number
	of controllers plugged into the system.
	
	Support varies from target to target. Standard behavior is to
	effectively return zero, if support is unavailable.
	
	This will be potentially slower than the less
	hardware-oriented functionality in this module.
	
	The 'InputManager' and 'ControllerDevice' classes
	have software based solutions, if you need them.
	
	Unlike the software oriented solutions, this command
	uses the platform's 'JoyPresent' implementation.
	
	Or, in the case of 'INPUTMANAGER_USE_XINPUT', 'XInputDevice.DevicePluggedIn'.
#End

Function JoyCount:Int(Controllers:Int=InputManager.CONTROLLER_COUNT, Offset:Int=InputManager.CONTROLLER_PRIMARY)
	' Local variable(s):
	Local Count:Int = 0
	
	For Local ControllerID:= Offset Until Controllers
		#If Not INPUTMANAGER_USE_XINPUT
			If (JoyPresent(ControllerID)) Then
		#Else
			If (XInputDevice.DevicePluggedIn(ControllerID)) Then
		#End
				Count += 1
		#If INPUTMANAGER_CONTROLLERS_OPTIMIZE_AVAILABILITY_CHECK
			Else
				Return Count
		#End
			Endif
	Next
	
	' Return the number of controllers we have plugged in.
	Return Count
End