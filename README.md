# wDarkMode

Dark mode support module for [wNim](https://github.com/khchen/wNim) applications on Windows 10/11.

## Note

The current theming targets core controls, but many controls may still render poorly or require owner‑draw/custom handling to look correct.

Contributions welcome: if you can expand control coverage, fix theming edge cases, or add examples, please open a pull request.

## Features

* ✨ Automatic detection of Windows dark mode settings
* 🎨 Dark title bars for frames
* 🖌️ Dark themed controls (TreeView, ListView, and more)
* 🎭 Complete dark color scheme (background, foreground, controls)
* ♿ High contrast mode detection and handling
* 🪟 Works on Windows 10 build 17763+ (version 1809) and Windows 11

## Installation

### Via Nimble

```bash
nimble install https://github.com/bunkford/wDarkMode@#HEAD
```

### Manual Installation

Clone this repository and build your project with the wDarkMode source:

```bash
git clone https://github.com/bunkford/wDarkMode.git
```

## Requirements

* Windows 10 build 17763 (version 1809) or later
* Nim >= 1.6.0
* [wNim](https://github.com/khchen/wNim) >= 0.13.0
* [winim](https://github.com/khchen/winim) >= 3.9.0

## Usage

### Basic Usage

```nim
import wNim
import wDarkMode

let app = App()
enableDarkMode(app)  # Enable dark mode support

let frame = Frame(title="My Dark Mode App")
applyDarkModeToWindow(frame)  # Apply to frame and all children

frame.show()
app.mainLoop()
```

### Advanced Usage

```nim
import wNim
import wDarkMode

let app = App(wSystemDpiAware)

# Initialize and check dark mode support
if initDarkMode():
  echo "Dark mode is supported!"
  
  # Check if user has dark mode enabled
  if isDarkModeEnabled():
    echo "User prefers dark mode"
  else:
    echo "User prefers light mode"
else:
  echo "Dark mode not supported on this system"

let frame = Frame(title="Advanced Dark Mode Demo", size=(800, 600))
let panel = Panel(frame)

# Create controls
let button = Button(panel, label="Click Me", pos=(20, 20))
let textCtrl = TextCtrl(panel, pos=(20, 60), size=(300, 100))
let listBox = ListBox(panel, pos=(20, 180), size=(300, 200))

# Apply dark mode to frame and all children
enableDarkModeForFrame(frame, enable=true)

frame.show()
app.mainLoop()
```

### Manual Color Control

You can use the provided color constants for custom controls:

```nim
import wNim
import wDarkMode

let panel = Panel(frame)

if isDarkModeEnabled():
  panel.backgroundColor = wDarkModeBackground
  panel.foregroundColor = wDarkModeForeground
else:
  panel.backgroundColor = wLightModeBackground
  panel.foregroundColor = wLightModeForeground
```


### Main Functions

#### `enableDarkMode(app: wApp)`
Enable dark mode support for the application. Call this after creating your App instance.

#### `applyDarkModeToWindow(win: wWindow, enable: bool = true)`
Apply dark mode colors and theme to a window and all its children. Call this on your Frame or Panel after creation.

#### `enableDarkModeForFrame(frame: wFrame, enable: bool = true)`
Convenience function to enable dark mode for a frame and all its children. This applies the title bar dark mode and recursively sets colors.

#### `initDarkMode(): bool`
Initialize dark mode support. Returns `true` if dark mode is supported. This is called automatically by `enableDarkMode()`.

#### `isDarkModeSupported(): bool`
Check if dark mode is supported on this system (Windows 10 1809+ or Windows 11).

#### `isDarkModeEnabled(): bool`
Check if dark mode is currently enabled by the user in Windows settings.

#### `updateDarkModeStatus()`
Update the dark mode enabled status based on current system settings.

### Low-Level Functions

#### `allowDarkModeForWindow(hwnd: HWND, allow: bool): bool`
Allow dark mode for a specific window handle.

#### `setWindowDarkTheme(hwnd: HWND, enable: bool = true)`
Apply dark theme to a window control using undocumented APIs.

#### `refreshTitleBarThemeColor(hwnd: HWND)`
Refresh the title bar theme color for a window.

#### `isHighContrast(): bool`
Check if Windows is using high contrast mode.

### Color Constants

| Constant | RGB Value | Hex | Sample |
|----------|-----------:|-----:|:------:|
| `wDarkModeBackground` | RGB(43, 43, 43) | `#2B2B2B` | <div title="#2B2B2B" style="width:48px;height:24px;background:#2B2B2B;border:1px solid #ccc;border-radius:4px;"></div> |
| `wDarkModeForeground` | RGB(255, 255, 255) | `#FFFFFF` | <div title="#FFFFFF" style="width:48px;height:24px;background:#FFFFFF;border:1px solid #ccc;border-radius:4px;"></div> |
| `wDarkModeControl` | RGB(60, 60, 60) | `#3C3C3C` | <div title="#3C3C3C" style="width:48px;height:24px;background:#3C3C3C;border:1px solid #ccc;border-radius:4px;"></div> |
| `wLightModeBackground` | RGB(240, 240, 240) | `#F0F0F0` | <div title="#F0F0F0" style="width:48px;height:24px;background:#F0F0F0;border:1px solid #ccc;border-radius:4px;"></div> |
| `wLightModeForeground` | RGB(0, 0, 0) | `#000000` | <div title="#000000" style="width:48px;height:24px;background:#000000;border:1px solid #ccc;border-radius:4px;"></div> |
| `wLightModeControl` | RGB(255, 255, 255) | `#FFFFFF` | <div title="#FFFFFF" style="width:48px;height:24px;background:#FFFFFF;border:1px solid #ccc;border-radius:4px;"></div> |

## Examples

See the [examples](examples/) directory for complete working examples:

* [`darkmode.nim`](examples/darkmode.nim) - Comprehensive example demonstrating all features

### Running Examples

```bash
nim c -r examples/darkmode.nim
```

Or use the nimble task:

```bash
nimble examples
```

## How It Works

This module uses undocumented Windows APIs to enable dark mode support:

1. Detects Windows 10 build number to determine dark mode API availability
2. Loads undocumented functions from `uxtheme.dll` by ordinal number
3. Checks system settings to determine if dark mode is enabled
4. Applies dark mode to window title bars using `SetWindowCompositionAttribute`
5. Recursively applies dark colors to all window controls

The implementation is based on the excellent research and code from [ysc3839/win32-darkmode](https://github.com/ysc3839/win32-darkmode).

## Compatibility

| Windows Version | Build | Status |
|----------------|-------|--------|
| Windows 10 1809 | 17763 | ✅ Supported |
| Windows 10 1903 | 18362 | ✅ Supported |
| Windows 10 1909 | 18363 | ✅ Supported |
| Windows 10 2004 | 19041 | ✅ Supported |
| Windows 10 20H2+ | 19042+ | ✅ Supported |
| Windows 11 | 22000+ | ✅ Supported |

## Limitations

* Not all controls support dark theming (e.g., ComboBox may have issues)
* Some third-party controls may not respond to dark mode changes
* Title bar dark mode requires Windows 10 1809 or later
* High contrast mode takes precedence over dark mode

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details

## Credits

* Based on [ysc3839/win32-darkmode](https://github.com/ysc3839/win32-darkmode)
* Created for use with [wNim](https://github.com/khchen/wNim) by Ward

## Author

Duncan Clarke ([@bunkford](https://github.com/bunkford))

## See Also

* [wNim](https://github.com/khchen/wNim) - Windows Native Interface Module for Nim
* [winim](https://github.com/khchen/winim) - Windows API module for Nim
