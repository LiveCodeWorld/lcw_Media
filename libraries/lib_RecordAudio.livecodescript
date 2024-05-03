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
command audio_RecordTranscriptWav audioPageTitle, folderPageTitle, pWikiDomain
   if pWikiDomain is empty then put "http://transcript.thought.garden/" into pWikiDomain
   
   put audioPageTitle into LocalArray ["audioPageTitle"]
   put folderPageTitle into LocalArray ["folderPageTitle"]
   --
   put fedwiki_ConstructSlug (audioPageTitle) into audioPageSlug
   put fedwiki_ConstructSlug (folderPageTitle) into folderPageSlug
   --
   put audioPageSlug into LocalArray ["audioPageSlug"]
   put folderPageSlug into LocalArray ["folderPageSlug"]
   put pWikiDomain into LocalArray ["wikiDomain"]
   
   # Construct audio paths
   put transcribe_ConstructAudioFile (audioPageSlug, "wav", pWikiDomain) into wavFile
   put transcribe_ConstructRawAudioFile (audioPageSlug, folderPageSlug, pWikiDomain, "pcm") into pcmFile
   
   # Store for audio_StopRecordingAndCreate
   put wavFile into LocalArray ["wavFile"]
   put pcmFile into LocalArray ["pcmFile"]
   
   if there is a file pcmFile then 
      return pcmFile -- use it don;t overrecord
   else
      # Create Pcm Folder
      set the itemdelimiter to slash
      put pcmFile into pcmFolder
      put empty into item -1 of pcmFolder
      folder_CreateNested pcmFolder
      
      # Start Recording in PCM folder
      mergMicrophoneSetAudioFormat "Linear PCM" -- default
      mergMicrophoneStartRecording pcmFile
   end if
   --
   return pcmFile
end audio_RecordTranscriptWav

command audio_StopRecordingAndCreate valueArray, pNotify
   # Stop recording
   mergMicrophoneStopRecording
   put the result into mResult
   
   # Notify
   if pNotify is not false then
      lcw_NOtify "Stopped recording. Now saving file..."
   end if
   
   switch mResult
      case "not recording"
         put valueArray ["pageTitle"] into audioPageTitle
         put valueArray ["wikiDomain"] into wikiDomain
         --
         put audio_StoppedPagedArray (audioPageTitle, wikiDomain) into pageArray
         break
      case "already recording"
      case "recording failed"
         breakpoint
         break
      default
         # Varaibles from audio_RecordTranscriptWav
         put LocalArray ["wavFile"] into wavFile
         put LocalArray ["pcmFile"] into pcmFile
         
         # Convert PCM to Wav
         if there is not a file wavFile then
            # Notify
            if pNotify is not false then
               lcw_NOtify "Converting auio to wav..."
            end if
            
            ffmpeg_ExportAudioAsWav pcmFile, wavFile
            get the result
         end if
         
         # Create Transcript
         put LocalArray ["wikiDomain"] into wikiDomain
         put LocalArray ["audioPageSlug"] into audioPageSlug
         put transcribe_TextFile (audioPageSlug, wikiDomain) into textFile
         if there is not a file textFile then
            # Notify
            if pNotify is not false then
               lcw_NOtify "Trtanscribing wav file using Whisper. This might take some time..."
            end if
            
            whisper_CreateTranscript wavFile
         end if
         
         put LocalArray ["audioPageTitle"] into audioPageTitle
         put audio_StoppedPagedArray (audioPageTitle, wikiDomain) into pageArray
         delete variable LocalArray
   end switch
   --
   return pageArray
end audio_StopRecordingAndCreate

function audio_StoppedPagedArray audioPageTitle, wikiDomain
   put fedwiki_ConstructSlug (audioPageTitle) into audioPageSlug
   --
   put transcribe_WavURL (audioPageSlug, wikiDomain) into audioUrl
   put transcribe_GetWavText (audioPageSlug, wikiDomain) into sTranscript
   
   # Construct Stopped pageArray
   put "Stopped" && audioPageTitle into dialogueTitle
   put "Here is the recent raw audiofile and transcript." into sMarkdown
   put pageArray_Construct (dialogueTitle, sMarkdown, "markdown") into pageArray
   
   # Add Audio Section
   pageArray_AddMarkdown pageArray, "# Audio"
   put "Audio recorded on" && the internet date into audioText
   pageArray_AddAudio pageArray, audioUrl, audioText
   
   # Add Transcript Section
   pageArray_AddMarkdown pageArray, "# Transcript"
   pageArray_AddMarkdown pageArray, sTranscript
   
   # Add Tools
   pageArray_AddMarkdown pageArray, "# Tools"
   pageArray_AddMarkdown pageArray, "Click on the button below to use [[ChatGPT]] to process the transcript."
   --
   put audioPageTitle into valueArray ["pageTitle"]
   put audioPageSlug into valueArray ["audioPageSlug"]
   put wikiDomain into valueArray ["wikiDomain"]
   --
   put "http://rest.livecode.world/transcribe/tidy_Transcript" into postURL
   pageArray_AddButton pageArray, "Tidy Transcript", postURL, valueArray
   
   return pageArray
end audio_StoppedPagedArray


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
   # Stop recording
   mergMicrophoneStopRecording
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
end audio_StopRecording


--> Props
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

