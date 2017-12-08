function cdsitepackages
	cd (python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
	test "$argv" != ""; and cd $argv
end