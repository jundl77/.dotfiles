function workon
	if test "$argv" = ""
		echo "Must specify a virtualenv"
		return 1
	end
    set workon_home_or $WORKON_HOME $HOME/.virtualenvs
    set ve "$workon_home_or[1]/$argv[1]"
    set activate "$ve/bin/activate.fish"
    if not test -f "$activate"
    	echo "No virtualenv at $ve"
    	return 1
    end
    . "$activate"
    if test -f "$ve/.project"
        cd (cat $ve/.project)
    end
end
