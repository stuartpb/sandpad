require "strings" --email subject; email address

urls={
  home="http://sandpad.luaforge.net/",
  manual="http://sandpad.luaforge.net/manual.html",
  license="http://sandpad.luaforge.net/license.html",
  launchpad="https://launchpad.net/sandpad",
  luaforge="http://luaforge.net/projects/sandpad/",
  bugreport="https://bugs.launchpad.net/sandpad/+filebug",
  askq="https://answers.launchpad.net/sandpad/+addquestion",
  email="mailto:stuart@testtrack4.com?subject="..strings.appname
}

return urls
