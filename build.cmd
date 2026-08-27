@echo off
setlocal
if not exist build\dcu mkdir build\dcu
if not exist build\bpl mkdir build\bpl
if not exist build\dcp mkdir build\dcp

dcc32 -B -Q -N0build\dcu -LEbuild\bpl -LNbuild\dcp packages\HueRuntime.dpk || exit /b 1
dcc32 -B -Q -Ubuild\dcp -N0build\dcu -LEbuild\bpl -LNbuild\dcp packages\HueDesign.dpk || exit /b 1
dcc32 -B -Q -Ubuild\dcu;build\dcp -N0build\dcu -Ebuild tests\HueTests.dpr || exit /b 1
dcc32 -B -Q -Ubuild\dcu;build\dcp -N0build\dcu -Ebuild examples\ConsoleHueDemo.dpr || exit /b 1
dcc32 -B -Q -Ubuild\dcu;build\dcp -N0build\dcu -Ebuild examples\VersionNeutralControl.dpr || exit /b 1
dcc32 -B -Q -Ubuild\dcu;build\dcp -N0build\dcu -Ebuild examples\SimpleVCL\SimpleHueDemo.dpr || exit /b 1
dcc32 -B -Q -Ubuild\dcu;build\dcp -N0build\dcu -Ebuild examples\HomeAutomation\HomeAutomationDemo.dpr || exit /b 1
dcc32 -B -Q -Ubuild\dcu;build\dcp -N0build\dcu -Ebuild examples\SceneBrowser\SceneBrowserDemo.dpr || exit /b 1
dcc32 -B -Q -Ubuild\dcu;build\dcp -N0build\dcu -Ebuild examples\EventMonitor\EventMonitorDemo.dpr || exit /b 1
build\HueTests.exe || exit /b 1
endlocal
