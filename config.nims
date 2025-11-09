# Nim configuration file for wDarkMode

# Add src directory to path so examples can import wDarkMode
switch("path", "src")
switch("path", "../src")  # For compiling from examples directory

# Compiler switches
switch("hint", "XDeclaredButNotUsed:off")

# Windows-specific settings (since this is a Windows dark mode module)
when defined(windows):
  # Enable multi-threading if needed
  # switch("threads", "on")
  
  # GUI app settings (no console window for GUI examples)
  when defined(release):
    switch("app", "gui")
