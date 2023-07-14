script "Global | Audio | Record | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Audio | Record | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   put the display_View of tObject into displayView
   
   ## Display Card
   display_TrelloSelectedCard displayView
   
   ## Check files
   put _ListShortAudioFiles() into LocalArray ["shortAudioFiles"]
   put _AudioFilePath (displayView) into LocalArray ["soundFile"]
   --
   return displayView
end menu_Target

private function _SelectedCardID displayView
   put the view_Data of displayView into vData
   put the selected_Line of displayView into lineNum
   put vData [lineNum]["id"] into cardID
   return cardID
end _SelectedCardID

function _SelectedShortName displayView
   put the view_Data of displayView into vData
   put the selected_Line of displayView into lineNum
   --
   set the itemdelimiter to "."
   if _NamesAreUnique (vData) then
      return tolower (item 1 of vData [lineNum]["name"])
   else
      return vData [lineNum]["id"]
   end if
end _SelectedShortName

private function _NamesAreUnique vData
   set the itemdelimiter to "."
   repeat with lineNum = 1 to item 2 of the extents of vData
      put tolower (item 1 of vData [lineNum]["name"]) into cardName
      if testArray [cardName] is true then return false
      put true into testArray [cardName]
   end repeat
   return true
end _NamesAreUnique

private function _GetAudioPath cardID, dObject
   put the module_AssetFolder of dObject into mFolder
   put mFolder & cardID into sPath
   --
   return sPath
end _GetAudioPath

private function _TrelloCardView
   put display_FindCloned ("View|Image", "Trello Card") into trelloCardView
   return trelloCardView
end _TrelloCardView

private function _AudioFilePath displayView
   put the module_AssetFolder of stack "View|Trello" into mFolder
   folder_CreateNested mFolder
   --
   put _SelectedShortName (displayView) into shortName
   put mFolder & shortName into sPath
   --
   switch mergMicrophoneGetAudioFormat()
      case "Linear PCM"
         put ".wav" after sPath
         break
      case "Apple Lossless"
         put ".m4a" after sPath
         break
      case "MP4-AAC"
         put ".m4a" after sPath
         break
      case "iLBC"
         put ".ilbc" after sPath
         break
   end switch
   return sPath
end _AudioFilePath

private function _AudioFromShortFile shortFile
   put the module_AssetFolder of stack "View|Trello" into mFolder
   put mFolder & shortFile into soundFile
   return soundFile
end _AudioFromShortFile

private function _ListShortAudioFiles
   put the module_AssetFolder of stack "View|Trello" into mFolder
   put file_ListShort (mFolder) into shortFiles
   return shortFiles
end _ListShortAudioFiles

getprop disabled_RecordAudio
   if there is a file LocalArray ["soundFile"] then
      return true
   else
      return mergMicrophoneIsAvailable() is false
   end if
end disabled_RecordAudio

getprop disabled_StopRecording
   put mergMicrophoneIsRecording() into isRecording
   return isRecording is false
end disabled_StopRecording

getprop audioFormat_Param
   return mergMicrophoneGetAudioFormat()
end audioFormat_Param

getprop audioFormat_Params
   return "Linear PCM,Apple Lossless,MP4-AAC,iLBC"
end audioFormat_Params

getprop playAudio_Params [displayView]
   return LocalArray ["shortAudioFiles"]
end playAudio_Params

getprop deleteAudio_Params [displayView]
   return LocalArray ["shortAudioFiles"]
end deleteAudio_Params


--> Global | Audio | Record | Menu
-
on menu_RecordAudio displayView
   put _AudioFilePath (displayView) into sPath
   --
   -- record sound file sPath
   -- set the recordFormat to "wav"
   
   mergMicrophoneStartRecording sPath
   --
   switch the result
      case "already recording"
         breakpoint
         break
      case "recording failed"
         breakpoint  break
   end switch
end menu_RecordAudio

on menu_StopRecording
   -- stop recording
   mergMicrophoneStopRecording
   --
   switch the result
      case "already recording"
         breakpoint
         break
      case "recording failed"
         breakpoint
         break
   end switch
end menu_StopRecording

on menu_DeleteAudio displayView, shortFile
   put _AudioFromShortFile (shortFile) into soundFile
   --
   -- delete file soundFile
   revDeleteFile soundFile
end menu_DeleteAudio

private on _
end _

on menu_PlayAudio displayView, shortFile
   put _AudioFromShortFile (shortFile) into soundFile
   put the selected_AudioFile of displayView into soundFile
   --
   audio_Play soundFile
end menu_PlayAudio

on menu_StopAudio
   -- put the sound into sName
   -- stop playing audioClip sName
   audio_Pause
end menu_StopAudio

private on __
end __

on menu_AudioFormat displayView, formatName
   mergMicrophoneSetAudioFormat formatName
end menu_AudioFormat

on menu_RevealRecording
   put the module_AssetFolder of stack "View|Trello" into mFolder
   --
   finder_Reveal mFolder
end menu_RevealRecording
