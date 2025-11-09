#====================================================================
#
#                       wNim Dark Mode Module
#
#====================================================================

## Dark mode support module for wNim applications.
## 
## This module provides automatic dark mode support for wNim GUI applications
## on Windows 10 (build 17763+) and Windows 11. It enables dark title bars,
## dark themed controls, and provides a complete dark color scheme.
##
## Based on https://github.com/ysc3839/win32-darkmode
##
## Basic Usage
## ===========
##
## .. code-block:: nim
##   import wNim
##   import wDarkMode
##   
##   let app = App()
##   enableDarkMode(app)  # Enable dark mode support
##   
##   let frame = Frame(title="My App")
##   applyDarkModeToWindow(frame)  # Apply to frame and all children
##   frame.show()
##   app.mainLoop()
##
## Features
## ========
##
## * Automatic detection of Windows 10/11 dark mode settings
## * Dark title bars for frames
## * Dark themed controls (TreeView, ListView, etc.)
## * Complete dark color scheme (background, foreground, controls)
## * High contrast mode detection and handling
## * Works on Windows 10 build 17763+ and Windows 11
##
## Requirements
## ============
##
## * Windows 10 build 17763 (version 1809) or later
## * wNim >= 0.13.0
## * winim >= 3.9.0

import wNim
import winim/[winstr, utils], winim/inc/[windef, winbase, winuser, uxtheme]

# Constants and types that may not be in winim
const
  SPI_GETHIGHCONTRAST* = 0x0042
  HCF_HIGHCONTRASTON* = 0x00000001

type
  HIGHCONTRAST* {.pure.} = object
    cbSize*: UINT
    dwFlags*: DWORD
    lpszDefaultScheme*: LPWSTR

type
  PreferredAppMode* = enum
    ## Preferred app mode for dark mode support (Windows 10 1903+)
    pamDefault = 0
    pamAllowDark = 1
    pamForceDark = 2
    pamForceLight = 3
    pamMax = 4

  WINDOWCOMPOSITIONATTRIB* = enum
    ## Window composition attributes
    WCA_UNDEFINED = 0
    WCA_NCRENDERING_ENABLED = 1
    WCA_NCRENDERING_POLICY = 2
    WCA_TRANSITIONS_FORCEDISABLED = 3
    WCA_ALLOW_NCPAINT = 4
    WCA_CAPTION_BUTTON_BOUNDS = 5
    WCA_NONCLIENT_RTL_LAYOUT = 6
    WCA_FORCE_ICONIC_REPRESENTATION = 7
    WCA_EXTENDED_FRAME_BOUNDS = 8
    WCA_HAS_ICONIC_BITMAP = 9
    WCA_THEME_ATTRIBUTES = 10
    WCA_NCRENDERING_EXILED = 11
    WCA_NCADORNMENTINFO = 12
    WCA_EXCLUDED_FROM_DDA = 24
    WCA_PASSIVEUPDATEMODE = 25
    WCA_USEDARKMODECOLORS = 26
    WCA_LAST = 27

  WINDOWCOMPOSITIONATTRIBDATA* = object
    ## Window composition attribute data
    attrib*: WINDOWCOMPOSITIONATTRIB
    pvData*: pointer
    cbData*: int

  IMMERSIVE_HC_CACHE_MODE* = enum
    ## Immersive high contrast cache mode
    IHCM_USE_CACHED_VALUE = 0
    IHCM_REFRESH = 1

# Function pointer types for undocumented uxtheme.dll functions
type
  fnRtlGetNtVersionNumbers = proc(major: ptr DWORD, minor: ptr DWORD, build: ptr DWORD) {.stdcall.}
  fnSetWindowCompositionAttribute = proc(hwnd: HWND, data: ptr WINDOWCOMPOSITIONATTRIBDATA): BOOL {.stdcall.}
  fnShouldAppsUseDarkMode = proc(): bool {.stdcall.}
  fnAllowDarkModeForWindow = proc(hwnd: HWND, allow: bool): bool {.stdcall.}
  fnAllowDarkModeForApp = proc(allow: bool): bool {.stdcall.}
  fnRefreshImmersiveColorPolicyState = proc() {.stdcall.}
  fnIsDarkModeAllowedForWindow = proc(hwnd: HWND): bool {.stdcall.}
  fnGetIsImmersiveColorUsingHighContrast = proc(mode: IMMERSIVE_HC_CACHE_MODE): bool {.stdcall.}
  fnSetPreferredAppMode = proc(appMode: PreferredAppMode): PreferredAppMode {.stdcall.}

