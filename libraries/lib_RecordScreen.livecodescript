script "lib_RecordScreen"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_RecordScreen
type: library
version: 0.1

/*Some help*/

--> Variables
-
local LocalArray


--> Props
-
getprop screen_Rect
   put the stack_Name of the target into stackName
   put the loc of stack stackName into gLoc
   --
   screen_SetNum gLoc
   put screen_RectFromLoc (gLoc) into sRect
   return sRect
end screen_Rect

getprop screen_CastFolder
   put the filename of this stack into sFolder
   --
   set the itemdelimiter to slash
   put empty into item -1 of sFolder
   return sFolder
end screen_CastFolder


--> Working on
-
getprop stack_IsProportional
   put the screen_ProportionalStackRect of the target into pRect
   rect_Normalise pRect
   put the stack_Rect of the target into sRect
   return pRect = sRect
end stack_IsProportional

getprop screen_ProportionalStackRect
   put the stack_Name of the target into stackName
   put the screen_Rect of the target into tScreenRect
   --
   put item 3 of tScreenRect - item 1 of tScreenRect into tScreenWidth
   put item 4 of tScreenRect - item 2 of tScreenRect into tScreenHeight
   
   put the height of stack stackName into sHeight
   put the rect of stack stackName into sRect
   --
   put sRect into nRect
   put sHeight * tScreenWidth / tScreenHeight into nWidth
   put (nWidth + item 1 of sRect) into item 3 of nRect
   --
   return nRect
end screen_ProportionalStackRect

command process_CloseAll
   repeat for each line pName in the openprocesses
      close process pName 
   end repeat
end process_CloseAll


--> Screen | Rect
-
function screen_BottomRight pWidth, pMargin
   if pWidth is empty then put 340 into pWidth
   if pMargin is empty then put 32 into pMargin
   --
   put the screenrect into cRect
   rect_SubtractMargins cRect, pMargin
   --
   put round (9/16 * pWidth) into cHeight
   --
   put item 3 of cRect - pWidth into item 1 of cRect
   put item 4 of cRect - cHeight into item 2 of cRect
   --
   return cRect
end screen_BottomRight

function screen_RectFromLoc gLoc
   get the screenRects
   repeat with lineNum = 1 to the number of lines of it
      put line lineNum of it into sRect
      if gLoc is within sRect then
         return sRect
      end if
   end repeat
   return empty
end screen_RectFromLoc

function screen_NumberFromLoc gLoc
   get the screenRects
   repeat with lineNum =1 to the number of lines of it
      put line lineNum of it into sRect
      if gLoc is within sRect then
         return lineNum
      end if
   end repeat
   return 0
end screen_NumberFromLoc

function screen_GetNum
   put LocalArray ["screenNum"] into screenNum
   if screenNum is an integer then
      return screenNum 
   else
      return 1
   end if
end screen_GetNum

command screen_SetNum screenNumOrLoc
   switch
      case screenNumOrLoc is an integer
         put screenNumOrLoc into screenNum
         break
      case screenNumOrLoc is a point
         put screen_NumberFromLoc (screenNumOrLoc) into screenNum
         break
      default
         put globalloc (the mouseloc) into gLoc
         put screen_NumberFromLoc (gLoc) into screenNum
   end switch
   --
   put screenNum into LocalArray ["screenNum"]
   return true
end screen_SetNum


--> Screen | Recording
-
function screen_IsRecording
   get the openprocesses
   if it is empty then
      delete variable LocalArray ["screenProcessName"]
      return false
   end if
   
   put LocalArray ["screenProcessName"] into screenProcessName
   put screenProcessName is among the lines of it into sBoolean
   return sBoolean
end screen_IsRecording

command screen_ToggleRecord pShortFile, pWarn
   if pShortFile is not empty then
      screen_SetShortFile pShortFile
   else
      put screen_GetShortFile() into pShortFile
   end if
   --
   if screen_IsRecording() then
      screen_StopRecording
      --
      if pWarn is true then
         lcw_Answer "Stopped recording, would you like to show the file '[[shortFile]]'?", "", pShortFile
         put screen_GetFile() into screenFile
         finder_Reveal screenFile
      end if
   else
      if pWarn is true then
         put screen_GetNum() into sNum
         lcw_Answer "Would you like to recording screen [[sNum]]?", "", sNum
      end if
      --
      screen_StartRecording
   end if
