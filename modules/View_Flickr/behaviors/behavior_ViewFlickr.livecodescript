script "behavior_ViewFlickr"
--> MetaData
-
license: GPLv3
name: behavior_ViewFlickr
type: behavior
version: 0.1


--> Events
-
on dragEnter
   set the allowableDragActions to "link"
   set the dragAction to "link"
end dragEnter

on dragDrop
   put the dragData ["text"] into droppedURL
   if droppedURL is empty then pass dragDrop
   
   flickr_FetchAndDeconstructFromDroppedUrl droppedURL, photoTitle, photoDescription, photoURL, photoTags
   put the result into photoArray
   
   lock screen
   put photoTitle into field "Title" of me
   set the htmltext of field "Description" of me to photoDescription
   set the filename of image 1 of me to photoURL
   unlock screen
   
   if the shiftkey is "Down" then
      display_Array photoArray
   end if
end dragDrop
