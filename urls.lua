require "strings" --email subject; email address

urls={
  main="http://sandpad.luaforge.net/",
  manual="http://sandpad.luaforge.net/manual.html",
  luaforge="http://luaforge.net/projects/sandpad/",
  launchpad="https://launchpad.net/sandpad",
  bugreport="https://bugs.launchpad.net/sandpad/+filebug",
  email="mailto:stuart@testtrack4.com?subject="..strings.appname
}

return urls
