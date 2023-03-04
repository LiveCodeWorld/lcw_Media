script "model_SvgLibrary"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_SvgLibrary
type: model
version: 0.1


--> Icon | Model
-
command icon_Delete iconName, iFamilyName
   -- cant find deleteIcon (there is addIcon)
   /*
   setCurrentIconFamily iFamilyName
   put getCurrentIconFamily() into oFamilyName
   setCurrentIconFamily iFamilyName
   --
   put iconData() into iData
   delete iData [iName]
   */
   
   put iconDataForFamily (iFamilyName) into iconData
   delete variable iconData [iconName]
   --
   icon_RemoveFamily iFamilyName
   addIconFamily iFamilyName, iconData
   --
   -- setCurrentIconFamily oFamilyName
   return iconData
end icon_Delete

command icon_LoadFamily iFamilyName, pDisplay
   put icon_GetLibrary (iFamilyName) into iconData
   --
   addIconFamily iFamilyName, iconData
   -- 
   if pDisplay is true then
      display_IconFamily iFamilyName
   end if
   return iconData
end icon_LoadFamily

command icon_RemoveFamily iFamilyName
   setCurrentIconFamily "fontawesome"
   deleteIconFamily iFamilyName
end icon_RemoveFamily

function icon_ListLibraries
   put the array_Models of me into iconLibNames
   replace ".array" with empty in iconLibNames
   return iconLibNames
end icon_ListLibraries

function icon_GetLibrary iFamilyName
   return the array_Data [iFamilyName] of me
end icon_GetLibrary

command icon_SetLibrary iFamilyName
   put iconDataForFamily (iFamilyName) into iconData
   --
   set the array_Data [iFamilyName] of me to iconData
   put the result into modelArrayFile
   return modelArrayFile
end icon_SetLibrary

function icon_GetModelDataFile iFamilyName
   -- get the model_DataFile [iFamilyName] of me
   -- get the model_DataFolder [iFamilyName] of me
   --
   put the project_Folder of me into projectFolder
   put iFamilyName & ".array" into shortFile
   put model_GetDataFile ("IconFamily", projectFolder, shortFile) into modelDataFile
   return modelDataFile
end icon_GetModelDataFile
