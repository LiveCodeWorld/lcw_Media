script "behavior_ViewImageSVG"
--> MetaData
-
license: GPLv3
name: behavior_ViewImageSVG
type: view behavior
version: 0.4


/*
The idea here is to experiment with layered behaviors.
That is instead of using if-then logic to switch the behavior of a layout,
we simply add or remove a behavior.

The scripts below are just work in progress for now.
*/

local LocalArray

--> Working on
-

--> Events
-
on LayoutControl pRect
   if pRect is empty then put the rect of me into pRect
   set the rect of me to pRect
end LayoutControl

on browserNavigateBegin clickedURL
   -- This gets called when the browser view is first opened
   -- and on every link clicked that loads a page
   -- "http://libbrowser_dummy_url/list_ImageFileIDs%2Cc%2Cstack+%22behavior_ServerScriptContainer%22%2C1"
   
   dispatch "svg_BrowserNavigate" with clickedURL
end browserNavigateBegin

on browserDocumentLoadBegin pUrl
   -- working
   pass browserDocumentLoadBegin
end browserDocumentLoadBegin

on browserBeforeNavigate
   breakpoint
   put the params
end browserBeforeNavigate

on browserUnhandledLoadRequest
   breakpoint
   put the params
end browserUnhandledLoadRequest

on browserFrameDocumentLoadFailed
   breakpoint
   put the params
end browserFrameDocumentLoadFailed

on browserFrameDocumentLoadBegin
   breakpoint
   put the params
end browserFrameDocumentLoadBegin


--> Graph
-
getprop graph_Style
   return the graph_Style of me
end graph_Style

setprop graph_Style [dontRender] graphStyle
   put the dot_File of me into dotFile
   put dot_LayoutEngine (graphStyle) into dotCommand
   set the graph_Style of me to graphStyle
   if dontRender is true then return dotCommand
   --
   dot_CreateSvg dotFile, dotCommand
   put the result into svgFile
   set the svg_File [true] of me to svgFile
   return dotCommand
end graph_Style


--> Dot
-
getprop dot_Array [pGraphStyle]
   put the dot_File of me into dotFile
   put dotArray_Get (dotFile, pGraphStyle, false) into dotArray
   return dotArray
end dot_Array

setprop dot_Array [graphStyle] dotArray
   put the dot_File of me into dotFile
   if graphStyle is empty then
      put the graph_Style of me into graphStyle
   end if
   --
   dotArray_Set dotFile, dotArray
   put the result into dotJSON
   return dotJSON
end dot_Array

getprop dot_Text
   put the dot_File of me into dotFile
   put dot_GetText (dotFile) into dotText
   return dotText
end dot_Text

setprop dot_Text [graphStyle] dotText
   put the dot_File of me into dotFile
   dot_SetText dotFile, dotText
   --
   dot_CreateGraph dotText, dotFile, graphStyle
   put the result into svgFile
   set the svg_File of me to svgFile
   return svgFile
end dot_Text


--> SVG | Fluid
-
getprop svg_IsFluid
   put the svg_Dimensions of me into myDimensions
   return myDimensions = "100%,100%"
end svg_IsFluid

setprop svg_IsFluid someBoolean
   if someBoolean is true then
      set the svg_Dimensions of me to "100%,100%"
   else
      put the svg_ViewBoxDimensions of me into originalDimensions
      set the svg_Dimensions of me to originalDimensions
   end if
end svg_IsFluid

getprop graph_Style
   return the graph_Style of me
end graph_Style

setprop graph_Style [dontRender] graph_Style
   set the graph_Style of me to graph_Style
   if dontRender is not true then
      
   end if
end graph_Style


--> SVG | Files
-
getprop svg_File
   put the svg_File of me into svgPath
   return svgPath
end svg_File

setprop svg_File [isFluid] svgPath
   set the svg_File of me to svgPath
   --
   put "file:" & svgPath into svgURL
   put url svgURL into svgXML
   if isFluid is true then
      _SetDimensions svgXML, "100%", "100%"
   end if
   --
   put svgPath into svgTitle
   put svg_GetHTMLTemplate() into htmlTemplate
   put merge (htmlTemplate) into someHtml
   set the htmltext of me to someHtml
   --    
   return someHtml
end svg_File


--> SVG | URL
-
getprop svg_URL svgURL
   return the svg_URL of me
   -- return LocalArray ["svg_URL"]
end svg_URL

