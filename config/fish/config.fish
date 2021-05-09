# Fish shell

# less highlighting
set hilite (which highlight)
set -x LESSOPEN "| $hilite %s --out-format xterm256 --line-numbers --quiet --force --style solarized-light"
set -x LESS " -R"

#set hilite (which src-hilite-lesspipe.sh)
#set -x LESSOPEN "| $hilite %s"
#set -x LESS " -R -X -F "

source ~/.dotfiles/julian_bash.sh

# Import bash_profile
egrep "^export " ~/.bash_profile | while read e
	set var (echo $e | sed -E "s/^export ([A-Z_]+)=(.*)\$/\1/")
	set value (echo $e | sed -E "s/^export ([A-Z_]+)=(.*)\$/\2/")
	
	# remove surrounding quotes if existing
	set value (echo $value | sed -E "s/^\"(.*)\"\$/\1/")

	if test $var = "PATH"
		# replace ":" by spaces. this is how PATH looks for Fish
		set value (echo $value | sed -E "s/:/ /g")
	
		# use eval because we need to expand the value
		eval set -xg $var $value

		continue
	end

	# evaluate variables. we can use eval because we most likely just used "$var"
	set value (eval echo $value)

	#echo "set -xg '$var' '$value' (via '$e')"
	set -xg $var $value
end
