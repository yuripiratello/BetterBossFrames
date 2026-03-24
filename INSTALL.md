# Installation Guide

This guide provides detailed instructions for installing Better Boss Frames in World of Warcraft: Midnight.

## Prerequisites

- World of Warcraft: Midnight (version 12.0.0 or higher)
- Basic knowledge of WoW AddOns location

## Finding Your AddOns Folder

### Windows

1. Open File Explorer
2. Navigate to: `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\`
   - If you installed WoW to a different location, adjust the path accordingly
3. If the `AddOns` folder doesn't exist, create it

### macOS

1. Open Finder
2. Navigate to: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
   - You can use `Cmd + Shift + G` and paste the path to navigate quickly
3. If the `AddOns` folder doesn't exist, create it

## Installation Methods

### Method 1: Download Release Package (Recommended)

1. Download the latest release package (BetterBossFrames-v1.0.0.zip)
2. Extract the ZIP file
3. Copy the entire `BetterBossFrames` folder to your AddOns directory
4. The final path should look like:
   - Windows: `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\BetterBossFrames\`
   - macOS: `/Applications/World of Warcraft/_retail_/Interface/AddOns/BetterBossFrames/`

### Method 2: Clone from Repository

If you're cloning from a Git repository:

```bash
cd "/path/to/World of Warcraft/_retail_/Interface/AddOns/"
git clone <repository-url> BetterBossFrames
```

## Verifying Installation

After installation, your `BetterBossFrames` folder should contain:

```
BetterBossFrames/
├── BetterBossFrames.toc
├── Core.lua
├── BossFrames.lua
├── README.md
├── LICENSE
└── libs/
    ├── LibStub/
    │   └── LibStub.lua
    └── LibEditMode/
        ├── LibEditMode.lua
        ├── namespaced.lua
        ├── embed.xml
        ├── pools.lua
        └── widgets/
            ├── button.lua
            ├── checkbox.lua
            ├── colorpicker.lua
            ├── dialog.lua
            ├── divider.lua
            ├── dropdown.lua
            ├── expander.lua
            ├── extension.lua
            └── slider.lua
```

## Activating the AddOn

1. Launch World of Warcraft
2. At the character selection screen, click "AddOns" in the lower-left corner
3. Find "Better Boss Frames" in the list
4. Ensure the checkbox next to it is checked
5. Click "Okay"
6. Enter the game with your character

## First Time Setup

1. Once in-game, you should see a message: "Better Boss Frames loaded! Use Edit Mode to customize."
2. Open Edit Mode by pressing `ESC` → Edit Mode, or type `/editmode`
3. Look for "Better Boss Frames" - it will appear as a labeled container in Edit Mode
4. Click on it to select it, then:
   - Drag to reposition
   - Click the settings icon to customize options
5. Click "Save and Exit" when done

## Troubleshooting Installation

### AddOn Not Appearing in AddOns List

- **Check folder name**: Must be exactly `BetterBossFrames` (case-sensitive on some systems)
- **Check folder location**: Must be in `_retail_\Interface\AddOns\`, not in `_classic_` or other versions
- **Verify .toc file**: The `BetterBossFrames.toc` file must be present in the root of the folder

### "Interface action failed" or Lua errors

- **Verify all files are present**: Check the file structure above
- **Ensure libraries are complete**: All files in `libs/LibEditMode/widgets/` must be present
- **Check file permissions**: Ensure all files are readable

### AddOn Loads but Nothing Appears

- **Boss frames only appear when fighting bosses**: Test in a dungeon or raid
- **Check if Edit Mode is working**: Type `/editmode` to open Edit Mode
- **Reload UI**: Type `/reload` to reload the interface

### SavedVariables Not Saving

- **Check file permissions**: WoW needs write access to its folders
- **Windows UAC**: Run WoW as administrator if needed
- **macOS permissions**: Grant WoW full disk access in System Preferences → Security & Privacy

## Updating the AddOn

To update to a newer version:

1. Delete the old `BetterBossFrames` folder from your AddOns directory
2. Install the new version following the installation methods above
3. Your settings should be preserved (stored in `SavedVariables`)

## Uninstalling

To completely remove Better Boss Frames:

1. Delete the `BetterBossFrames` folder from your AddOns directory
2. (Optional) Delete saved settings:
   - Windows: `C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\SavedVariables\BetterBossFrames.lua`
   - macOS: `/Applications/World of Warcraft/_retail_/WTF/Account/<ACCOUNT>/SavedVariables/BetterBossFrames.lua`

## Getting Help

If you continue to experience issues:

1. Check the README.md for troubleshooting tips
2. Enable Lua errors: `/console scriptErrors 1`
3. Try to reproduce the issue and note any error messages
4. Report issues on the GitHub repository with:
   - Your WoW version
   - Addon version
   - Any error messages
   - Steps to reproduce the issue
