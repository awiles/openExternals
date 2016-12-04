# set up the windows batch file for setting up the correct runtime paths.
# TODO: build a script for VS2010, VS2012 and VS2013.  Also flip between 32 and 64 bits when needed.

if(WIN32)
    set(openExternals_VTK_RUNTIME ${CMAKE_BINARY_DIR}/vtk/vtkInstall/bin )
    #set(openExternals_PCL_RUNTIME ${CMAKE_BINARY_DIR}/pcl/pclInstall/bin )
	if(MSVC11 AND CMAKE_CL_64 )
		message(STATUS "Setting the runtime batch files for Visual Studio 2012 Win64." )
	    set(openExternals_OPENCV_RUNTIME ${openExternals_OPENCV_DIR}/x64/vc11/bin )
		set(runtime_output_file ${CMAKE_BINARY_DIR}/../setupRuntimePaths-openExternals.bat)
		if( EXISTS ${runtime_output_file} )
			message(STATUS "Delete ${runtime_output_file}")
			file(REMOVE ${runtime_output_file})
		endif()
		configure_file(
			${CMAKE_SOURCE_DIR}/cmake/setupRuntimePaths-openExternals.bat.in
			 ${runtime_output_file})
		foreach(BUILD_TYPE Debug Release)
			set(devenv_output_file ${CMAKE_BINARY_DIR}/../openExternals-VS2012-64-dev${BUILD_TYPE}.bat)
			if( EXISTS ${devenv_output_file} )
				message(STATUS "Delete ${devenv_output_file}")
				file(REMOVE ${devenv_output_file})
			endif()			
			configure_file(
				${CMAKE_SOURCE_DIR}/cmake/openExternals-VS2012-64-dev.bat.in
				${devenv_output_file} )
		endforeach()
    else()
        message(WARNING "Runtime batch file not set up for this windows build.")
	endif()
else()
	message(STATUS "Setting the runtime shell script files for gcc." )
    set(openExternals_OPENCV_RUNTIME ${openExternals_OPENCV_DIR}/bin )
	set(runtime_output_file ${CMAKE_BINARY_DIR}/../setupRuntimePaths-openExternals.sh)
	if( EXISTS ${runtime_output_file} )
			message(STATUS "Delete ${runtime_output_file}")
			file(REMOVE ${runtime_output_file})
	endif()
    configure_file(	
		${CMAKE_SOURCE_DIR}/cmake/setupRuntimePaths-openExternals.sh.in
		${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/setupRuntimePaths-openExternals.sh
		@only )
	file(COPY ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/setupRuntimePaths-openExternals.sh
		DESTINATION ${CMAKE_BINARY_DIR}/../
		FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
	
endif(WIN32)