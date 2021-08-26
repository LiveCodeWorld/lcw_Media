script "lib_Hackmd"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_Hackmd
type: library
version: 0.1

/*
This is a cli hack in the place of a proper api
*/


--> Working on
-
command hackmd_Deconstruct lexText, @lexTitle, @lexBody
   local lexMeta
   
   if word 1 of line 1  of lexText = "---" then
      get lineOffset ("---", lexText , 1)
      if endNum > 0 then
         put it + 1 into endNum
         put line 1 to endNum of lexText into lexMeta
         delete line 1 to endNum of lexText
      end if
   end if
   
   put word 1 to -1 of lexText into lexBody
   get line 1 of lexBody
   if word 1 of it = "#" then
      put word 2 to -1 of it into pageTitle
      put word 1 to -1 of line 2 to -1 of lexBody into lexBody
   else
      put empty into pageTitle
   end if
   return lexMeta
end hackmd_Deconstruct

command hackmd_StipMeta @lexText
   if word 1 of line 1  of lexText = "---" then
      put lineOffset ("---", lexText , 1) into endNum
      delete line 1 to endNum of lexText
   end if
end hackmd_StipMeta

command launch_HackmdHelp
   launch url "https://github.com/hackmdio/hackmd-cli#configuration"
end launch_HackmdHelp


--> Hackmd
-
function hackmd_FetchMarkdown noteID, pUseCli
   /*
   $ hackmd-cli export [--pdf|--md|--html] <note_id> <output_file>
   Export note to local file or stdout(if the output_file param is omitted)
   
   USAGE
   $ hackmd-cli export [NOTEID] [OUTPUT]
   
   OPTIONS
   -h, --help  show CLI help
   --html
   --md
   --pdf
   */
   
   if pUseCli is true then
      put "hackmd-cli export" && kwote (noteID) into someShell
      put shell (someShell) into shellResult
      return shellResult
   end if
   
   -- this works for published docs
   put merge ("https://hackmd.io/[[noteID]]/download") into someURL
   put url someURL into someMarkdown
   return someMarkdown
end hackmd_FetchMarkdown

command hackmd_Login
   /*
   USAGE
   $ hackmd-cli login
   
   OPTIONS
   -h, --help   show CLI help
   -u, --id=id  Login email/username
   --ldap
   
   EXAMPLE
   $ hackmd-cli login
   
   Enter your email: hello@hackmd.io
   Enter your password: *******
   
   Login as HMD successfully!
   
   Used a ~/.hackmd/config.json file:
   
   {
   "loginID": "user@example.com",
   "loginPassword": "xxxxxx"
   }
   */
   
   put "hackmd-cli login" into someShell
   /*
   put space & "-u" && userEmail after someShell
   put space & "-id" && userID after someShell
   */
   
   put shell (someShell) into shellResult
   return shellResult
end hackmd_Login

command hackmd_Logout
   /*
   $ hackmd-cli logout
   You've logged out successfully
   */
   
   put shell ("hackmd-cli logout") into shellResult
   return shellResult
end hackmd_Logout


--> Deps
-