# Global state
var
  g_darkModeSupported* = false
  g_darkModeEnabled* = false
  g_buildNumber: DWORD = 0

  # Function pointers
  g_SetWindowCompositionAttribute: fnSetWindowCompositionAttribute = nil
  g_ShouldAppsUseDarkMode: fnShouldAppsUseDarkMode = nil
  g_AllowDarkModeForWindow: fnAllowDarkModeForWindow = nil
  g_AllowDarkModeForApp: fnAllowDarkModeForApp = nil
  g_RefreshImmersiveColorPolicyState: fnRefreshImmersiveColorPolicyState = nil
  g_IsDarkModeAllowedForWindow: fnIsDarkModeAllowedForWindow = nil
  g_GetIsImmersiveColorUsingHighContrast: fnGetIsImmersiveColorUsingHighContrast = nil
  g_SetPreferredAppMode: fnSetPreferredAppMode = nil

# Dark mode color scheme constants
const
  # Dark mode colors - Carefully tuned for best appearance with native controls
  wDarkModeBackground* = 0x2B2B2B      # RGB(43, 43, 43) - Main window background
  wDarkModeForeground* = 0xFFFFFF      # RGB(255, 255, 255) - White text
  wDarkModeControl* = 0x3C3C3C         # RGB(60, 60, 60) - Control background

  # Light mode colors (standard Windows light theme)
  wLightModeBackground* = 0xF0F0F0     # RGB(240, 240, 240) - Light gray background
  wLightModeForeground* = 0x000000     # RGB(0, 0, 0) - Black text
  wLightModeControl* = 0xFFFFFF        # RGB(255, 255, 255) - White for controls

proc isHighContrast*(): bool =
  ## Check if Windows is using high contrast mode
  var highContrast = HIGHCONTRAST(cbSize: sizeof(HIGHCONTRAST).UINT, lpszDefaultScheme: nil)
  if SystemParametersInfo(SPI_GETHIGHCONTRAST, sizeof(HIGHCONTRAST).UINT, addr highContrast, 0) != 0:
    result = (highContrast.dwFlags and HCF_HIGHCONTRASTON) != 0
  else:
    result = false

proc allowDarkModeForWindow*(hwnd: HWND, allow: bool): bool =
  ## Allow dark mode for a specific window
  if g_darkModeSupported and not g_AllowDarkModeForWindow.isNil:
    result = g_AllowDarkModeForWindow(hwnd, allow)
  else:
    result = false

proc setWindowDarkTheme*(hwnd: HWND, enable: bool = true) =
  ## Apply dark theme to a window control using undocumented APIs.
  ## This works for some controls (TreeView, ListView, etc.) but not all.
  if not g_darkModeSupported:
    return
  
  if enable:
    # Try approach 1: DarkMode_Explorer theme
    discard SetWindowTheme(hwnd, "DarkMode_Explorer", nil)
    # Try approach 2: AllowDarkModeForWindow + Explorer theme
    discard allowDarkModeForWindow(hwnd, true)
    discard SetWindowTheme(hwnd, "Explorer", nil)
  else:
    # Revert to default theme
    discard SetWindowTheme(hwnd, nil, nil)

