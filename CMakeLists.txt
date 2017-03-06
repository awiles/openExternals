project(openExternals)

cmake_minimum_required(VERSION 2.8.11)

# if we don't define it, let's assume debug.
if(NOT DEFINED CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Debug)
endif()

# Output directories.
SET(LIBRARY_OUTPUT_PATH ${openExternals_BINARY_DIR}/bin CACHE INTERNAL "Single output directory for building all libraries.")
SET(EXECUTABLE_OUTPUT_PATH ${openExternals_BINARY_DIR}/bin CACHE INTERNAL "Single output directory for building all executables.")
SET(CXX_TEST_PATH ${EXECUTABLE_OUTPUT_PATH})

set(CMAKE_PREFIX_PATH)

# set the QT_DIR and set up some other variables.
if(WIN32)
	# TODO:This works for Windows, MSVC 2012, 64 bits.  Need logic here based on the generator.
    set(QT_DIR "C:\\Qt\\5.2.1\\msvc2012_64_opengl" CACHE PATH "Need to set the Qt prefix for various things.")
    set(CMAKE_LIBRARY_PATH "C:\\Program Files (x86)\\Windows Kits\\8.0\\Lib\\win8\\um\\x64" CACHE PATH "Qt5 requires this.")
	# Need wzunzip.exe for Boost download on windows.
elseif(APPLE)
    # assume QT is installed to /opt/Qt
    # need to use 5.4 with VTK 6.3 on Mac OSX Sierra.
    set(QT_DIR "/opt/Qt/5.4/clang_64" CACHE PATH "Need to set the Qt prefix for various things.")
else()
    set(QT_DIR "/opt/Qt/5.2.1/gcc_64" CACHE PATH "Need to set the Qt path in order to find it more easily." )
endif()
# update the prefixes.
list(APPEND CMAKE_PREFIX_PATH ${QT_DIR})

# set up the external tests.
include(ExternalProject)

########  Eigen ##########
set(EIGEN_REPO https://bitbucket.org/eigen/eigen/)
ExternalProject_Add( eigen
	PREFIX eigen
    SOURCE_DIR eigen/eigen
	#BINARY_DIR eigen/eigenBuild <-- we don't need this right now.
	HG_REPOSITORY ${EIGEN_REPO}
	HG_TAG 3.2.2
	CONFIGURE_COMMAND ""
	BUILD_COMMAND ""
	INSTALL_COMMAND ""
	CMAKE_ARGS
		-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
	    -DEIGEN_TEST_NOQT:BOOL=ON )
		
set(openExternals_EIGEN_DIR ${CMAKE_BINARY_DIR}/eigen/eigen)

########  VTK  ###########
if(APPLE)
    set(extra_params "-DVTK_REQUIRED_OBJCXX_FLAGS:STRING=")
endif()
ExternalProject_Add( vtk6
	PREFIX vtk
    SOURCE_DIR vtk/vtk
	BINARY_DIR vtk/vtkBuild
	INSTALL_DIR vtk/vtkInstall
	GIT_REPOSITORY https://github.com/Kitware/VTK.git
    GIT_TAG v6.3.0
	CMAKE_ARGS
		-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
        -DVTK_Group_Qt:BOOL=ON
		-DVTK_QT_VERSION:STRING=5
		-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}
		-DCMAKE_LIBRARY_PATH:STRING=${CMAKE_LIBRARY_PATH}
		-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_BINARY_DIR}/vtk/vtkInstall
		-DBUILD_SHARED_LIBS:BOOL=ON
		-DBUILD_DOCUMENTATION:BOOL=OFF
		-DBUILD_TESTING:BOOL=OFF
        -DBUILD_EXAMPLES:BOOL=OFF
                ${extra_params} )
				
set(openExternals_VTK_INSTALL_DIR ${CMAKE_BINARY_DIR}/vtk/vtkInstall)
set(openExternals_VTK_DIR ${openExternals_VTK_INSTALL_DIR}/lib/cmake/vtk-6.3)


########  OpenCV  ########
option(openExternals_USE_OPENCV_2_4 "Revert to openCV 2.4.13.2 instead of the 3.0.0-beta." ON)
if( openExternals_USE_OPENCV_2_4)
    # need 2.4.13.2 to fix the Mac OSX Sierra 10.12 issue with QTKit.
	set(OPENCV_GIT_TAG "2.4.13.2" )
