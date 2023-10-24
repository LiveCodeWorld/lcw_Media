script "lib_RecordAudio"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_RecordAudio
type: library
version: 0.1

/*Some help*/

--> Variables
-
local LocalArray


--> Working on
-
getprop recording_Folder
   put the long id of the target into tObject
   --
   set lockmessages to true
   put the recording_Folder of tObject into mFolder
   set lockmessages to false
   if there is a folder mFolder then return mFolder
   
   ## Default
   put the module_AssetFolder of tObject into mFolder
   folder_CreateNested mFolder
   return mFolder
end recording_Folder


--> Display
-
on mDoubleUp_AudioRecord displayView, someLine
   breakpoint
   put the title_Text of displayView into someTitle
end mDoubleUp_AudioRecord

command display_RocketRecordings pListName
   if pListName is empty then put "Inbox" into pListName
   --
   put trello_RocketCardNames (pListName) into rocketIndex
   replace ".jpg" with empty in rocketIndex
   --
   display_RecordingList rocketIndex, pListName
   put the result into displayView
   --
   return displayView
end display_RocketRecordings

command display_RecordingList pIndex, pTitle
   if pIndex is empty then
      put trello_RocketCardNames () into pIndex
      replace ".jpg" with empty in pIndex
   end if
   --
   if pTitle is empty then put "Index" into pTitle
   --
   display_Data pIndex, pTitle, "Recordings"
   put the result into displayView
   --
   display_SetMouseAndMenu displayView, "Trello | List", "lcw_Media"
   return displayView
end display_RecordingList


--> Audio | Files
-
getprop audio_Files [listShort]
   put the recording_Folder of the target into rFolder
   if listShort is true then
      return file_ListShort (mFolder)
   else
      return file_ListLong (mFolder)
   end if
end audio_Files

getprop audio_File [shortName]
   if shortName is empty then put the short name of the target into shortName
   --
   put the recording_Folder of the target into rFolder
   put audio_GetFilePath (shortName, rFolder) into audioFile
   return audioFile
end audio_File

function audio_GetFilePath shortName, pFolder, pFormatName
   if pFolder is empty then put audio_DefaultFolder() into pFolder
   put audio_RecordingFileExtension (pFormatName) into fExt
   --
   put pFolder & shortName & "." & fExt into sPath
   return sPath
end audio_GetFilePath

command audio_DeleteAudio shortName, pFolder, pFormatName
   put audio_GetFilePath (shortName, pFolder, pFormatName) into audioFile
   --
   -- delete file audioFile
   revDeleteFile audioFile
end audio_DeleteAudio

function audio_DefaultFolder
   put view_GetTemplateObject("View|Audio") into tObject
   put the module_AssetFolder of tObject into rFolder
   folder_CreateNested rFolder
   return rFolder
end audio_DefaultFolder

function audio_RecordingFileExtension pFormatName
   if pFormatName is empty then
      put mergMicrophoneGetAudioFormat() into pFormatName
   end if
   --
   switch pFormatName
      case "Linear PCM"
         return "wav"
      case "Apple Lossless"
         return "m4a"
      case "MP4-AAC"
         return ".m4a"
      case "iLBC"
         return "ilbc"
   end switch
end audio_RecordingFileExtension

function audio_GetRandomFile audioFiles
   put the number of lines of audioFiles into maxNum
   put random (maxNum) into lineNum
   put line lineNum of audioFiles into audioFile
   return audioFile
end audio_GetRandomFile


--> Audio | Recording
-
command audio_Record displayView
   -- record sound file sPath
   -- set the recordFormat to "wav"
   
   put _AudioFilePath (displayView) into sPath
   -- 
   mergMicrophoneStartRecording sPath
   --
   switch the result
      case "already recording"
         breakpoint
         break
      case "recording failed"
         breakpoint 
         break
      default
         return the result
   end switch
end audio_Record

command audio_StopRecording
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
end audio_StopRecording


--> Record | Audio
-
command audio_SetFormat formatName
   mergMicrophoneSetAudioFormat formatName
end audio_SetFormat


--> Audio
-
command audio_Play audioFiles
   -- put _AudioFromShortFile (shortFile, displayView) into audioFile
   _SetAudioPlayer pAudioPlayer
   --
   set the play_List [true] of audioView to audioFiles
end audio_Play

command audio_Pause pAudioView
   _SetAudioPlayer pAudioPlayer
   --
   set the audio_Playing of pAudioPlayer to false
end audio_Pause

command audio_Stop pAudioPlayer
   _SetAudioPlayer pAudioPlayer
   --
   put "stop" && pAudioPlayer into doScript
   do doScript
end audio_Stop


--> Private
-
private command _SetAudioPlayer @pAudioPlayer
   if exists (pAudioPlayer) is false then
      put view_GetTemplateObject ("View|Audio") into pAudioPlayer
      return false
   else
      return true
   end if
end _SetAudioPlayer

