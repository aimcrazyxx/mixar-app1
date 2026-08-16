REM SPDX-FileCopyrightText: 2026 Adeveda Enterprises Private Limited
REM
REM SPDX-License-Identifier: GPL-2.0-or-later

@echo off
setlocal enabledelayedexpansion

REM Initialize Blender upstream to the exact commit specified by the parent repo.
REM Skip LFS during the initial clone so the checkout does not download large
REM binary payloads before the platform-specific dependency repository is ready.
echo Initializing Blender submodule...
set "GIT_LFS_SKIP_SMUDGE=1"
git submodule update --init --recursive --force --progress upstream
if errorlevel 1 (
    echo Failed to initialize Blender submodule
    exit /b 1
)
set "GIT_LFS_SKIP_SMUDGE="

cd upstream
if errorlevel 1 exit /b 1

REM Blender marks platform library submodules with "update = none". On an
REM interactive Windows build, make.bat asks whether it should enable and fetch
REM lib/windows_x64. GitHub Actions has no interactive stdin, so that prompt
REM defaults to "No" and the build fails. Enable the Windows x64 library
REM submodule explicitly before running Blender's updater.
echo Initializing Blender Windows x64 precompiled libraries...
git config --local "submodule.lib/windows_x64.update" "checkout"
if errorlevel 1 (
    echo Failed to enable lib/windows_x64 submodule
    exit /b 1
)

set "GIT_LFS_SKIP_SMUDGE=1"
git submodule update --init --force --progress lib/windows_x64
if errorlevel 1 (
    echo Failed to initialize lib/windows_x64 submodule
    exit /b 1
)
set "GIT_LFS_SKIP_SMUDGE="

echo Pulling Windows x64 library LFS files...
git -C lib/windows_x64 lfs pull
if errorlevel 1 (
    echo Failed to download lib/windows_x64 LFS files
    exit /b 1
)

REM Use Blender's native Windows updater. Because lib/windows_x64 already
REM exists, check_libraries.cmd does not prompt for interactive input.
echo Running Blender Windows update...
call make.bat update
if errorlevel 1 (
    echo Blender dependency update failed
    exit /b 1
)

echo Pulling Blender source LFS files...
git lfs pull
if errorlevel 1 (
    echo Failed to pull Blender source LFS files
    exit /b 1
)

cd ..
echo Initialization complete!
exit /b 0
