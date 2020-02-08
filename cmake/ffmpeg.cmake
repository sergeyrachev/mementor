
find_package(PkgConfig)
if (PkgConfig_FOUND)
    pkg_check_modules(FFMPEG REQUIRED libavcodec libavformat libavutil libswresample libavdevice libavfilter)
    add_library(ffmpeg_api INTERFACE)
    target_link_libraries(ffmpeg_api INTERFACE ${FFMPEG_LIBRARIES})
    target_link_directories(ffmpeg_api INTERFACE ${FFMPEG_LIBRARY_DIRS})
    target_include_directories(ffmpeg_api INTERFACE ${FFMPEG_INCLUDE_DIRS})
    target_compile_options(ffmpeg_api INTERFACE ${FFMPEG_CFLAGS} ${FFMPEG_LDFLAGS})
    add_library(FFMPEG::api ALIAS ffmpeg_api )
endif ()

