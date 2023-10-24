script "behavior_ViewAudio"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewAudio
type: behavior
version: 0.1

--> Variables
-
constant ControllerHeight = 30

--> Working on
-
on resizeControl
   LayoutControl
end resizeControl

on LayoutControl pRect
   if pRect is empty then put the rect of me into pRect
   --
   rect_SetHeight pRect, ControllerHeight, false
   set the rect of me to pRect
end LayoutControl

getprop play_List
   return the play_List of me
end play_List

setprop play_List [playAudio] audioFiles
   set the play_List of me to audioFiles
   set the auto_PlayList of me to playAudio
   --
   put line 1 of audioFiles into audioFile
   set the audio_File [playAudio] of me to audiofile
end play_List

getprop auto_PlayList
   return the auto_PlayList of me
end auto_PlayList

setprop auto_PlayList sBoolean
   set the auto_PlayList of me to sBoolean
end auto_PlayList

on audio_ReachedEnd aDuration
   set the label of stack _StackName() to empty
   --
   put the auto_PlayList of me into playAudio
   put the play_List of me into playList
   delete line 1 of playList
   set the play_List [playAudio] of me to playList
end audio_ReachedEnd


--> Events
-
on playStarted
   set the label of stack _StackName() to the currenttime of me
end playStarted

on playPaused
   set the label of stack _StackName() to "Paused"
end playPaused

on playStopped
   put the duration of me into aDuration
   if the currentTime of me = aDuration then
      audio_ReachedEnd aDuration
   else
      -- set the label of stack _StackName() to empty
   end if
end playStopped

getprop short_File
   put the fileName of me into sFile
   set the itemdelimiter to "/"
   return item -1 of sFile
end short_File

on currentTimeChanged theInterval
   put the short_File of me into shortFile
   set the label of stack _StackName() to shortFile && theInterval
end currentTimeChanged

private function _StackName
   return the stack_Name of me
end _StackName


--> Sound
-
getprop audio_Playing
   return the paused of me is false
end audio_Playing

setprop audio_Playing sBoolean
   -- set the paused of me to (sBoolean is false) -- occasional crash
   if sBoolean is true then
      start me
   else
      stop me
   end if
end audio_Playing

getprop audio_File
   put the filename of me into audioFile
   return audioFile
end audio_File

setprop audio_File [playAudio] audioFile
   if there is a file audioFile then
      set the filename of me to audioFile
   end if
   if playAudio is a boolean then
      set the audio_Playing of me to playAudio
   end if
end audio_File


--> Movie
-
getprop movie_Paused
   return the paused of me
end movie_Paused

setprop movie_Paused someBoolean
   set the paused of me to someBoolean
   focus on me
end movie_Paused

getprop movie_PlayRate
   return the playrate of me
end movie_PlayRate

setprop movie_PlayRate someRate
   set the playrate of me to someRate
   focus on me
end movie_PlayRate

--> Objects
-
getprop audio_View
   return the long id of me
end audio_View
