function cdproject
	if test "$VIRTUAL_ENV" = ""
		echo "No virtualenv activated!"
		return 1
	end
	set project "$VIRTUAL_ENV/.project"
	if not test -f "$project"
		echo "The virtualenv has no project set (use setvirtualenvproject)"
		return 1
	end
	cd (cat $project)
	test "$argv" != ""; and cd $argv
end