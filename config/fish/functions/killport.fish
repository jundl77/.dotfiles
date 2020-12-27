function killport
  kill (lsof -ti:$argv)
end