proc refreshTitleBarThemeColor*(hwnd: HWND) =
  ## Refresh the title bar theme color for a window
  if not g_darkModeSupported:
    return

  var dark: BOOL = 0
  if not g_IsDarkModeAllowedForWindow.isNil and 
     not g_ShouldAppsUseDarkMode.isNil and
     g_IsDarkModeAllowedForWindow(hwnd) and
     g_ShouldAppsUseDarkMode() and
     not isHighContrast():
    dark = 1

  if g_buildNumber < 18362:
    SetProp(hwnd, "UseImmersiveDarkModeColors", cast[HANDLE](dark))
  elif not g_SetWindowCompositionAttribute.isNil:
    var data = WINDOWCOMPOSITIONATTRIBDATA(
      attrib: WCA_USEDARKMODECOLORS,
      pvData: addr dark,
      cbData: sizeof(dark)
    )
    discard g_SetWindowCompositionAttribute(hwnd, addr data)

proc allowDarkModeForApp*(allow: bool) =
  ## Allow dark mode for the entire application
  if not g_AllowDarkModeForApp.isNil:
    discard g_AllowDarkModeForApp(allow)
  elif not g_SetPreferredAppMode.isNil:
    discard g_SetPreferredAppMode(if allow: pamAllowDark else: pamDefault)

proc checkBuildNumber(buildNumber: DWORD): bool =
  ## Check if the build number supports dark mode
  result = (buildNumber == 17763 or  # 1809
            buildNumber == 18362 or  # 1903
            buildNumber == 18363 or  # 1909
            buildNumber == 19041 or  # 2004
            buildNumber >= 19042)    # 2009 and later