end screen_ToggleRecord

command screen_StartRecording pShortFile, pScreenNum, pScreenCastFolder
   if pScreenNum is empty then
      put screen_GetNum() into pScreenNum
   else
      screen_SetNum pScreenNum
   end if
   --
   if pScreenCastFolder is empty then
      put screen_GetCastFolder() into pScreenCastFolder
   else
      screen_SetCastFolder pScreenCastFolder
   end if
   --
   if pShortFile is empty then
      put screen_GetShortFile() into pShortFile
   else
      screen_SetShortFile pShortFile
   end if
   --
   put the defaultfolder into oFolder
   set the defaultfolder to pScreenCastFolder
   --
   put merge ("screencapture -gvD[[pScreenNum]] [[pShortFile]]") into sShell
   --
   open process sShell for update
   put the result into recordingResult
   put sShell into LocalArray ["screenProcessName"]
   --
   set the defaultfolder to oFolder
   return recordingResult
end screen_StartRecording

command screen_StopRecording
   put LocalArray ["screenProcessName"] into screenProcessName
   if screenProcessName is not among the lines of the openprocesses then
      put empty into LocalArray ["screenProcessName"]
      return empty
   end if
   --
   write space to process screenProcessName
   close process screenProcessName
   delete variable LocalArray ["screenProcessName"]
   return the result
end screen_StopRecording


--> Screen | Files
-
function screen_GetModuleFile pShortFile, pViewName
   put screen_GetModuleFolder (pViewName) into screenCastFolder
   screen_SetCastFolder screenCastFolder
   --
   return screen_GetFile (pShortFile)
end screen_GetModuleFile

function screen_GetModuleFolder viewName
   get "View|"
   if char 1 to 5 of viewName is not it then
      put it before viewName
   end if
   --
   if viewName is empty then
      put the module_AssetFolder of the topstack into screenCastFolder
   else
      put the module_AssetFolder of stack viewName into screenCastFolder
   end if
   return screenCastFolder
end screen_GetModuleFolder

function screen_GetProjectFile pShortFile, pStackName
   put screen_GetProjectFolder (pStackName) into screenCastFolder
   screen_SetCastFolder screenCastFolder
   --
   return screen_GetFile (pShortFile)
end screen_GetProjectFile

function screen_GetProjectFolder pStackName
   if pStackName is empty then
      put the project_AssetFolder of the topstack into screenCastFolder
   else
      put the project_AssetFolder of stack pStackName into screenCastFolder
   end if
   return screenCastFolder
end screen_GetProjectFolder

function screen_GetFile pShortFile
   put screen_GetCastFolder() into screenCastFolder
   --
   if pShortFile is empty then
      put screen_GetShortFile() into shortFile
      return screenCastFolder & shortFile
   else
      screen_SetShortFile pShortFile
      return screenCastFolder & pShortFile
   end if
end screen_GetFile

function screen_GetShortFile
   put LocalArray ["shortFile"] into shortFile
   --
   if shortFile is empty then
      return the seconds & ".mov"
   else
      return shortFile
   end if
end screen_GetShortFile

command screen_SetShortFile shortFile
   put shortFile into LocalArray ["shortFile"]
end screen_SetShortFile

function screen_GetCastFolder
   put LocalArray ["screenCastFolder"] into screenCastFolder
   if there is not a folder screenCastFolder then
      ## Default
      put the project_AssetFolder of me into assetFolder
      put assetFolder & "ScreenCasts/" into screenCastFolder
      folder_CreateNested screenCastFolder
      -- screen_SetCastFolder screenCastFolder
   end if
   return screenCastFolder
end screen_GetCastFolder

command screen_SetCastFolder screenCastFolder
   folder_CreateNested screenCastFolder
   put screenCastFolder into LocalArray ["screenCastFolder"]
end screen_SetCastFolder
