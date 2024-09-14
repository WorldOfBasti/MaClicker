# MaClicker
MaClicker is a simple auto clicker for your Mac. It was built with swift and requires macOS 10.13 High Sierra or higher. It is possible to achieve up to 100 clicks per second.
<br>
![](images/program.png)
<br>
Two languages are currently supported:
- English
- German

## Usage

### Installation
Download the .dmg file [of the release page](https://github.com/WorldOfBasti/MaClicker/releases), open it and copy the .app file to your applications folder. Open it, it should pop up in your menubar. Don't forget to add MaClicker to the accessibility permissions in the System Preferences: <br>
System Preferences -> Security & Privacy -> Privacy -> Accessibility

### Select mode
Currently, you can choose between three modes:
- Toggle <br>
This mode enables or disables the auto clicker when the activation key is pressed.
- Hold <br>
This mode enables the auto clicker while the activation key is held.
- Lock <br>
This mode simply holds the selected mouse button (enable/disable with activation key).

### Select activation key
You need to select an activation key to use the auto clicker.

### Select mouse button
Currently, you can choose between two mouse buttons to use:
- Left mouse button
- Right mouse button <br>

### Select clicks per second (click speed)
You can select how many clicks per second should be pressed.

### Select click limit
You can enable and set a click limit. The auto clicker stops when the limit got reached.

## Building
If you want to build MaClicker from source, follow these steps:
- Download the source code
- Open the project with xCode
- Build the project

## Acknowledgements
- The [Sauce project](https://github.com/Clipy/Sauce), it helps me using keyCodes with different keyboard layouts.
- The [Sparkle project](https://sparkle-project.org), for the update process

## Want to support this project?
The best way to support this project is to create issues and sending pull requests. Alternatively, you can translate the program to [other languages](https://github.com/WorldOfBasti/MaClicker/blob/master/src/MaClicker/en.lproj/Main.storyboard).