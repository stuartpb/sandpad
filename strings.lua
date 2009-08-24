strings=
{
  appname="Sandpad",
  nogo="(NOT IMPLEMENTED)",
  noco="(NOT ACTUALLY CHANGEABLE)"
}

strings.tips={
  boxes={
    "When executed, code in this box starts in the default environment.",
    "This box starts from the left box's environment "
    .."(or the default environment if it's being passed as a string).",
    "The contents of this box are returned to print()."
  },
  filename="Put a filename here to open that file. "..strings.nogo,
  box1radio={
    string="Selecting this will pass the contents of the left box to the right one in a string as \"...\". "..strings.nogo,
    lua="Selecting this will execute the contents of the left box. "..strings.noco
  },
  output="Calls to print (such as code in the form above) and errors are displayed here.",
  auto={
    save="Checking this box will save the file after every change. "..strings.nogo,
    run="Unchecking this box will make the above code only run when the adjacent button is pressed. "..strings.nogo
  },
  email="Clicking this button will open your default e-mail composer.",
  browser="Clicking this button will open your default web browser."
}

strings.about={
  title="About "..strings.appname,
  byline="by Stuart P. Bentley",
  license="View License",
  email="Contact",
  close="Fantastic."
}

strings.settings={
  title=strings.appname.." Settings",
  delay="Delay to run (in milliseconds):",
  cheapformat="(edit \"%s\" in script)",
  autosaveuncheck="Don't uncheck Autosave when I change files"
}

strings.cuebanners={
  filename="Filename",
}

strings.buttons={
  save="Save",
  run="Run",
  autorun="Autorun",
  clear="Clear",
  fileid="File:",
  x="\215"
}

strings.pre={
  auto="Auto" --for toggle before "Save" button
}

strings.combos={
  box1={
    lua="Lua (Environment)",
    string="String (...)"
  }
}

strings.frames={
  box3="print"
}

strings.menus={
  file={title="File";
    open="Open...",
    saveas="Save As...",
    new="New File...",
    clear="Clear All Boxes",
    quit="Quit"
  },
  settings={title="Settings";
    exe="Execution...",
    badds="Safety..."
  },
  help={title="Help";
    manual="Online Manual",
    askq="Ask Question",
    bugreport="Report Bug",
    pages=strings.appname.." Pages",
    about="About..."
  }
}

strings.pages={
  home="Home",
  launchpad="Launchpad",
  luaforge="LuaForge"
}

strings.formats={
  version="Version %s",
  pushed="Pushed %s"
}

return strings
