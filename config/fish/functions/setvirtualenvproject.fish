function setvirtualenvproject
	if test "$VIRTUAL_ENV" = ""
		echo "No virtualenv activated!"
		return 1
	end
	set project $argv "."
	set fullproject (readlink -e $project[1])
	if test "$fullproject" = ""
		echo "$project[1] does not exist"
		return 1
	end
	echo "Setting virtualenv project home to $fullproject"
	echo "$fullproject" > "$VIRTUAL_ENV/.project"
end