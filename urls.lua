require "strings" --email subject

urls={
  main="http://sandpad.luaforge.net/",
  manual="http://sandpad.luaforge.net/manual.html",
  project="http://luaforge.net/projects/sandpad/",
  tracker={
    bugs="http://luaforge.net/tracker/?func=add&group_id=494&atid=2011"
  },
  email="mailto:"..strings.email.address.."?subject="..strings.email.bugsubject
}

return urls
