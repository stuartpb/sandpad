------------------------------------------------
--Sandpad
--by Stuart P. Bentley (stuart@testtrack4.com)
--http://sandpad.luaforge.net
  local version="1.0"
------------------------------------------------

-------------------------------------------------------------------------------
--           !!! LOCALS ONLY UNTIL setfenv(1,shadowbox(_G)) !!!              --
-------------------------------------------------------------------------------

local function shadowmt(imitate)
  --table for variables that should return nil
  --and not look for a value in the imitated table
  local deleted={}
  return {
  __index=function(t,k)
    if deleted[k] then
      return nil
    elseif type(imitate[k])=="table" then
      t[k]=setmetatable({},shadowmt(imitate[k]))
      return t[k]
    else
      return imitate[k]
    end
  end,
  __newindex=function(t,k,v)
    if not v and imitate[k] then
      deleted[k]=true
    else
      deleted[k]=nil
    end
    rawset(t,k,v)
  end
  }
end

local function shadowtable(uptable)
  return setmetatable({},shadowmt(uptable))
end

local fakeglobal --function defined below for upvalue access
do
  local setfenv=setfenv
  local getfenv=getfenv
  local tonumber=tonumber

  function fakeglobal(upenv)
    local fake_G={}
    fake_G._G=fake_G

    function fake_G.getfenv(f)
      stacklevel=tonumber(f)
      if stacklevel then
        if stacklevel==0 then
          return fake_G
        else
          return getfenv(stacklevel+1)
        end
      else
        return getfenv(f)
      end
    end

    function fake_G.setfenv(f,table)
      stacklevel=tonumber(f)
      if stacklevel then
        if stacklevel==0 then
          fake_G=table
        else
          setfenv(stacklevel+1,table)
        end
      else
        setfenv(f,table)
      end
    end

    return fake_G
  end
end

--returns a shadow sandbox global environment
local function shadowbox(upenv)
  return setmetatable(fakeglobal(upenv),shadowmt(upenv))
end

--save clean default environment for use in boxes
local defaultenv=_G
--set new global environment shadowing original _G
--except setfenv(0,shadowbox(_G)) causes iup to remain unindexed
--after the call to require
--so right now we do the next best thing
--and set this chunk's environment instead
setfenv(1,shadowbox(_G))

-------------------------------------------------------------------------------
-- !!! DO NOT PUT ANY CODE MODIFYING THE GLOBAL ENVIRONMENT ABOVE THIS LINE !!!
-------------------------------------------------------------------------------

require "iuplua"
local icon=(io.open "sandpad.ico")
if icon and pcall(require,"iupluaim") then
  icon:close()
  --counting on this to soon have alpha
  icon=iup.LoadImage "sandpad.ico"
else
  icon = iup.image {
    { 1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,3,2,3,1,1,1,1,1,1,1 },
    { 1,1,1,1,3,3,2,2,2,3,3,3,1,1,1,1 },
    { 1,1,3,3,3,3,2,2,2,3,3,3,3,3,1,1 },
    { 1,3,3,3,2,2,2,2,2,2,2,3,3,3,3,1 },
    { 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2 },
    { 1,3,3,3,2,2,2,2,2,2,2,3,3,3,3,1 },
    { 1,1,3,3,3,3,2,2,2,3,3,3,3,1,1,1 },
    { 1,1,1,1,3,3,2,2,2,3,3,1,1,1,1,1 },
    { 1,1,1,1,1,1,3,2,3,1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1 }
    -- Sets star image colors
    ; colors = { "BGCOLOR", "255 255 255", "0 0 0" }
    ; bgcolor="BGCOLOR"
  }
end

tabwidth=2
blankoutput=""
rundelay=500

require "strings"
require "urls"

