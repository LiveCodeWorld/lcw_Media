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
   -- display_TrelloSelectedCard displayView
   
   ## Check files
   put _ListShortAudioFiles (displayView) into LocalArray ["shortAudioFiles"]
   put _AudioFilePath (displayView) into LocalArray ["audioFile"]
   --
   return displayView
end menu_Target

private function _RecordingFolder displayView
   put the recording_Folder of displayView into mFolder
   if there is a folder mFolder then return mFolder
   
   ## Default
   put the module_AssetFolder of stack "View|Trello" into mFolder
   folder_CreateNested mFolder
   return mFolder
end _RecordingFolder

private function _AudioFilePath displayView
   put _RecordingFolder(displayView) into mFolder
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

private function _AudioFromShortFile shortFile, displayView
   put _RecordingFolder (displayView) into mFolder
   put mFolder & shortFile into audioFile
   return audioFile
end _AudioFromShortFile

private function _ListShortAudioFiles displayView
   put _RecordingFolder (displayView) into mFolder
   put file_ListShort (mFolder) into shortFiles
   return shortFiles
end _ListShortAudioFiles

private function _SelectedCardID displayView
   put the view_Data of displayView into vData
   put the selected_Line of displayView into lineNum
   put vData [lineNum]["id"] into cardID
   return cardID
end _SelectedCardID

function _SelectedShortName displayView
   put the view_Data of displayView into vData
   -- put the selected_Line of displayView into lineNum
   put the selected_LineNumber of displayView into lineNum
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

private function _TrelloCardView
   put display_FindCloned ("View|Image", "Trello Card") into trelloCardView
   return trelloCardView
end _TrelloCardView

getprop disabled_RecordAudio
   if there is a file LocalArray ["audioFile"] then
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

getprop playAudio_Param [displayView]
   put the selected_AudioFile of displayView into audioFile
   set the itemdelimiter to slash
   return item -1 of audioFile
end playAudio_Param

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
   put _AudioFromShortFile (shortFile, displayView) into audioFile
   --
   -- delete file audioFile
   revDeleteFile audioFile
end menu_DeleteAudio

private on _
end _

on menu_PlayAudio displayView, shortFile
   put _AudioFromShortFile (shortFile, displayView) into audioFile
   --
   audio_Play audioFile
   -- put view_GetTemplateObject ("View|Audio") into audioPlayer
   -- set the audio_File [true] of audioPlayer to audioFile
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

private on ___
end ___

on menu_ExportSlides displayView
   put _RecordingFolder (displayView) into mFolder
   --
   put the view_Data of displayView into vData
   put the displayed_Index of displayView into someIndex
   put the number of lines of someIndex into maxNum
   --
   repeat with lineNum = 1 to maxNum   
      display_Spin lineNum, displayView, "dark green"
      put vData [lineNum]["id"] into cardID
      --
      put trello_GetCard (cardID) into cardData
      if cardData is not an array then next repeat
      --
      put cardData ["name"] into cardName
      put cardData ["labels"] into labelData
      put cardData ["attachments"][1]["url"] into bigURL
      --
      put mFolder & cardName into imagePath
      put url bigURL into url ("binfile:" & imagePath)
   end repeat
end menu_ExportSlides

on menu_SetRecordingFolder displayView
   put _RecordingFolder (displayView) into mFolder
   answer folder prompt with mFolder
   if it is empty then exit to top
   
   put it & slash into mFolder
   set the recording_Folder of displayView to mFolder
end menu_SetRecordingFolder

on menu_RevealRecording displayView
   put _RecordingFolder (displayView) into mFolder
   --
   finder_Reveal mFolder
end menu_RevealRecording

private on ____
end ____

on submenu_Dev
   return menu_DevTitle ("Global | Audio | Record | Menu")
end submenu_Dev
