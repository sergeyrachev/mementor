mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
project_dir := $(abspath $(mkfile_path))

stage_dir := $(project_dir)/stage

build_dir := $(stage_dir)/build-dir
install_dir := $(stage_dir)/install-dir
download_dir := $(stage_dir)/download-dir
prefix_dir := $(stage_dir)/prefix-dir

define _windows_mingw_makefile
cat <<'EOD'
mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
project_dir := $(abspath $(mkfile_path)/..)
stage_dir := $(project_dir)/stage
build_dir := $(stage_dir)/build-dir
install_dir := $(stage_dir)/install-dir
download_dir := $(stage_dir)/download-dir
prefix_dir := $(stage_dir)/prefix-dir

project_dir_winpath := $(shell cygpath -w $(project_dir))
stage_dir_winpath := $(shell cygpath -w $(stage_dir))
build_dir_winpath := $(shell cygpath -w $(build_dir))
install_dir_winpath := $(shell cygpath -w $(install_dir))
download_dir_winpath := $(shell cygpath -w $(download_dir))
prefix_dir_winpath := $(shell cygpath -w $(prefix_dir))

mingw_prefix_winpath := $(shell cygpath -w $$MINGW_PREFIX)

FORCE:

clean:
	-rm -rf $(build_dir) $(install_dir) $(download_dir) $(prefix_dir)

folders:
	mkdir -p $(build_dir) $(install_dir) $(download_dir) $(prefix_dir)

$(download_dir)/ffmpeg.zip:
	wget -O $(download_dir)/ffmpeg.zip https://github.com/GyanD/codexffmpeg/releases/download/4.3.2-2021-02-27/ffmpeg-4.3.2-2021-02-27-full_build-shared.zip

ffmpeg: $(download_dir)/ffmpeg.zip
	7z x $(download_dir)/ffmpeg.zip -y -o$(download_dir)
	cp -r $(download_dir)/ffmpeg-4.3.2-2021-02-27-full_build-shared/* $(prefix_dir)/

$(build_dir)/semver.marker:
	git clone https://gitlab.com/sergeyrachev/semver.git $(download_dir)/semver
	touch $(build_dir)/semver.marker

semver: $(build_dir)/semver.marker;

$(download_dir)/spdlog.marker:
	git clone --branch v1.8.2 --depth 1 https://github.com/gabime/spdlog.git $(download_dir)/spdlog
	touch $(download_dir)/spdlog.marker

$(build_dir)/spdlog.marker:
	mkdir -p $(build_dir)/spdlog
	cmake -Wno-dev --trace-expand --trace-redirect="$(build_dir_winpath)/spdlog/cmake.log" -DCMAKE_INSTALL_PREFIX="$(prefix_dir_winpath)" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(prefix_dir_winpath);$(mingw_prefix_winpath)" -B "$(build_dir_winpath)/spdlog" -S "$(download_dir_winpath)/spdlog"
	cmake --build $(build_dir_winpath)/spdlog --config Release --target install
	touch $(build_dir)/spdlog.marker

spdlog: $(download_dir)/spdlog.marker $(build_dir)/spdlog.marker;

get-packages:
	pacman -Sy --noconfirm  $$MINGW_PACKAGE_PREFIX-curl $$MINGW_PACKAGE_PREFIX-boost $$MINGW_PACKAGE_PREFIX-openssl $$MINGW_PACKAGE_PREFIX-pkgconf $$MINGW_PACKAGE_PREFIX-cmake $$MINGW_PACKAGE_PREFIX-toolchain $$MINGW_PACKAGE_PREFIX-7zip $$MINGW_PACKAGE_PREFIX-wget $$MINGW_PACKAGE_PREFIX-ninja

battery: ffmpeg spdlog;

version: semver FORCE
	(cd $(build_dir) && $(download_dir)/semver/semver.sh)

artifact:
	export SEMVER_MAJOR_NUMBER=$(shell cat $(build_dir)/SEMVER_MAJOR_NUMBER)
	export SEMVER_MINOR_NUMBER=$(shell cat $(build_dir)/SEMVER_MINOR_NUMBER)
	export SEMVER_PATCH_NUMBER=$(shell cat $(build_dir)/SEMVER_PATCH_NUMBER)
	export SEMVER_TWEAK_NUMBER=$(shell cat $(build_dir)/SEMVER_TWEAK_NUMBER)
	export SEMVER_BUILD_NUMBER=$(shell cat $(build_dir)/SEMVER_BUILD_NUMBER)
	export SEMVER_REVISION=$(shell cat $(build_dir)/SEMVER_REVISION)
	export SEMVER_PHASE=$(shell cat $(build_dir)/SEMVER_PHASE)
	export SEMVER_CI=$(shell cat $(build_dir)/SEMVER_CI)
	export SEMVER_TIMESTAMP=$(shell cat $(build_dir)/SEMVER_TIMESTAMP)
	export SEMVER_MNEMONIC=$(shell cat $(build_dir)/SEMVER_MNEMONIC)
	export SEMVER_DIRTY=$(shell cat $(build_dir)/SEMVER_DIRTY)

	mkdir -p $(build_dir)/mementor
	cmake -Wno-dev --trace-expand --trace-redirect="$(build_dir_winpath)/mementor/cmake.log" -DCMAKE_INSTALL_PREFIX="$(install_dir_winpath)" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(prefix_dir_winpath)" -B "$(build_dir_winpath)/mementor" -S "$(project_dir_winpath)"
	cmake --build "$(build_dir_winpath)/mementor" --config Release --target install
	ctest --test-dir "$(build_dir_winpath)/mementor"
EOD
endef
export windows_mingw_makefile=$(value _windows_mingw_makefile)

clean:
	rm -rf $(build_dir) $(install_dir) $(download_dir) $(prefix_dir)

folders:
	mkdir -p $(build_dir) $(install_dir) $(download_dir) $(prefix_dir)

windows-mingw: folders
	eval "$$windows_mingw_makefile" > $(stage_dir)/windows-mingw.Makefile
	$(MAKE) -f $(stage_dir)/windows-mingw.Makefile battery version artifact

ubuntu24: ;

arch: ;

windows-native: ;
