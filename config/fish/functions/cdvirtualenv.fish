function cdvirtualenv
	if test "$VIRTUAL_ENV" = ""
		echo "No virtualenv activated!"
		return 1
	end
	cd "$VIRTUAL_ENV"
	test "$argv" != ""; and cd $argv
end