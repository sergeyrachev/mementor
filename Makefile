mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
project_dir := $(abspath $(mkfile_path))

scratch_dir := $(project_dir)/scratch

build_dir := $(scratch_dir)/build
dist_dir := $(scratch_dir)/dist
download_dir := $(scratch_dir)/download
deps_dir := $(scratch_dir)/deps

define _windows_mingw_makefile
cat <<'EOD'
.ONESHELL:
.SHELLFLAGS = -ec

mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
project_dir := $(abspath $(mkfile_path)/..)

scratch_dir := $(project_dir)/scratch
build_dir := $(scratch_dir)/build
dist_dir := $(scratch_dir)/dist
download_dir := $(scratch_dir)/download
deps_dir := $(scratch_dir)/deps

project_dir_winpath := $(shell cygpath -w $(project_dir))
scratch_dir_winpath := $(shell cygpath -w $(scratch_dir))
build_dir_winpath := $(shell cygpath -w $(build_dir))
dist_dir_winpath := $(shell cygpath -w $(dist_dir))
download_dir_winpath := $(shell cygpath -w $(download_dir))
deps_dir_winpath := $(shell cygpath -w $(deps_dir))

mingw_prefix_winpath := $(shell cygpath -w $$MINGW_PREFIX)

FORCE:

clean:
	-rm -rf $(build_dir) $(dist_dir) $(download_dir) $(deps_dir)

folders:
	mkdir -p $(build_dir) $(dist_dir) $(download_dir) $(deps_dir)

$(download_dir)/ffmpeg.marker:
	wget -O $(download_dir)/ffmpeg-4.3.2-2021-02-27-full_build-shared.zip https://github.com/GyanD/codexffmpeg/releases/download/4.3.2-2021-02-27/ffmpeg-4.3.2-2021-02-27-full_build-shared.zip
	touch $(download_dir)/ffmpeg.marker

$(build_dir)/ffmpeg.marker:
	7z x $(download_dir)/ffmpeg-4.3.2-2021-02-27-full_build-shared.zip -y -o$(download_dir)
	cp -r $(download_dir)/ffmpeg-4.3.2-2021-02-27-full_build-shared/* $(deps_dir)/
	touch $(build_dir)/ffmpeg.marker

ffmpeg: $(download_dir)/ffmpeg.marker $(build_dir)/ffmpeg.marker;

$(build_dir)/semver.marker:
	git clone https://gitlab.com/sergeyrachev/semver.git $(download_dir)/semver
	touch $(build_dir)/semver.marker

semver: $(build_dir)/semver.marker;

get-packages:
	pacman -Sy --noconfirm  \
	$$MINGW_PACKAGE_PREFIX-curl \
	$$MINGW_PACKAGE_PREFIX-boost \
	$$MINGW_PACKAGE_PREFIX-openssl \
	$$MINGW_PACKAGE_PREFIX-pkgconf \
	$$MINGW_PACKAGE_PREFIX-cmake \
	$$MINGW_PACKAGE_PREFIX-toolchain \
	$$MINGW_PACKAGE_PREFIX-7zip \
	$$MINGW_PACKAGE_PREFIX-wget \
	$$MINGW_PACKAGE_PREFIX-ninja \
	$$MINGW_PACKAGE_PREFIX-spdlog

battery: ffmpeg;

version: semver FORCE
	(cd $(build_dir) && $(download_dir)/semver/semver.sh)

artifact:
	export SEMVER_MAJOR=$(shell cat $(build_dir)/SEMVER_MAJOR)
	export SEMVER_MINOR=$(shell cat $(build_dir)/SEMVER_MINOR)
	export SEMVER_PATCH=$(shell cat $(build_dir)/SEMVER_PATCH)
	export SEMVER_TWEAK=$(shell cat $(build_dir)/SEMVER_TWEAK)
	export SEMVER_BUILD=$(shell cat $(build_dir)/SEMVER_BUILD)
	export SEMVER_REVISION=$(shell cat $(build_dir)/SEMVER_REVISION)
	export SEMVER_PHASE=$(shell cat $(build_dir)/SEMVER_PHASE)
	export SEMVER_CI=$(shell cat $(build_dir)/SEMVER_CI)
	export SEMVER_TIMESTAMP=$(shell cat $(build_dir)/SEMVER_TIMESTAMP)
	export SEMVER_MNEMONIC=$(shell cat $(build_dir)/SEMVER_MNEMONIC)
	export SEMVER_DIRTY=$(shell cat $(build_dir)/SEMVER_DIRTY)

	mkdir -p $(build_dir)/mementor
	cmake -Wno-dev --trace-expand --trace-redirect="$(build_dir_winpath)/mementor/cmake.log" -DCMAKE_INSTALL_PREFIX="$(dist_dir_winpath)" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(deps_dir_winpath)" -DBoost_USE_STATIC_LIBS=OFF -B "$(build_dir_winpath)/mementor" -S "$(project_dir_winpath)"
	cmake --build "$(build_dir_winpath)/mementor" --target install
	ctest --test-dir "$(build_dir_winpath)/mementor"
EOD
endef
export windows_mingw_makefile=$(value _windows_mingw_makefile)

clean:
	rm -rf $(build_dir) $(dist_dir) $(download_dir) $(deps_dir)

folders:
	mkdir -p $(build_dir) $(dist_dir) $(download_dir) $(deps_dir)

windows-mingw: folders
	eval "$$windows_mingw_makefile" > $(scratch_dir)/windows-mingw.Makefile
	$(MAKE) -f $(scratch_dir)/windows-mingw.Makefile battery version artifact

ubuntu24: ;

arch: ;

windows-native: ;
