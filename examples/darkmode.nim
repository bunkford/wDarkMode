## Example demonstrating standalone dark mode module usage.
## This shows how to use wDarkModeStandalone.nim without modifying wNim core files.

import wNim
import wDarkMode

let app = App(wSystemDpiAware)

# Enable dark mode support
enableDarkMode(app)

let frame = Frame(title="Standalone Dark Mode Demo", size=(600, 500))

# Create a panel for controls
let panel = Panel(frame, style=wBorderSunken)

# Header text
let headerText = StaticText(panel, 
  label="Standalone Dark Mode Module Demo",
  pos=(20, 10))

# Description
let descText1 = StaticText(panel, 
  label="This uses the standalone wDarkModeStandalone.nim module.",
  pos=(20, 35))
let descText2 = StaticText(panel, 
  label="No modifications to wNim core files required!",
  pos=(20, 55))

# Buttons section
let buttonLabel = StaticText(panel, label="Buttons:", pos=(20, 85))
let button1 = Button(panel, label="Standard Button", pos=(20, 105), size=(150, 30))
let button2 = Button(panel, label="Another Button", pos=(180, 105), size=(150, 30))

# Checkbox section
let checkLabel = StaticText(panel, label="Checkboxes:", pos=(20, 150))
let checkbox1 = CheckBox(panel, label="Option 1", pos=(20, 170))
let checkbox2 = CheckBox(panel, label="Option 2", pos=(20, 195))
let checkbox3 = CheckBox(panel, label="Option 3 (checked)", pos=(20, 220))
checkbox3.value = true

# Radio buttons section
let radioLabel = StaticText(panel, label="Radio Buttons:", pos=(180, 150))
let radio1 = RadioButton(panel, label="Choice A", pos=(180, 170))
let radio2 = RadioButton(panel, label="Choice B", pos=(180, 195))
let radio3 = RadioButton(panel, label="Choice C", pos=(180, 220))
radio1.value = true

# Text input section
let textLabel = StaticText(panel, label="Text Input:", pos=(20, 255))
let textCtrl = TextCtrl(panel, value="Type here...", 
  pos=(20, 275), size=(310, 25), style=wBorderSunken)

# ComboBox section
let comboLabel = StaticText(panel, label="Dropdown:", pos=(20, 315))
let comboBox = ComboBox(panel, value="Item 1",
  choices=["Item 1", "Item 2", "Item 3", "Item 4"],
  pos=(20, 335), size=(150, 25), style=wCbReadOnly)

# ListBox section
let listLabel = StaticText(panel, label="List Box:", pos=(180, 315))
let listBox = ListBox(panel, 
  choices=["Entry 1", "Entry 2", "Entry 3", "Entry 4", "Entry 5"],
  pos=(180, 335), size=(150, 80), style=wBorderSunken)

# Slider section
let sliderLabel = StaticText(panel, label="Slider:", pos=(350, 85))
let slider = Slider(panel, value=50, pos=(350, 105), size=(200, 30))

# Gauge section
let gaugeLabel = StaticText(panel, label="Progress Bar:", pos=(350, 150))
let gauge = Gauge(panel, value=70, pos=(350, 170), size=(200, 25))

# Toggle button for dark mode
let toggleButton = Button(panel, label="Toggle Dark/Light Mode", 
  pos=(20, 425), size=(200, 35))

# Status information
let statusText = StaticText(panel, label="", pos=(230, 430))

# Track manual mode override for demonstration
var manualDarkMode = isDarkModeEnabled()

proc updateStatus() =
  if isDarkModeSupported():
    statusText.label = "Current Mode: " & (if manualDarkMode: "Dark" else: "Light")
  else:
    statusText.label = "Dark mode not supported"

# Toggle button handler
toggleButton.wEvent_Button do ():
  manualDarkMode = not manualDarkMode
  enableDarkModeForFrame(frame, manualDarkMode)
  updateStatus()
  echo "Toggled to: ", if manualDarkMode: "Dark Mode" else: "Light Mode"

# Button click events
button1.wEvent_Button do ():
  echo "Button 1 clicked"
  
button2.wEvent_Button do ():
  echo "Button 2 clicked"

# Slider event
slider.wEvent_Slider do ():
  gauge.value = slider.value

# Initialize status display
updateStatus()

# Apply dark mode to the frame and all its children
if isDarkModeEnabled():
  enableDarkModeForFrame(frame, true)

frame.center()
frame.show()
app.mainLoop()
