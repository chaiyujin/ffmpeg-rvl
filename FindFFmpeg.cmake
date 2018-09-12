# adapt from https://github.com/snikulov/cmake-modules

# vim: ts=2 sw=2
# - Try to find the required ffmpeg components(default: AVFORMAT, AVUTIL, AVCODEC)
#
# Once done this will define
#    FFMPEG_FOUND                 - System has the all required components.
#    FFMPEG_INCLUDE_DIRS    - Include directory necessary for using the required components headers.
#    FFMPEG_LIBRARIES         - Link these to use the required ffmpeg components.
#    FFMPEG_DEFINITIONS     - Compiler switches required for using the required ffmpeg components.
#
# For each of the components it will additionally set.
#     - AVCODEC
#     - AVDEVICE
#     - AVFORMAT
#     - AVFILTER
#     - AVUTIL
#     - POSTPROC
#     - SWSCALE
# the following variables will be defined
#    <component>_FOUND                - System has <component>
#    <component>_INCLUDE_DIRS - Include directory necessary for using the <component> headers
#    <component>_LIBRARIES        - Link these to use <component>
#    <component>_DEFINITIONS    - Compiler switches required for using <component>
#    <component>_VERSION            - The components version
#
# Copyright (c) 2006, Matthias Kretz, <kretz@kde.org>
# Copyright (c) 2008, Alexander Neundorf, <neundorf@kde.org>
# Copyright (c) 2011, Michael Jansen, <kde@michael-jansen.biz>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

if (UNIX)
    # the install shell will install ffmpeg at $HOME/ffmpeg_build/
    set(FFMPEG_INSTALL_PATH "$ENV{HOME}/ffmpeg_build")
else()
    # change $ENV{HOME} to msys2 home
    set(MSYS_HOME "C:/msys64/home/admin")
    set(FFMPEG_INSTALL_PATH "${MSYS_HOME}/ffmpeg_build")
endif (UNIX)

include(FindPackageHandleStandardArgs)

# The default components were taken from a survey over other FindFFMPEG.cmake files
if (NOT FFmpeg_FIND_COMPONENTS)
    set(FFmpeg_FIND_COMPONENTS AVCODEC AVDEVICE AVFORMAT AVUTIL POSTPROC SWSCALE SWRESAMPLE)
endif ()

#
### Macro: set_component_found
#
# Marks the given component as found if both *_LIBRARIES AND *_INCLUDE_DIRS is present.
#
macro(set_component_found _component )
    if (${_component}_LIBRARIES AND ${_component}_INCLUDE_DIRS)
        # message(STATUS "    - ${_component} found.")
        set(${_component}_FOUND TRUE)
    else ()
        # message(STATUS "    - ${_component} not found. ${${_component}_LIBRARIES} ${${_component}_INCLUDE_DIRS}")
    endif ()
endmacro()

#
### Macro: find_component
#
# Checks for the given component by invoking pkgconfig and then looking up the libraries and
# include directories.
#
macro(find_component _component _pkgconfig _library _header)
    
    if (UNIX)
        # use pkg config to find ffmpeg build from shell
        find_package(PkgConfig)
        if (PKG_CONFIG_FOUND)
            set(ENV{PKG_CONFIG_PATH} "${FFMPEG_INSTALL_PATH}/lib/pkgconfig")
            pkg_check_modules(PC_${_component} ${_pkgconfig})

            # find from path
            find_path(${_component}_INCLUDE_DIRS ${_header}
                HINTS "${FFMPEG_INSTALL_PATH}/include/" )
            find_library(${_component}_LIBRARIES NAMES ${_library}
                HINTS "${FFMPEG_INSTALL_PATH}/lib/" )
            
            # process ldflags
            if (APPLE)
            else()
                set(${_component}_EXTRA_LDFLAGS ${PC_${_component}_LDFLAGS})
            endif (APPLE)
            set(${_component}_LIBRARIES     ${${_component}_LIBRARIES} ${${_component}_EXTRA_LDFLAGS})

            set(${_component}_DEFINITIONS   ${PC_${_component}_CFLAGS_OTHER} CACHE STRING "The ${_component} CFLAGS.")
            set(${_component}_VERSION       ${PC_${_component}_VERSION}      CACHE STRING "The ${_component} version number.")

            set_component_found(${_component})            
        endif ()
    else()
        # in windows
        find_path(${_component}_INCLUDE_DIRS ${_header}
            HINTS "${FFMPEG_INSTALL_PATH}/include/" )
        find_library(${_component}_LIBRARIES NAMES ${_library}
            HINTS "${FFMPEG_INSTALL_PATH}/lib/")
        set_component_found(${_component})
    endif (UNIX)

    mark_as_advanced(
        ${_component}_INCLUDE_DIRS
        ${_component}_LIBRARIES
        ${_component}_DEFINITIONS
        ${_component}_VERSION)

