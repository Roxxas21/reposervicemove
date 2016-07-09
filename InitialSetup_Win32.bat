@echo off
setlocal

::Select the path to the root opencv folder
set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Please select the root folder for Opencv (ex: c:\OpenCV-3.1.0).',0,0).self.path""
for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "OPENCV_ROOT_PATH=%%I"
if NOT DEFINED OPENCV_ROOT_PATH (goto failure)

::Select the path to the root Boost folder
set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Please select the root folder for Boost (ex: c:\local\boost_1_61_0).',0,0).self.path""
for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "BOOST_ROOT_PATH=%%I"
if NOT DEFINED BOOST_ROOT_PATH (goto failure)

::Substitute backslashes to forward slashes
set FWD_SLASH_OPENCV_ROOT_PATH=%OPENCV_ROOT_PATH:\=/%

:: Write out the paths to a config batch file
del SetBuildVars_Win32.bat
echo @echo off >> SetBuildVars_Win32.bat
echo set OPENCV_BUILD_PATH=%FWD_SLASH_OPENCV_ROOT_PATH%/sources/build/install >> SetBuildVars_Win32.bat
echo set BOOST_ROOT_PATH=%BOOST_ROOT_PATH% >> SetBuildVars_Win32.bat
echo set BOOST_LIB_PATH=%BOOST_ROOT_PATH%/lib32-msvc-14.0 >> SetBuildVars_Win32.bat

:: Add MSVC build tools to the path
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86

:: Generate the project files for OpenCV 32-bit
echo "Creating OpenCV 32-bit project files..."
pushd %OPENCV_ROOT_PATH%\sources
del /f /s /q build > nul
rmdir /s /q build
mkdir build
pushd build
cmake -G "Visual Studio 14 2015" -DBUILD_opencv_java=OFF -DBUILD_opencv_python2=OFF -DBUILD_opencv_python3=OFF ..
popd
popd

:: Compile the DEBUG|Win32 and RELEASE|Win32 builds of OpenCV
pushd %OPENCV_ROOT_PATH%\sources\build
echo "Building OpenCV DEBUG|Win32..."
MSBuild.exe OpenCV.sln /p:configuration=DEBUG /p:Platform="Win32" /t:Clean;Build 
echo "Installing OpenCV DEBUG|Win32..."
MSBuild.exe INSTALL.vcxproj /p:configuration=DEBUG /p:Platform="Win32" /t:Build
echo "Building OpenCV RELEASE|Win32..."
MSBuild.exe OpenCV.sln /p:configuration=RELEASE /p:Platform="Win32" /t:Clean;Build
echo "Installing OpenCV RELEASE|Win32..."
MSBuild.exe INSTALL.vcxproj /p:configuration=RELEASE /p:Platform="Win32" /t:Build
popd

:: Compile the DEBUG|Win32 and RELEASE|Win32 builds of protobuf
echo "Creating protobuf project files..."
pushd thirdparty\protobuf
del /f /s /q vsprojects > nul
rmdir /s /q vsprojects
mkdir vsprojects
pushd vsprojects
cmake -G "Visual Studio 14 2015" -Dprotobuf_DEBUG_POSTFIX="" -Dprotobuf_BUILD_TESTS=OFF ../cmake
echo "Building protobuf DEBUG|Win32"
MSBuild.exe protobuf.sln /p:configuration=DEBUG /t:Clean;Build 
echo "Building protobuf RELEASE|Win32"
MSBuild.exe protobuf.sln /p:configuration=RELEASE /t:Clean;Build
popd
popd

:: Compile the DEBUG|Win32 and RELEASE|Win32 builds of libusb
pushd thirdparty\libusb\msvc\
echo "Building libusb DEBUG|Win32..."
MSBuild.exe libusb_2015.sln /p:configuration=DEBUG /p:Platform="Win32" /t:Clean;Build 
echo "Building libusb RELEASE|Win32..."
MSBuild.exe libusb_2015.sln /p:configuration=RELEASE /p:Platform="Win32" /t:Clean;Build
popd

:: Compile the RELEASE|Win32 build of SDL2
echo "Creating SDL2 project files..."
pushd thirdparty\SDL2
del /f /s /q build > nul
rmdir /s /q build
mkdir build
pushd build
cmake .. -G "Visual Studio 14 2015" -DDIRECTX=OFF -DDIRECTX=OFF -DSDL_STATIC=ON -DFORCE_STATIC_VCRT=ON -DEXTRA_CFLAGS="-MT -Z7 -DSDL_MAIN_HANDLED -DWIN32 -DNDEBUG -D_CRT_SECURE_NO_WARNINGS -DHAVE_LIBC -D_USE_MATH_DEFINES
echo "Building SDL2 Release|Win32..."
MSBuild.exe SDL2.sln /p:configuration=RELEASE /p:Platform="Win32" /t:Clean
MSBuild.exe SDL2-static.vcxproj /p:configuration=RELEASE /p:Platform="Win32" /t:Build 
MSBuild.exe SDL2main.vcxproj /p:configuration=RELEASE /p:Platform="Win32" /t:Build
popd
popd

:: Generate the project files for PSMoveService
call GenerateProjectFiles_Win32.bat
pause
goto exit

:failure
goto exit

:exit
endlocal
