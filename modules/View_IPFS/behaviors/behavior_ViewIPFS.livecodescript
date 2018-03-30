script "behavior_ViewIPFS"
--> MetaData
-
license: GPLv3
name: behavior_ViewIPFS
type: behavior
version: 0.2


--> Props
-
getprop image_FileName
   put the filename of _imageObject() into someFile
   return someFile
end image_FileName

setprop image_FileName fileOrUrl
   put _imageObject() into imageObject
   set the filename of imageObject to fileOrUrl
   return imageObject
end image_FileName

getprop browser_URL
   put the url of _browserWidget() into someURL
   return someURL
end browser_URL

setprop browser_URL someURL
   put _browserWidget() into browserWidget
   set the url of browserWidget to someURL
   return browserWidget
end browser_URL

getprop display_Type
   switch
      case visible of _browserWidget() is true
         return "browser"
      case visible of _imageObject() is true
         return "image"
      case visible of _playerObject() is true
         return "player"
   end switch
end display_Type

setprop display_Type viewType
   lock screen
   switch viewType
      case "browser"
         set the visible of _browserWidget() to true
         --
         set the visible of _playerObject() to false
         set the visible of _imageObject() to false
         break
      case "image"
         set the visible of _imageObject() to true
         --
         set the visible of _playerObject() to false
         set the visible of _browserWidget() to false
         break
      case "player"
         set the visible of _playerObject() to true
         --
         set the visible of _imageObject() to false
         set the visible of _browserWidget() to false
         break
   end switch
   unlock screen
end display_Type

getprop view_Types
   return "browser,player,image"
end view_Types
--> Events
-
on dragEnter
   set the dragaction to "copy"
end dragEnter

on dragDrop
   -- put the dragData ["files"]
   put the dragData ["text"] into someURL
   set the url of _browserWidget() to someURL
end dragDrop

on resizeControl
   put the rect of me into viewRect
   LayoutControl viewRect
end resizeControl

on refreshDisplay
   put the rect of this card into cardRect
   LayoutControl cardRect
end refreshDisplay

command LayoutControl cardRect
   lock screen
   put the inner_Rect [cardRect] of me into cardRect
   rect_SubtractMargins cardRect
   --
   put _headerRect (cardRect) into headerRect
   put _bodyRect (cardRect) into bodyRect
   put _footerRect (cardRect) into footerRect
   --
   lock screen
   set the rect of _headerWidget() to headerRect
   set the rect of _browserWidget() to bodyRect
   set the rect of _playerObject() to bodyRect
   set the rect of _imageObject() to bodyRect
   set the rect of _footerWidget() to footerRect
   unlock screen
   unlock screen
end LayoutControl


--> Props | Display
-
getprop footer_IsVisible
   return the visible of _footerWidget()
end footer_IsVisible

setprop footer_IsVisible someBoolean
   lock screen
   set the visible of _footerWidget() to someBoolean
   dispatch "refreshDisplay" to cd 1 of me
   unlock screen
end footer_IsVisible


--> Geometry
-
private function _headerRect stackRect
   put item 2 of stackRect + _headerHeight() into item 4 of stackRect
   return stackRect
end _headerRect

private function _bodyRect stackRect
   add _headerHeight() to item 2 of stackRect
   subtract _footerHeight() from item 4 of stackRect
   return stackRect
end _bodyRect

private function _footerRect stackRect
   put item 4 of stackRect - _footerHeight() into item 2 of stackRect
   return stackRect
end _footerRect

private function _headerHeight
   return 55
end _headerHeight

private function _footerHeight
   if the footer_IsVisible of me is true then
      return 40
   else
      return 0
   end if
end _footerHeight


--> Controls
-
getprop view_Object
   return the long id of me
end view_Object

getprop title_View
   put _headerWidget() into headerWidget
   return headerWidget
end title_View


--> Private
-
private function _headerWidget
   put the long id of widget "Browser Header" of me into headerWidget
   return headerWidget
end _headerWidget

private function _browserWidget
   put the long id of widget "Browser" of me into arrayWidget
   return arrayWidget
end _browserWidget

private function _playerObject
   put the long id of player 1 of me into playerObject
   return playerObject
end _playerObject

private function _imageObject
   put the long id of image 1 of me into imageObject
   return imageObject
end _imageObject

private function _footerWidget
   put the long id of widget "Browser Footer" of me into footerWidget
   return footerWidget
end _footerWidget
