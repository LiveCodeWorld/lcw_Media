script "lib_Photos"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_Photos
type: library
version: 0.1

/*Some help*/


--> Working on
-
on menu_FindOriginalPhoto
   display_TestPhoto
   put "FDD24A74-161C-4BA3-A155-77F9F9F555AB" into shortFileName
   put "1D760E8E-1334-4BDA-BFBE-61745486B2DC" into shortFileName
   --
   put photos_FindOriginal (shortFileName) into imageFile
   --
   put imageFile
   -- finder_Reveal imageFile - can't reveal package contents
end menu_FindOriginalPhoto


--> Photos
-
function photos_FindOriginal shortFileName, pFileExtension
   -- find "/Users/fortyfoxes/Pictures/Photos Library.photoslibrary/originals" -name "FDD24A74-161C-4BA3-A155-77F9F9F555AB.*"
   
   switch pFileExtension
      case empty
         put shortFileName & ".*" into shortImageFile
         break
      default
         put shortFileName & "." & pFileExtension into shortImageFile
   end switch
   
   put "/Users/fortyfoxes/Pictures/Photos Library.photoslibrary/" into originalsFolder
   put "originals/" after originalsFolder
   --
   put "find" into someShell
   put space & kwote (originalsFolder) after someShell
   --
   put space & "-name" && kwote (shortImageFile) after someShell
   --
   put shell (someShell) into searchResult
   --
   return searchResult
end photos_FindOriginal



--> Deps
-
