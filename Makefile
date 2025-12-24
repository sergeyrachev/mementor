mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
project_dir := $(abspath $(mkfile_path))

clean: windows-mingw-clean ;

windows-mingw:
	$(MAKE) -f ci/windows-mingw.Makefile battery version artifact

windows-mingw-clean:
	$(MAKE) -f ci/windows-mingw.Makefile clean
