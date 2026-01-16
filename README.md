# Volume Mixer plugin for DMS

A plugin that allows you to control the volume of your system and applications.

<img width="505" height="661" alt="image" src="./assets/screenshot.png" />

## Features
* **System Volume Control:** Adjust the default main output volume
* **Notifications Volume Control:** Adjust the volume for system notifications 
* **Per-Application Mixing:** Independently control the volume level for every running application

## Installation

```bash
mkdir -p ~/.config/DankMaterialShell/plugins/
cd ~/.config/DankMaterialShell/plugins/
git clone https://github.com/EDUnter/dms-volume-mixer 
```

## Usage
1. Open DMS Settings
2. Go to the "Plugins" tab
3. Click on Scan
4. Enable the "Volume Mixer" plugin
5. Go to the "Widgets" tab
6. Add the "Volume Mixer" widget to your DankBar
7. Open the "Volume Mixer" widget to adjust the volume levels for your system and applications

## Known limitations
Brief, annoying audio spikes when the volume is changed directly within the application. The spikes are more noticeable when the volume factor is configured to a significantly low value.

> **What is the Volume Factor?**
> The **volume factor** is a multiplier applied to the audio stream's current volume, **directly corresponding to the value displayed on the widget's slider.**
