# WristForce Wear OS Application

A Wear OS companion app for smartwatch users featuring voice commands, meeting management, and approvals.


## Features

- Voice command integration (Speak/Read)
- Meeting schedule display
- approvals screen
- real time clock display

## Prerequisites

- Android Studio Meerkat 
- Android SDK 35
- Minimun SDK -31
- Wear OS 4.0+ emulator or physical device

## Setup & Installation

1. Clone Repository
```bash
git clone https://github.com/your-username/wristforce-wear.git
cd wristforce-wear

2. Open in Android Studio
Launch Android Studio
Select "Open" and choose the project directory
Wait for Gradle sync to complete

3. Configure Emulator

Open AVD Manager (Tools > Device Manager)
Create new Wear OS virtual device:
Category: Wear
Template: Wear OS Square
System Image: Wear OS 4.0 (API 33)
Category: mobile
template: Medium phone API 35 | x86_64 the phone emulator must have google play service


Configure orientation and features

4. Build & Run
Select build variant (Debug/Release)

Choose Wear OS emulator or connected device

Emulator mobile device connection:
Step 1: Start Both Emulators
Launch the phone emulator first.
Launch the Wear OS emulator second.

Step 2: Pair via Extended Controls
On the phone emulator toolbar, click the ⋮ (three dots) to open extended controls.
Go to Wear OS tab > Pair Wear OS device.



Build Output: app-debug.apk (Wear OS)
Physical Device Setup
Enable Developer Options:

Settings > System > About > Tap build number 7 times

Enable ADB Debugging:

Settings > Developer options > ADB debugging