else()
	# Build the released version of opencv
	set(OPENCV_GIT_TAG "3.0.0")
	#set(OPENCV_GIT_TAG "origin/master")
	# For OpenCV 3.0.0-beta, OpenCV is compiled with CUDA support when -DBUILD_CUDA_STUBS is turned on.
	# Check whether CUDA toolkit (http://developer.nvidia.com/cuda-toolkit) has been installed first.
	find_package(CUDA)
endif()
if(WIN32)
	set(openCV_CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /DHAVE_DSHOW /DHAVE_VIDEOINPUT" )
	set(openCV_CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /DHAVE_DSHOW /DHAVE_VIDEOINPUT" )
	message(STATUS "OpenCV CXX_FLAGS: ${openCV_CMAKE_CXX_FLAGS}")
	message(STATUS "OpenCV C_FLAGS: ${openCV_CMAKE_C_FLAGS}")
endif()
message(STATUS "Using OpenCV ${OPENCV_GIT_TAG}")

ExternalProject_Add( OpenCV
	PREFIX opencv
	SOURCE_DIR opencv/opencv
	BINARY_DIR opencv/opencvBuild
	INSTALL_DIR opencv/opencvInstall
	GIT_REPOSITORY https://github.com/Itseez/opencv.git
	GIT_TAG ${OPENCV_GIT_TAG}
	DEPENDS eigen vtk6
	CMAKE_ARGS
		-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
		-DWITH_QT:BOOL=ON
		-DWITH_OPENGL:BOOL=ON
		if(CUDA_FOUND AND ${OPENCV_GIT_TAG} EQUAL "origin/master" )
			-DBUILD_CUDA_STUBS:BOOL=ON
		else()
			-DWITH_CUDA:BOOL=OFF
		endif()
		-DVTK_DIR=${openExternals_VTK_DIR}
		-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_BINARY_DIR}/opencv/opencvInstall
		-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}
		-DCMAKE_LIBRARY_PATH:STRING=${CMAKE_LIBRARY_PATH} )
		#if(WIN32)
		#	-DCMAKE_CXX_FLAGS:STRING=${openCV_CMAKE_CXX_FLAGS}
		#	-DCMAKE_C_FLAGS:STRING=${openCV_CMAKE_C_FLAGS}
		#endif() )		
		
set(openExternals_OPENCV_DIR ${CMAKE_BINARY_DIR}/opencv/opencvInstall)
# do we need this the below variable?  OpenCVConfig.cmake should provide a variable.
set(openExternals_OPENCV_INCLUDE_DIR ${CMAKE_BINARY_DIR}/opencv/opencvInstall/include)

########  OpenIGTLink  ########
ExternalProject_Add( openIGTLink
	PREFIX openIGTLink
    SOURCE_DIR openIGTLink/openIGTLink
	BINARY_DIR openIGTLink/openIGTLinkBuild
	INSTALL_DIR openIGTLink/openIGTLinkInstall
	GIT_REPOSITORY https://github.com/openigtlink/OpenIGTLink.git
    GIT_TAG v2.0
	CMAKE_ARGS
		-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
		-DBUILD_SHARED_LIBS:BOOL=ON
		-DBUILD_TESTING:BOOL=OFF
		-DUSE_GTEST:BOOL=OFF
		-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_BINARY_DIR}/openIGTLink/openIGTLinkInstall
        -DBUILD_EXAMPLES:BOOL=OFF )
				
set(openExternals_OPENIGTLINK_INSTALL_DIR ${CMAKE_BINARY_DIR}/openIGTLink/openIGTLinkInstall)
set(openExternals_OPENIGTLINK_DIR ${openExternals_OPENIGTLINK_INSTALL_DIR}/lib/igtl)

# set up the cmake configuration
configure_file(
	${CMAKE_SOURCE_DIR}/cmake/openExternalsConfig.cmake.in
	${CMAKE_BINARY_DIR}/openExternalsConfig.cmake )
	
# set up the batch files.
include(${CMAKE_SOURCE_DIR}/cmake/setupRuntimePaths.cmake)