function print(...)
  local msg = {}
  local args={...}
  for i, v in ipairs(args) do
    msg[#msg+1]=tostring(v)
    if i~= #args then
      msg[#msg+1]="\t"
    end
  end
  msg[#msg+1]="\n"
  if iup._VERSION:match"(%d+)%."~="3" then
    returndata.value=returndata.value..table.concat(msg)
  else
    returndata.append=table.concat(msg)
  end
end
defaultenv.print=print;

colors={
  red="255 0 0",
  black="0 0 0",
  white="255 255 255"
}

values={
  printbg="217 240 252",
  printblank="230 240 252"
}

if true then--iup._VERSION:match"(%d+)%."~="3" then
  values.editfont="Consolas::8"
  values.printfont="Consolas::20"
  printalign="ACENTER"
else --prepare for the future
  values.editfont="Consolas,Monospace, 8"
  values.printfont="Consolas,Monospace, 20"
  printalign="ACENTER:ACENTER"
  --also play around with "FORMATTING" and "AUTOHIDE"
end

local function cheapsettingform(var)
  return " ".._G[var].." "..string.format(strings.settings.cheapformat,var)
end

dialogs={
  settings=iup.dialog{title=strings.settings.title;
    iup.hbox{
    iup.label{title=strings.settings.delay},
    iup.label{title=cheapsettingform"rundelay"}
    }
    ;margin="4x4"
  },

  help={
    about=iup.dialog{title=strings.about.title;
      iup.hbox{
        iup.vbox{
          iup.hbox{alignment="ABOTTOM";
            iup.label{title=strings.appname,font=values.printfont},
            iup.label{title=version,font=values.editfont, }
          },
          iup.label{title=strings.about.byline},
          iup.label{title=strings.about.epoch},
          iup.fill{},
        },
        iup.vbox{
          iup.label{title="IUP "..iup._VERSION},
          iup.label{title=_VERSION},
          iup.fill{},
          iup.hbox{
            iup.button{title=strings.about.email,
              tip=strings.tips.email,
              padding="3x3",
              action=function()
                iup.Help(urls.email)
              end
            },
            iup.button{title=strings.about.close,
              padding="3x3",
              action=function()
                return iup.CLOSE
              end
            }
            ;margin=0
          }
          ;alignment="ARIGHT"
        }
      ;gap=4,margin="4x4", alignment="ABOTTOM"
      },
      show_cb=function(self,state)
        if state==iup.SHOW then
          iup.SetFocus(self[1][2][4][2]) --not working in iup3rc1
        end
      end
      ;dialogframe="YES"
      ;RESIZE="NO", MINBOX="NO", MAXBOX="NO" --redundancy for iup 2.x
    },

    cg=iup.dialog{title=strings.help.title;
      iup.vbox{
      iup.label{title=strings.help.lines[1]},
      iup.label{title=strings.help.lines[2]},
      }
      ;margin="4x4"
    }
  }
}

--set all controls in a table to a specific state
function actable(cls,state)
  if cls then
    for _,v in pairs(cls) do
      v.active=state
    end
  end
end

--deactivate all boxes after and inclding the argument index
function deactivate_down(laters)
  for i=laters, #boxes do
    actable(boxes[i].cls,"NO")
    boxes[i].text.active="NO"
  end
end

--reactivate an individual box
function reactivate_box(box)
  if box.cls then
    for _,v in pairs(box.cls) do
      v.active=box.states[v]
    end
  end
  box.text.active="YES"
end

--set the state of a control in a box
function setactive(box,clst,state)
  box=boxes[box]
  if type(clst)=="string" then
    box.states[box.cls[clst]]=state
    box.cls[clst].active=state
  elseif type(clst)=="table" then
    for _,clstring in pairs(clst) do
      box.states[box.cls[clstring]]=state
      box.cls[clstring].active=state
    end
  end
end

function clearbox(box)
  box=boxes[box]
  box.text.value=""
  box:eval()
end

function clearallboxes()
  for _,box in ipairs(boxes) do
    box.text.value=""
  end
  --will exec and clear all futher boxes' functions
  boxes[1]:eval()
end

--change the color of returndata to a set of colors
function coloretdata(colort)
  returndata.bgcolor=colort.bg
  returndata.fgcolor=colort.fg

  --without this line my LfW IUP2.7.1 won't update
  --the color in the non-writeable area of the box
  --(as it is now it still takes one redraw to fix)
  iup.Update(returndata)
end

local nofile=true
boxes={ --individual box definitions
  --[[on env chains:
    each env runs from a shadow of the env above it,
    and when reset (when executing that box's text)
    remakes all shadows that come after it
    (since they all need to shadow the new env).
    env is stored in an index so it can be accessed
    by the lower boxes' environments.]]

  [0]={env=defaultenv,output=""},
  {--1
    name="Left Box",
    text=iup.multiline{expand="YES",font=values.editfont,tabsize=tabwidth,
      tip=strings.tips.boxes[1],tipfont="SYSTEM"},
    color={
      fParse={ --soon boxes[1].color.fParse will not come into play (String/Lua toggling)
        bg="255 192 192",
        fg=colors.red
      },
      fExec={
        bg="255 128 0",
        fg=colors.red
      }
    },
    cls={
      nameclear=iup.button{title=strings.buttons.fileid,
        active="NO",padding="2x";--size="x14";
        action=function(self)
          boxes[1].cls.filename.value=""
          self.title=strings.buttons.fileid
          boxes[1].cls.astog.value="OFF"
          setactive(1,{"nameclear","astog","save"},"NO")
          nofile=true
        end},
      filename=iup.text{expand="HORIZONTAL",
        tip=strings.tips.filename;
        action=function(self,change,value)
          if value=="" then
            boxes[1].cls.nameclear.title=strings.buttons.fileid
            boxes[1].cls.astog.value="OFF"
            setactive(1,{"nameclear","astog","save"},"NO")
            nofile=true
          else
            if nofile then --wrong way to do this but
              boxes[1].cls.nameclear.title=strings.buttons.clear
              setactive(1,{"nameclear","astog"},"YES")
              nofile=false
            end
            boxes[1].cls.astog.value="OFF"
            setactive(1,"save","YES")
          end
        end},
      astog=iup.toggle{title=strings.pre.auto,value="OFF",
        active="NO",tip=strings.tips.auto.save;
        action=function(self,state)
          if state==1 then
            setactive(1,"save","NO")
          else
            setactive(1,"save","YES")
          end
        end
      },
      save=iup.button{title=strings.buttons.save,focusonclick="NO",
        active="NO",padding="2x";--size="x14";
        action=function()
        end
      },
      tgLua=iup.toggle{title=strings.combos.box1.lua, value="ON",
        tip=strings.tips.box1radio.lua},
      tgString=iup.toggle{title=strings.combos.box1.string,
        tip=strings.tips.box1radio.string},
      luable=iup.label{title="",expand="HORIZONTAL"}
    }
  },
  {--2
    name="Top Box",
    text=iup.multiline{expand="YES",font=values.editfont,tabsize=tabwidth,
      fgcolor=colors.black, bgcolor="255 250 223",
      tip=strings.tips.boxes[2],tipfont="SYSTEM",
      },
    color={
      fParse={
        bg="255 255 128",
        fg=colors.red
      },
      fExec={
        bg="255 255 0",
        fg=colors.red
      }
    },
    cls={
      artog=iup.toggle{title="",value="ON",tip=strings.tips.auto.run;
        action=function(self,state)
          if state==1 then
            boxes[2].cls.run.title=strings.buttons.autorun
            setactive(2,"run","NO")
          else
            boxes[2].cls.run.title=strings.buttons.run
            setactive(2,"run","YES")
          end
        end
      },
      run=iup.button{title=strings.buttons.autorun,focusonclick="NO",
        expand="HORIZONTAL",active="NO",--size="x14";
        action=function()
          boxes[2].text:action(nil,boxes[2].text.value)
        end
      },
      clear=iup.button{title=strings.buttons.clear,focusonclick="NO",
        expand="HORIZONTAL",--size="x14";
        action=function()
          clearbox(2)
        end
      }
    }
  },
  {--3
    name="Print Box",
    text=iup.text{expand="HORIZONTAL",font=values.editfont,tabsize=tabwidth,
      tip=strings.tips.boxes[3],tipfont="SYSTEM"
    },
    color={
      fParse={
        bg=values.printblank,
        fg=colors.red
      },
      fExec={
        bg=values.printbg,
        fg=colors.red
      },
      normal={
        bg=values.printbg,
        fg=colors.black
      },
      blank={
        bg=values.printblank,
        fg="192 192 192"
      }
    },
    cls={
      clear=iup.button{title=strings.buttons.x,focusonclick="NO",padding="3x";
        action=function()
          clearbox(3)
        end
      }
    }
  }
}

for iBox, curBox in ipairs(boxes) do
  --initial chaining
  curBox.env=shadowbox(boxes[iBox-1].env)
  curBox.output=boxes[iBox-1].output

  --initialize stored control states
  curBox.states={}
  if curBox.cls then
    for _,v in pairs(curBox.cls) do
      curBox.states[v]=v.active
    end
  end

  function curBox:eval(newcode)
    --create a new environment for this iteration
    self.env=shadowbox(boxes[iBox-1].env)
    self:run(newcode)
  end

  function curBox:run(newcode)
    --TODO: Don't recompile if not newcode
    newcode=newcode or self.text.value
    --if the box is being run then it's at reactivation focus
    reactivate_box(self)
    local f, message=loadstring(newcode,self.name)
    if f then
      setfenv(f,self.env)
      local ok, r=pcall(f)
      if not ok then
        self:fExec(r)
      else
        --call next action which will make subsequent calls down the line

        --we don't need the following commented out check because
        --the final box's action is redefined altogether at the end of the loop

        --if iBox~=#boxes then
        boxes[iBox+1]:eval()
        --end
      end
    else
      self:fParse(message)
    end
  end

  function curBox.text:action(c,newcode)
    -- if c is a printable character
    -- (arrow keys+home,end,pgup/down are all >300)
    -- of course, this was more of an IUP2 problem-
    -- IUP3 only calls action for changes now
    -- (and non-printable characters like backspace and ctrl+v are 0)
    if c<=256 then
      -- output whatever the previous box output before this one
      returndata.value=boxes[iBox-1].output
      if c==string.byte"\n" or c==string.byte"\r"
      and tonumber(self.caretpos)==#self.value
      and string.sub(self.value, #self.value, #self.value)=="\n" then
        --just run (not bothering to pass the "new code"
        --that's the same as the old code but with
        --2 newlines at the end instead of one)
        curBox:run()
        --ignore the new newline
        return iup.IGNORE
      else
        curBox:eval(newcode)
      end
    end
  end

  if not curBox.fParse then
    function curBox:fParse(message)
      returndata.value=message
      coloretdata(self.color.fParse)
      deactivate_down(iBox+1)
    end
  end

  if not curBox.fExec then
    function curBox:fExec(message)
      returndata.value=message
      coloretdata(self.color.fExec)
      deactivate_down(iBox+1)
    end
  end
end

--final box run setup
boxes[#boxes].run=function(self,newcode)
  --TODO: Don't recompile if not newcode
  newcode=newcode or self.text.value
  --if the box is being run then it's at reactivation focus
  reactivate_box(self)
  if newcode:find"%S" then
    newcode="return "..newcode
    local f, message=loadstring(newcode,self.name)
    if f then
      setfenv(f,self.env)
      local r={pcall(f)}
      if not r[1] then
        self:fExec(r[2])
      else
        if #r>1 then
          print(unpack(r,2))--,#r
          coloretdata(self.color.normal)
        else
          print "nil"
          coloretdata(self.color.blank)
        end
      end
    else
      self:fParse(message)
    end
  else
    returndata.value=boxes[#boxes-1].output
    if returndata.value==blankoutput then
      coloretdata(self.color.blank)
    end
  end
end

returndata=iup.multiline{font=values.printfont,bgcolor=values.printblank,
  alignment="ACENTER",expand="YES",border="YES",wordwrap="YES",
  readonly="YES",value=blankoutput,scrollbar="NO",size=nil,
  appendnewline="NO",tip=strings.tips.output,tipfont="SYSTEM"}

Sandpad=iup.dialog{title=strings.appname;
  iup.hbox{
    iup.vbox{
      iup.hbox{
        iup.hbox{
          boxes[1].cls.nameclear,
          boxes[1].cls.filename
          ;gap=2,margin="0x0",alignment="ACENTER"
        },
        iup.hbox{
          boxes[1].cls.astog,
          boxes[1].cls.save
          ;gap=-1,margin="0x0",alignment="ACENTER"
        }
        ;gap=4,margin=0,alignment="ACENTER"
      },
      boxes[1].text,
      iup.radio{
        iup.hbox{
          boxes[1].cls.tgString,
          boxes[1].cls.tgLua,
          boxes[1].cls.luable
        }
      }
      ;gap=4--,margin=0
    },
    iup.vbox{
      boxes[2].text,
      iup.hbox{
        iup.hbox{
          boxes[2].cls.artog,
          boxes[2].cls.run
          ;gap=-1,margin="0x0",alignment="ACENTER"
        },
        boxes[2].cls.clear
        ;gap=4,alignment="ACENTER"
      },
      iup.frame{title=strings.frames.box3;
        iup.vbox{
          iup.hbox{
            iup.hbox{
              iup.label{title="("},
              boxes[3].text,
              iup.label{title=")"}
              ;gap=2,alignment="ACENTER"
            },
            boxes[3].cls.clear
            ;gap=4,margin=4
          },
          returndata
        }
        ;gap=8
      }
      --;gap=4,margin=0
    }
    ;margin="2x2",gap=0
  }
  ;menu=iup.menu{
    iup.submenu{title=strings.menus.file.title;
      iup.menu{
        iup.item{title=strings.menus.file.open},
        iup.item{title=strings.menus.file.saveas},
        iup.item{title=strings.menus.file.new},
        iup.item{title=strings.menus.file.clear,
          action=clearallboxes},
        iup.separator{},
        iup.item{title=strings.menus.file.quit, action="return iup.CLOSE"}
      }
    },
    iup.submenu{title=strings.menus.settings.title;
      iup.menu{
        iup.item{title=strings.menus.settings.exe;
          action=function()
            dialogs.settings:popup()
          end
        },
        --settings.invis
      }
    },
    iup.submenu{title=strings.menus.help.title;
      iup.menu{
        iup.item{title=strings.menus.help.colors;
          action=function()
            dialogs.help.cg:popup()
          end
        },
        iup.separator{},
        iup.item{title=strings.menus.help.bugreport,
          action=function()
            iup.Help(urls.tracker.bugs)
          end
        },
        iup.separator{},
        iup.item{title=strings.menus.help.about;
          action=function()
            dialogs.help.about:popup()
          end
        }
      }
    }
  }
;size="HALFxHALF",gap=4,margin="4x4",icon=icon,
minsize="400x250",
shrink="YES",       --should never come into play under MINSIZE
}

local sysname=iup.GetGlobal "SYSTEM"
if sysname~="Win2k" and sysname~="WinXP" then
  --for some reason it uses a meg less RAM this way (on my Vista x64 system)
  Sandpad.layered="YES"
  Sandpad.layeralpha=255
end

Sandpad:show()
iup.SetFocus(boxes[3].text) --box of least resistance

iup.MainLoop()
