---

# FiveM Recording Security Cameras

This **FiveM script** allows players to view and record security camera footage in real time. It’s designed to enhance **roleplay scenarios** such as police surveillance or property monitoring. The system enables **live monitoring**, **automatic recording**, and the ability to **replay** previously recorded footage.

## Features
- **Camera Viewing**: Players can switch between security cameras in specified locations.
- **Recording**: Cameras automatically record footage.
- **Playback**: Recorded footage can be replayed from the perspective of the cameras.
- **Configurable**: Camera positions, intervals, and other settings are easily customizable through the configuration files.

## Installation

1. **Download the Script**: Clone or download the repository:
   ```bash
   git clone https://github.com/Paviin/Fivem-Recording-Security-Cameras.git
   ```
2. **Move to Your Server Resources**: Place the folder in your server's `resources` directory.
3. **Configure Your `server.cfg`**: Add the following line to your `server.cfg`:
   ```bash
   start RecordingSecurityCameras
   ```
4. **Install MySQL**: The script uses **MySQL-Async** for storing camera and recording data. Ensure that your server has MySQL set up and properly configured.
5. **Customize Settings**: Open the configuration file and set camera positions, recording intervals, and permissions.

## Usage

### Camera System Features
The script provides several key features for handling security cameras:

- **Camera Playback**: Recorded videos can be replayed at any time, allowing players to review events.
- **View Cameras**: Switch between different cameras by navigating through the user interface.

### Configuration
In the `config.lua` file, you can modify the following settings:
- **Camera Positions**: Define the x, y, z coordinates and angles for each camera.
- **Permissions**: Control which players or jobs can view and manage cameras.
  
## Requirements
- **MySQL-Async**: The script relies on a MySQL database to store camera data and video recordings.
  
## Known Issues
- **Camera Positioning**: Some cameras might have limited visibility depending on their placement.
- **Performance**: Frequent recording or large numbers of cameras can potentially affect server performance.

## Future Updates
- **Dynamic Camera Placement**: Future versions may allow players to place cameras dynamically in-game.
- **Enhanced Playback Features**: Additional controls for rewinding and fast-forwarding video may be added.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---
