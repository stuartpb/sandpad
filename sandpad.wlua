------------------------------------------------
--Sandpad
--by Stuart P. Bentley (stuart@testtrack4.com)
--http://sandpad.luaforge.net
  local version="1.0"
  local pushed="8/26.2009"
------------------------------------------------

-------------------------------------------------------------------------------
--         !!! USE ONLY LOCALS ABOVE setfenv(1,shadowbox(_G)) !!!            --
-------------------------------------------------------------------------------

local shadowmt, shadowtable, fakeglobal, shadowbox, defaultenv
do
  function shadowmt(source)
    --table for variables that should return nil
    --and not look for a value in the source table
    local deleted={}
    return {
    __index=function(t,k)
      if deleted[k] then
        return nil
      elseif type(source[k])=="table" then
        t[k]=setmetatable({},shadowmt(source[k]))
        return t[k]
      else
        return source[k]
      end
    end,
    __newindex=function(t,k,v)
      if not v and source[k] then
        deleted[k]=true
      else
        deleted[k]=nil
      end
      rawset(t,k,v)
    end
    }
  end

  function shadowtable(uptable)
    return setmetatable({},shadowmt(uptable))
  end

  function fakeglobal(upenv)
    local fake_G={}
    fake_G._G=fake_G

    return fake_G
  end

  --returns a shadow sandbox global environment
  function shadowbox(upenv)
    global=setmetatable(fakeglobal(upenv),shadowmt(upenv))

    --delete setfenv/getfenv
    --(reimplementation development in internalfenv branch)
    global.setfenv=nil
    global.getfenv=nil

    return global
  end

  --save clean default environment for use in boxes
  defaultenv=_G
end

--set new global environment shadowing original _G
--except setfenv(0,shadowbox(_G)) causes iup to fail to index itself
--so right now we do the next best thing
--and set this chunk's environment instead
setfenv(1,shadowbox(_G))

--get the original environment's setfenv and getfenv
--so we can set environments for boxes
setfenv=defaultenv.setfenv
getfenv=defaultenv.getfenv

-------------------------------------------------------------------------------
--        !!! DON'T MODIFY THE GLOBAL ENVIRONMENT ABOVE THIS LINE !!!        --
-------------------------------------------------------------------------------

require "iuplua"

local icon=(io.open "sandpad.ico")
if icon and pcall(require,"iupluaim") then
  icon:close()
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
  }
end

tabwidth=2
blankoutput=""
rundelay=500

require "strings"
require "urls"

colors={
  red="255 0 0",
  black="0 0 0",
  white="255 255 255"
}

values={
  printbg="217 240 252",
  printblank="230 240 252"
}

if true then
  values.editfont="Consolas::8"
  values.printfont="Consolas::20"
  printalign="ACENTER"
else
  values.editfont="Consolas,Monospace, 8"
  values.printfont="Consolas,Monospace, 20"
  printalign="ACENTER:ACENTER"
  --also play around with "FORMATTING" and "AUTOHIDE"
end

--set all controls in a table to a specific state
function actable(cls,state)
  if cls then
    for _,v in pairs(cls) do
      v.active=state
    end
  end
end

--deactivate all boxes after and including the argument index
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
  --BUG: outermost 1 pixel not updating
end

function boxtextbox(i, bgcolor)
  return iup.multiline{expand="YES",
    font=values.editfont, tabsize=tabwidth,
    tip=strings.tips.boxes[i],tipfont="SYSTEM",
    bgcolor=bgcolor}
end

local topboxchanged=false
local function topboxunauto()
  topboxchanged=true
end
--gets set after the function is creates
local topboxauto

boxes={ --individual box definitions
  [0]={env=defaultenv,prints={}},
  {--1
    text=boxtextbox(1),
    color={
      fParse={ --soon this color will not come into play (String/Lua toggling)
        bg="255 192 192",
        fg=colors.red
      },
      fExec={
        bg="255 128 0",
        fg=colors.red
      }
    },
    cls={
    --development branched to leftboxcontrols
    }
  },
  {--2
    text=boxtextbox(2,"255 250 223"),
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
            boxes[2].text.action=topboxauto
          else
            boxes[2].cls.run.title=strings.buttons.run
            setactive(2,"run","YES")
            boxes[2].text.action=topboxunauto
          end
        end
      },
      run=iup.button{title=strings.buttons.autorun,
        expand="HORIZONTAL",active="NO",--size="x14";
        action=function()
          if topboxchanged then
            boxes[2]:eval()
            topboxchanged=false
          else
            boxes[2]:run()
          end
        end
      },
      clear=iup.button{title=strings.buttons.clear,
        expand="HORIZONTAL",
        action=function()
          clearbox(2)
          iup.SetFocus(boxes[2].text)
        end
      }
    }
  },
  {--3
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
      clear=iup.button{title=strings.buttons.x,padding="3x";
        action=function()
          clearbox(3)
          iup.SetFocus(boxes[3].text)
        end
      }
    }
  }
}

