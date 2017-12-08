function mkvirtualenv
	if test "$argv" = ""
		set venvname (basename (pwd))
		echo "Assuming the current directory ($venvname) is the requested virtualenv name"
		set venvargs "$venvname"
	else
		set venvname $argv[1]
		set venvargs $argv
	end

	set workon_home_or $WORKON_HOME $HOME/.virtualenvs
	mkdir -p $workon_home_or[1]
	pushd $workon_home_or[1]

	if test -e "$venvname"
		echo "A virtualenv named $venvname exists already!"
		return 1
	end

	virtualenv $venvargs
	or return 1

	. "$venvname"/bin/activate.fish
	popd
end