setprop svg_URL [isFluid] svgURL
   -- put svgURL into LocalArray ["svg_URL"]
   set the svg_URL of me to svgURL
   --
   put url svgURL into svgXML
   -- put svg_Get (svgXML) into svgXML
   if isFluid is true then
      _SetDimensions svgXML, "100%", "100%"
   end if
   
   put svgURL into svgTitle
   put svg_GetHTMLTemplate() into htmlTemplate
   put merge (htmlTemplate) into someHtml
   --
   set the htmltext of me to someHtml
   --
   return someHtml
end svg_URL


--> Depends on lib_SVG
-
getprop svg_XML
   get the name of me
   put the htmltext of me into someHTML
   put svg_Get (someHTML) into svgXML
   return svgXML
end svg_XML

setprop svg_XML svgXML
   put the htmltext of me into someHTML
   svg_Set someHTML, svgXML
   set the htmltext of me to someHTML
end svg_XML


--> Objects
-
getprop svg_View
   return the long id of me
end svg_View

getprop view_Object
   return the long id of me
end view_Object

getprop displayed_Object
   put the displayed_Hkey of me into hKey
   put item 3 of hKey into hObject
   return hObject
end displayed_Object

setprop displayed_Object hObject
   put hObject into item 3 of LocalArray ["hKey"]
end displayed_Object

getprop displayed_Hkey
   put LocalArray ["hKey"] into hKey
   return hKey
end displayed_Hkey

setprop displayed_Hkey hKey
   put hKey into LocalArray ["hKey"]
end displayed_Hkey


--> Work in Progress
-
getprop svg_Scale
   put the htmltext of me into someHTML
   
   set the wholematches to false
   put "<g transform=" into tagBit
   put lineOffset (tagBit, someHTML) into lineNum
   
   -- "<g transform='scale([[svgScale]])'>"
   put line lineNum of someHTML into firstLine
   replace quote with "'" in firstLine
   put token 7 of firstLine into svgScale
   
   return svgScale
end svg_Scale

setprop svg_Scale svgScale   
   put the svg_XML of me into svgXML
   -- "<g transform='scale([[svgScale]])'>"
   set the wholematches to false
   put "<g transform=" & quote & "scale(" & svgScale & ")" & quote & ">" into startTag
   put lineOffset ("<g id=", svgXML) into startLineNum
   put startTag & CR before line startLineNum of svgXML
   
   put "</g>" into endTag
   put lineOffset ("</svg>", svgXML) into endLineNum
   put endTag & CR before line endLineNum of svgXML
   --
   set the svg_XML of me to svgXML
end svg_Scale

setprop svg_Scale svgScale
   put the htmltext of me into someHTML
   
   set the wholematches to false
   put "<g transform=" into tagBit
   put lineOffset (tagBit, someHTML) into lineNum
   
   switch
      case lineNum is 0 and svgScale is empty
         -- it's not there and we are trying to delete it
         -- do nothing
         break
      case lineNum is 0 and svgScale is not empty
         -- it's no there and we are trying to add a scale
         
         break
      case svgScale is empty
         delete line lineNum of someHTML
         
         -- now delete the end tag
         
         break
      default
         -- scale is already present and we have a new value to set
         put merge ("<g transform='scale(svgScale)'>") into startTag
         put startTag into line lineNum of someHTML
   end switch
   
   set the htmltext of me to someHTML
end svg_Scale


--> SVG | Props
-
getprop svg_Html
   put the htmltext of me into someHTML
   return someHTML
end svg_Html

setprop svg_Html someHTML
   set the htmltext of me to someHTML
end svg_Html

getprop svg_Width
   put the svg_HeaderArray of me into svgHeaderArray
   put svgHeaderArray ["width"] into svgWidth
   return svgWidth
end svg_Width

setprop svg_Width someWidth
   put _CreateXmlTree() into treeID
   revXMLSetAttribute treeID, "/svg","width", someWidth
   put revXMLText (treeID, empty, true) into newSvgXML
   _DeleteXmlTree
   delete line 1 of newSvgXML -- the xml header
   put word 1 to -1 of newSvgXML into newSvgXML
   
   set the svg_XML of me to newSvgXML
   return newSvgXML
end svg_Width

getprop svg_Height
   put the svg_HeaderArray of me into svgHeaderArray
   put svgHeaderArray ["height"] into svgHeight
   return svgHeight
end svg_Height

