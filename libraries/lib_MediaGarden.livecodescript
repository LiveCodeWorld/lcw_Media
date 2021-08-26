script "lib_MediaGarden"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_MediaGarden
type: library
version: 0.1

/*
A collection of scripts for VJ'ing Media Garden podcasts.
*/


--> Working on
-
command manyCam_SwitchCamera cameraNum
   put "tell application 'ManyCam'" into aScript
   put CR & "activate" after aScript
   put CR & "tell application 'System Events' to keystroke [[cameraNum]] using command down" after aScript
   put CR & "end tell" after aScript
   --
   replace "'" with quote in aScript
   put merge (aScript) into aScript
   --
   do aScript as "Applescript"
   --
   put aScript
end manyCam_SwitchCamera



--> Media | Garden
-
command ndi_SwitchVirtualInput ndiAlias
   _SetNdiCameraInfo ndiAlias, ndiSource, ndiCameraName
   ndi_SetVirtualInput ndiSource, ndiCameraName
   return the result   
end ndi_SwitchVirtualInput

private command _SetNdiCameraInfo ndiAlias, @ndiSource, @ndiCameraName
   -- "ndiAlias" is a nice memorable alias we give specific cameras
   switch ndiAlias
      case "Ipad"
         put "IPAD" into ndiSource
         put "NDI HX Camera" into ndiCameraName
         break
      case "Baby Webcam"
         put "DAVIDS-BABY-PRO-2.LOCAL" into ndiSource
         put "WebCam for NDI" into ndiCameraName
         break
   end switch  
end _SetNdiCameraInfo


--> NDI
-
function ndi_GetVirtualInputSources
   get _ConstructNdiAppleScript ("get name of every menu item of menu 1 of menu bar item 'Sources' of menu bar 1")
   do it as "Applescript"
   put the result into ndiSources
   --
   delete char 1 of ndiSources
   delete char -1 of ndiSources
   replace comma with CR in ndiSources
   replace quote with empty in ndiSources
   return ndiSources
end ndi_GetVirtualInputSources

command ndi_SetVirtualInput ndiSource, ndiCameraName
   put "click menu item '[[ndiCameraName]]' of menu 1 of menu item '[[ndiSource]]' of menu 1 of menu bar item 'Sources' of menu bar 1" into doLine
   get _ConstructNdiAppleScript (doLine, ndiSource, ndiCameraName)
   --
   do it as "Applescript"
   put the result into theResult
   lcw_Activate
   --
   return theResult
end ndi_SetVirtualInput

command lcw_Activate
   put "activate application 'LiveCode Indy 9.6.1 (rc 2)'" into aScript
   replace "'" with quote in aScript
   do aScript as "Applescript"
   return the result
end lcw_Activate

private function _ConstructNdiAppleScript doLine, ndiSource, ndiCameraName
   put "activate application 'NDI Virtual Input'" into aTemplate
   put CR & "tell application 'System Events'" after aTemplate
   put CR & "tell process 'NDI Virtual Input'" after aTemplate
   put CR & doLine after aTemplate
   put CR & "end tell" & CR & "end tell" after aTemplate
   --
   replace "'" with quote in aTemplate
   put merge (aTemplate) into aScript
   --
   return aScript
end _ConstructNdiAppleScript


--> Deps
-