if iup2 then
  boxes[1].cls.save.size="x14";
  boxes[1].cls.nameclear.size="x14";
  boxes[2].cls.clear.size="x14";
  boxes[3].cls.clear.size="x14";
end

for iBox, curBox in ipairs(boxes) do

  --allow chaining on initial boxes to do nothing
  function curBox.f() end

  --set up chaining
  --called before executing a box's function
  --and at the end of these definitions
  function curBox:rechain()
    --create a new environment for this iteration
    --from the previous box's
    self.env=shadowbox(boxes[iBox-1].env)
    setfenv(self.f,self.env)
    --internal environment function hookup
    self.env.print = self.print
  end

  function curBox:continue()
    curBox.prints={unpack(boxes[iBox-1].prints)}
  end

  --initialize stored control states
  curBox.states={}
  if curBox.cls then
    for _,v in pairs(curBox.cls) do
      curBox.states[v]=v.active
    end
  end

  --run: execute the box's function
  --the box's function's environment may be coming from the last run
  --of the previous box's function if this is being called in chain
  --or it might be operating on itself
  function curBox:run()
    --if the box is being run then it is active
    reactivate_box(self)
    self:continue()

    local ok, r=pcall(self.f)
    if not ok then
      self:fExec(r)
    else --call next box's chain which will run from the environment
      --left by this call and call chain itself (hence the name "chain")

      --if the final box's run weren't redefined at the end of the loop
      --then you would only want to call this if iBox~=#boxes
      boxes[iBox+1]:chain()
    end
  end

  function curBox:eval(newcode)
    --if newcode wasn't passed then it's a situation where it hasn't
    --been being passed
    newcode=newcode or self.text.value
    local message
    self.f, message=loadstring(newcode,strings.boxnames[iBox])
    if self.f then
      self:chain()
    else
      --reactivate so the user can fix the parse error
      --(which could have been present before a prior box had an error
      --and disabled all further boxes)
      reactivate_box(self)
      self:fParse(message)
    end
  end

  --chain: run from the previous box's environment
  function curBox:chain()
    self:rechain()
    self:run()
  end

  function curBox.text:action(c,newcode)
    if c==string.byte"\n" or c==string.byte"\r"
    and tonumber(self.caretpos)==#self.value
    and string.sub(self.value, -2)=="\n\n" then
      curBox:run()
      --ignore the new newline
      return iup.IGNORE
    else
      curBox:eval(newcode)
    end
  end

  if not curBox.fParse then
    function curBox:fParse(message)
      returndata.font=values.editfont
      coloretdata(self.color.fParse)
      returndata.value=
        message:gsub('%[string "(.-)"%]:(%d-):',
        string.format("%%1:%%2: %s:",strings.errors.parse))
      deactivate_down(iBox+1)
    end
  end

  if not curBox.fExec then
    function curBox:fExec(message)
      coloretdata(self.color.fExec)
      returndata.font=values.editfont
      returndata.value=
        message:gsub('%[string "(.-)"%]:(%d-):',
        string.format("%%1:%%2: %s:",strings.errors.run))
      deactivate_down(iBox+1)
    end
  end

  --internal environment functions
  if not curBox.print then
    --using upvalues because this is called from the environment
    function curBox.print(...)
      local tostrings={}
      arg={n=select('#',...),...}
      for i=1,arg.n do
        tostrings[i]=tostring(arg[i])
      end
      curBox.prints[#curBox.prints+1]=table.concat(tostrings,"\t")
    end
  end

  --link everything up
  curBox:rechain()
  curBox:continue()
end
topboxauto=boxes[2].text.action

--print box run setup
boxes[#boxes].eval=function(self,newcode)
  --if newcode wasn't passed then it's a situation where it hasn't
  --been being passed
  newcode=newcode or self.text.value
  if newcode:find"%S" then
    newcode="return "..newcode
  end
  local message
  self.f, message=loadstring(newcode,strings.boxnames[#boxes])
  if self.f then
    self:chain()
  else
    --reactivate so the user can fix the parse error
    --(which could have been present before a prior box had an error
    --and disabled all further boxes)
    reactivate_box(self)
    self:fParse(message)
  end
end

--this is *partly* because i don't know a better way to preserve
--the return arguments from pcall (what with the possible nils).
local function outputwith(self,success,...)
  if not success then
    self:fExec(...)
  else
    if select('#',...)>0 then
      self.print(...)
      --if #{...}>0 then
      coloretdata(self.color.normal)
    elseif #self.prints >0 then
      coloretdata(self.color.normal)
    else --ain't nothing going to get printed nohow
      coloretdata(self.color.blank)
    end
  --set the good print font since it will be
  --the small one after an error
    returndata.font=values.printfont
    returndata.value=table.concat(self.prints,'\n')
  end
end

boxes[#boxes].run=function(self)
  reactivate_box(self)
  self:continue()
  outputwith(self,pcall(self.f))
end

returndata=iup.multiline{font=values.printfont, bgcolor=values.printblank,
  alignment="ACENTER", border="YES", wordwrap="YES", expand="YES",
  readonly="YES", value=blankoutput, scrollbar="AUTOHIDE",
  appendnewline="NO", tip=strings.tips.output, tipfont="SYSTEM"}

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

  about=iup.dialog{title=strings.about.title;
    iup.vbox{
      iup.hbox{
        iup.vbox{
          iup.label{title=strings.appname,font=values.printfont},
          iup.label{title=strings.formats.version:format(version)},
          iup.label{title=strings.about.byline},
          iup.label{title=strings.formats.pushed:format(pushed)},
        },
        iup.fill{size=64},
        iup.vbox{
          iup.label{title="IUP "..iup._VERSION},
          iup.label{title=_VERSION},
          iup.fill{}
          ;alignment="ARIGHT"
        }
        ;margin="0x0"
      },
      iup.hbox{
        iup.button{title=strings.about.license,
          tip=strings.tips.browser,
          padding="4x2",
          action=function()
            iup.Help(urls.license)
          end
        },
        iup.fill{},
        iup.button{title=strings.about.email,
          tip=strings.tips.email,
          padding="4x2",
          action=function()
            iup.Help(urls.email)
          end
        },
        iup.button{title=strings.about.close,
          padding="4x2",
          action=function()
            return iup.CLOSE
          end
        }
        ;margin=0,gap=4
      }
      ;gap="2x2",margin="8x6",alignment="ABOTTOM"
    };
    show_cb=function(self,state)
      if state==iup.SHOW then
        iup.SetFocus(self[1][2][4]) --fix committed
      end
    end
    ;dialogframe="YES"
  },
}

for _,each in pairs(dialogs) do
  each.icon=icon
end

Sandpad=iup.dialog{title=strings.appname;
  iup.hbox{
    iup.vbox{
      --development of filename in leftboxcontrols branch
      boxes[1].text
      --development of string/Lua radio in leftboxcontrols branch
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
        --development of file options in leftboxcontrols branch
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
      }
    },
    iup.submenu{title=strings.menus.help.title;
      iup.menu{
        iup.item{title=strings.menus.help.manual;
          action=function()
            iup.Help(urls.manual)
          end
        },
        iup.separator{},
        iup.item{title=strings.menus.help.askq,
          action=function()
            iup.Help(urls.askq)
          end
        },
        iup.item{title=strings.menus.help.bugreport,
          action=function()
            iup.Help(urls.bugreport)
          end
        },
        iup.separator{},
        iup.submenu{title=strings.menus.help.pages;
          iup.menu{
            iup.item{title=strings.pages.home;
              action=function()
                iup.Help(urls.home)
              end
            },
            iup.item{title=strings.pages.launchpad;
              action=function()
                iup.Help(urls.launchpad)
              end
            },
            iup.item{title=strings.pages.luaforge;
              action=function()
                iup.Help(urls.luaforge)
              end
            },
          }
        },
        iup.item{title=strings.menus.help.about;
          action=function()
            dialogs.about:popup()
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