proc initDarkMode*(): bool =
  ## Initialize dark mode support. Returns true if dark mode is supported.
  # Get Windows build number
  let hNtdll = GetModuleHandle("ntdll.dll")
  if hNtdll == 0:
    return false
  
  let RtlGetNtVersionNumbers = cast[fnRtlGetNtVersionNumbers](
    GetProcAddress(hNtdll, "RtlGetNtVersionNumbers"))
  
  if RtlGetNtVersionNumbers.isNil:
    return false
  
  var major, minor: DWORD
  RtlGetNtVersionNumbers(addr major, addr minor, addr g_buildNumber)
  g_buildNumber = g_buildNumber and DWORD(not 0xF0000000'u32)
  
  # Check if Windows 10 with dark mode support
  if major < 10 or not checkBuildNumber(g_buildNumber):
    return false
  
  # Load uxtheme.dll functions by ordinal
  let hUxtheme = LoadLibraryEx("uxtheme.dll", 0, LOAD_LIBRARY_SEARCH_SYSTEM32)
  if hUxtheme == 0:
    return false
  
  # Load functions by ordinal number
  g_RefreshImmersiveColorPolicyState = cast[fnRefreshImmersiveColorPolicyState](
    GetProcAddress(hUxtheme, cast[LPCSTR](104)))
  g_GetIsImmersiveColorUsingHighContrast = cast[fnGetIsImmersiveColorUsingHighContrast](
    GetProcAddress(hUxtheme, cast[LPCSTR](106)))
  g_ShouldAppsUseDarkMode = cast[fnShouldAppsUseDarkMode](
    GetProcAddress(hUxtheme, cast[LPCSTR](132)))
  g_AllowDarkModeForWindow = cast[fnAllowDarkModeForWindow](
    GetProcAddress(hUxtheme, cast[LPCSTR](133)))
  
  let ord135 = GetProcAddress(hUxtheme, cast[LPCSTR](135))
  if g_buildNumber < 18362:
    g_AllowDarkModeForApp = cast[fnAllowDarkModeForApp](ord135)
  else:
    g_SetPreferredAppMode = cast[fnSetPreferredAppMode](ord135)
  
  g_IsDarkModeAllowedForWindow = cast[fnIsDarkModeAllowedForWindow](
    GetProcAddress(hUxtheme, cast[LPCSTR](137)))
  
  # Load SetWindowCompositionAttribute from user32.dll
  let hUser32 = GetModuleHandle("user32.dll")
  if hUser32 != 0:
    g_SetWindowCompositionAttribute = cast[fnSetWindowCompositionAttribute](
      GetProcAddress(hUser32, "SetWindowCompositionAttribute"))
  
  # Check if all required functions are available
  if g_RefreshImmersiveColorPolicyState.isNil or
     g_ShouldAppsUseDarkMode.isNil or
     g_AllowDarkModeForWindow.isNil or
     (g_AllowDarkModeForApp.isNil and g_SetPreferredAppMode.isNil) or
     g_IsDarkModeAllowedForWindow.isNil:
    return false
  
  g_darkModeSupported = true
  
  # Enable dark mode for the app
  allowDarkModeForApp(true)
  
  if not g_RefreshImmersiveColorPolicyState.isNil:
    g_RefreshImmersiveColorPolicyState()
  
  # Check if dark mode is currently enabled
  g_darkModeEnabled = (not g_ShouldAppsUseDarkMode.isNil and 
                       g_ShouldAppsUseDarkMode() and 
                       not isHighContrast())
  
  result = true

proc isDarkModeSupported*(): bool =
  ## Check if dark mode is supported on this system
  result = g_darkModeSupported

proc isDarkModeEnabled*(): bool =
  ## Check if dark mode is currently enabled by the user
  result = g_darkModeEnabled

proc updateDarkModeStatus*() =
  ## Update the dark mode enabled status based on current system settings
  if g_darkModeSupported and not g_ShouldAppsUseDarkMode.isNil:
    g_darkModeEnabled = g_ShouldAppsUseDarkMode() and not isHighContrast()

proc applyDarkModeToWindowRecursive(win: wWindow, enable: bool)

proc applyDarkModeToWindow*(win: wWindow, enable: bool = true) =
  ## Apply dark mode colors and theme to a window and all its children.
  ## Call this on your Frame or Panel after creation.
  if not g_darkModeSupported:
    return
  
  # Apply to Frame title bar
  if win of wFrame:
    let frame = wFrame(win)
    discard allowDarkModeForWindow(frame.handle, enable)
    refreshTitleBarThemeColor(frame.handle)
  
  # Apply colors and themes recursively
  applyDarkModeToWindowRecursive(win, enable)

proc applyDarkModeToWindowRecursive(win: wWindow, enable: bool) =
  ## Internal recursive function to apply dark mode
  # Set background and foreground colors
  if enable:
    win.backgroundColor = wDarkModeBackground
    win.foregroundColor = wDarkModeForeground
  else:
    win.backgroundColor = wLightModeBackground
    win.foregroundColor = wLightModeForeground
  
  # Apply theme to controls
  if win of wControl:
    setWindowDarkTheme(win.handle, enable)
  
  # Recursively apply to all children
  for child in win.children:
    applyDarkModeToWindowRecursive(child, enable)
  
  # Refresh the window
  win.refresh()

proc enableDarkMode*(app: wApp) =
  ## Enable dark mode support for the application.
  ## Call this after creating your App instance.
  if initDarkMode():
    echo "Dark mode initialized successfully"
    if g_darkModeEnabled:
      echo "Dark mode is currently enabled"
    else:
      echo "Dark mode is currently disabled (light theme)"
  else:
    echo "Dark mode is not supported (requires Windows 10 build 17763+)"

proc enableDarkModeForFrame*(frame: wFrame, enable: bool = true) =
  ## Convenience function to enable dark mode for a frame and all its children.
  ## This applies the title bar dark mode and recursively sets colors.
  if not g_darkModeSupported:
    return
  
  # Enable dark mode for title bar
  discard allowDarkModeForWindow(frame.handle, enable)
  refreshTitleBarThemeColor(frame.handle)
  
  # Apply to frame and all children
  applyDarkModeToWindow(frame, enable)

# Export useful functions for manual control
export isDarkModeSupported, isDarkModeEnabled, updateDarkModeStatus
export applyDarkModeToWindow, enableDarkMode, enableDarkModeForFrame
export setWindowDarkTheme, refreshTitleBarThemeColor, allowDarkModeForWindow
export wDarkModeBackground, wDarkModeForeground, wDarkModeControl
export wLightModeBackground, wLightModeForeground, wLightModeControl