endmacro()

macro (FFMPEG_COPY_DLL projectName)
    if (WIN32)
        file(GLOB FFMPEG_DLLS "${FFMPEG_INSTALL_PATH}/bin/*.dll" )
        foreach(THEDLL ${FFMPEG_DLLS})
            message(STATUS "  |> Copy DLL: ${THEDLL}")
            add_custom_command(TARGET ${projectName} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                # source  # target
                ${THEDLL} $<TARGET_FILE_DIR:${projectName}>)
        endforeach(THEDLL ${SNOW_WIN32_DLLS})
    endif  (WIN32)
endmacro()

# Check for cached results. If there are skip the costly part.
if (TRUE)

    # Check for all possible component.
    find_component(AVCODEC    libavcodec    avcodec    libavcodec/avcodec.h)
    find_component(AVFORMAT   libavformat   avformat   libavformat/avformat.h)
    find_component(AVDEVICE   libavdevice   avdevice   libavdevice/avdevice.h)
    find_component(AVUTIL     libavutil     avutil     libavutil/avutil.h)
    find_component(AVFILTER   libavfilter   avfilter   libavfilter/avfilter.h)
    find_component(SWSCALE    libswscale    swscale    libswscale/swscale.h)
    find_component(POSTPROC   libpostproc   postproc   libpostproc/postprocess.h)
    find_component(SWRESAMPLE libswresample swresample libswresample/swresample.h)

    # Check if the required components were found and add their stuff to the FFMPEG_* vars.
    foreach (_component ${FFmpeg_FIND_COMPONENTS})
        if (${_component}_FOUND)
            # message(STATUS "Required component ${_component} present.")
            set(FFMPEG_LIBRARIES   ${FFMPEG_LIBRARIES}   ${${_component}_LIBRARIES})
            set(FFMPEG_DEFINITIONS ${FFMPEG_DEFINITIONS} ${${_component}_DEFINITIONS})
            list(APPEND FFMPEG_INCLUDE_DIRS ${${_component}_INCLUDE_DIRS})
        else ()
            message(STATUS "Required component ${_component} missing.")
        endif ()
    endforeach ()

    # Build the include path with duplicates removed.
    if (FFMPEG_INCLUDE_DIRS)
        list(REMOVE_DUPLICATES FFMPEG_INCLUDE_DIRS)
    endif ()

    # cache the vars.
    set(FFMPEG_INCLUDE_DIRS ${FFMPEG_INCLUDE_DIRS} CACHE STRING "The FFmpeg include directories." FORCE)
    set(FFMPEG_LIBRARIES    ${FFMPEG_LIBRARIES}    CACHE STRING "The FFmpeg libraries." FORCE)
    set(FFMPEG_DEFINITIONS  ${FFMPEG_DEFINITIONS}  CACHE STRING "The FFmpeg cflags." FORCE)

    message(STATUS "${FFMPEG_INCLUDE_DIRS}")

    mark_as_advanced(FFMPEG_INCLUDE_DIRS
                     FFMPEG_LIBRARIES
                     FFMPEG_DEFINITIONS)

endif ()

# Now set the noncached _FOUND vars for the components.
foreach (_component AVCODEC AVDEVICE AVFORMAT AVUTIL POSTPROC SWSCALE SWRESAMPLE)
    set_component_found(${_component})
endforeach ()

# Compile the list of required vars
set(_FFmpeg_REQUIRED_VARS FFMPEG_LIBRARIES FFMPEG_INCLUDE_DIRS)
foreach (_component ${FFmpeg_FIND_COMPONENTS})
    list(APPEND _FFmpeg_REQUIRED_VARS ${_component}_LIBRARIES ${_component}_INCLUDE_DIRS)
endforeach ()

# Give a nice error message if some of the required vars are missing.
find_package_handle_standard_args(FFmpeg DEFAULT_MSG ${_FFmpeg_REQUIRED_VARS})