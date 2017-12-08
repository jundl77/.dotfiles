function cd
	builtin cd $argv
	set workon_home_or $WORKON_HOME $HOME/.virtualenvs
	set virtual_env "$workon_home_or[1]/"(basename $PWD)
	set activation "$virtual_env/bin/activate.fish"
	if test "$virtual_env" != "$VIRTUAL_ENV"
		if test "$PWD" = "$virtual_env"
			. $activation
		else if begin
				set project "$virtual_env/.project"
				test -f "$project"
				and test "$PWD" = (cat $project) -a -f "$activation"
			end
			. $activation
		end
	end
end