setprop svg_Height svgHeight
   _DeleteXmlTree
   put _CreateXmlTree() into treeID
   revXMLSetAttribute treeID, "/svg","height", svgHeight
   put revXMLText (treeID, empty, true) into newSvgXML
   _DeleteXmlTree
   delete line 1 of newSvgXML -- the xml header
   put word 1 to -1 of newSvgXML into newSvgXML
   
   set the svg_XML of me to newSvgXML
   return newSvgXML
end svg_Height

getprop svg_Header
   -- a hack which asumes the header is on a single line
   put the svg_XML of me into svgXML
   put line 1 of svgXML into svgHeader
   return svgHeader
end svg_Header

setprop svg_Header svgHeader
   -- a hack which asumes the header is on a single line
   put the svg_XML of me into svgXML
   put svgHeader into line 1 of svgXML
   set the svg_XML of me to svgXML
   return svgXML
end svg_Header

getprop svg_HeaderTable
   put _CreateXmlTree() into treeID
   put revXMLAttributes (treeID, "/svg", tab, CR) into attributeTable
   _DeleteXmlTree
   return attributeTable
end svg_HeaderTable

getprop svg_ViewBoxDimensions
   put the svg_ViewBox of me into svgViewBox
   put word 3 of svgViewBox - word 1 of svgViewBox into originalWidth
   put word 4 of svgViewBox - word 2of svgViewBox into originalHeight
   return originalWidth,originalHeight
end svg_ViewBoxDimensions

getprop svg_ViewBox
   put the svg_HeaderArray of me into svgHeaderArray
   put svgHeaderArray ["viewBox"] into svgViewBox
   return svgViewBox
end svg_ViewBox

getprop svg_HeaderArray
   put the svg_HeaderAttributes of me into attributeTable
   split attributeTable with CR and tab
   return attributeTable
end svg_HeaderArray

setprop svg_HeaderArray svgHeaderArray
   -- combine svgHeaderArray with space and "=" -- does not quote the attributes
   put "<svg" & space into newSvgHeader
   repeat for each key attributeName in svgHeaderArray
      put svgHeaderArray [attributeName] into attributeValue
      put attributeName & "=" & quote & attributeValue & quote & space after newSvgHeader
   end repeat
   delete char -1 of newSvgHeader
   put ">" after newSvgHeader
   
   set the svg_Header of me to newSvgHeader
   put the result into svgXML
   return svgXML
end svg_HeaderArray

getprop svg_HeaderAttributes
   put _CreateXmlTree() into treeID
   put revXMLAttributes (treeID, "/svg", tab, CR) into attributeTable
   _DeleteXmlTree
   return attributeTable
end svg_HeaderAttributes

getprop svg_Dimensions
   put the svg_HeaderArray of me into svgHeaderArray
   put svgHeaderArray ["width"] into svgWidth
   put svgHeaderArray ["height"] into svgHeight
   return svgWidth,svgHeight
end svg_Dimensions

setprop svg_Dimensions svgDimensions
   put item 1 of svgDimensions into svgWidth
   put item 2 of svgDimensions into svgHeight
   
   put the svg_XML of me into svgXML
   _SetDimensions svgXML, svgWidth, svgHeight
   set the svg_XML of me to svgXML
   return svgXML
end svg_Dimensions


--> Private
-
private command _SetDimensions @svgXML, svgWidth, svgHeight
   put _CreateXmlTree (svgXML) into treeID
   revXMLSetAttribute treeID, "/svg","width", svgWidth
   revXMLSetAttribute treeID, "/svg","height", svgHeight
   put revXMLText (treeID, empty, true) into svgXML
   _DeleteXmlTree
   
   delete line 1 of svgXML -- the xml header
   put word 1 to -1 of svgXML into svgXML
end _SetDimensions

private function _CreateXmlTree pSvgXML
   if pSvgXML is empty then
      put the svg_XML of me into pSvgXML -- in case we have other HTML displayed
   end if
   put true into pGoodXML
   put revCreateXMLTree (pSvgXML, pGoodXML, true, false) into svgXmlTreeID
   put svgXmlTreeID into LocalArray ["svgXmlTreeID"]
   return svgXmlTreeID
end _CreateXmlTree

private command _DeleteXmlTree
   put LocalArray ["svgXmlTreeID"] into svgXmlTreeID
   if svgXmlTreeID is not a number then return svgXmlTreeID
   revXMLDeleteTree svgXmlTreeID
   delete variable LocalArray ["svgXmlTreeID"]
   return svgXmlTreeID
end _DeleteXmlTree

