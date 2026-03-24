#!/bin/bash

# Better Boss Frames - Installation Script
# This script copies the addon to your WoW AddOns folder

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Better Boss Frames - Installation Script${NC}"
echo "========================================"
echo ""

# Detect WoW installation path
WOW_PATH="/Applications/World of Warcraft/_retail_/Interface/AddOns"
SOURCE_PATH="/Users/yuripiratello/projects/personal/better-boss-frames"
ADDON_NAME="BetterBossFrames"

# Check if WoW path exists
if [ ! -d "$WOW_PATH" ]; then
    echo -e "${RED}Error: WoW AddOns folder not found at:${NC}"
    echo "$WOW_PATH"
    echo ""
    echo "Please verify your WoW installation path and update this script."
    exit 1
fi

# Check if source path exists
if [ ! -d "$SOURCE_PATH" ]; then
    echo -e "${RED}Error: Source folder not found at:${NC}"
    echo "$SOURCE_PATH"
    exit 1
fi

# Check if source has required files
if [ ! -f "$SOURCE_PATH/BetterBossFrames.toc" ]; then
    echo -e "${RED}Error: BetterBossFrames.toc not found in source folder${NC}"
    echo "Make sure you're running this from the correct directory."
    exit 1
fi

# Remove old installation if it exists
if [ -d "$WOW_PATH/$ADDON_NAME" ]; then
    echo -e "${YELLOW}Removing old installation...${NC}"
    rm -rf "$WOW_PATH/$ADDON_NAME"
fi

# Copy addon to WoW
echo -e "${GREEN}Installing Better Boss Frames...${NC}"
cp -r "$SOURCE_PATH" "$WOW_PATH/$ADDON_NAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Installation successful!${NC}"
    echo ""
    echo "Addon installed to:"
    echo "$WOW_PATH/$ADDON_NAME"
    echo ""

    # Verify key files
    echo "Verifying installation..."

    if [ -f "$WOW_PATH/$ADDON_NAME/BetterBossFrames.toc" ]; then
        echo -e "${GREEN}✓${NC} BetterBossFrames.toc"
    else
        echo -e "${RED}✗${NC} BetterBossFrames.toc missing!"
    fi

    if [ -f "$WOW_PATH/$ADDON_NAME/Core.lua" ]; then
        echo -e "${GREEN}✓${NC} Core.lua"
    else
        echo -e "${RED}✗${NC} Core.lua missing!"
    fi

    if [ -f "$WOW_PATH/$ADDON_NAME/BossFrames.lua" ]; then
        echo -e "${GREEN}✓${NC} BossFrames.lua"
    else
        echo -e "${RED}✗${NC} BossFrames.lua missing!"
    fi

    if [ -d "$WOW_PATH/$ADDON_NAME/libs/LibEditMode" ]; then
        echo -e "${GREEN}✓${NC} LibEditMode library"
    else
        echo -e "${RED}✗${NC} LibEditMode library missing!"
    fi

    if [ -d "$WOW_PATH/$ADDON_NAME/libs/LibEditMode/widgets" ]; then
        WIDGET_COUNT=$(ls -1 "$WOW_PATH/$ADDON_NAME/libs/LibEditMode/widgets" | wc -l | tr -d ' ')
        echo -e "${GREEN}✓${NC} LibEditMode widgets ($WIDGET_COUNT files)"
    else
        echo -e "${RED}✗${NC} LibEditMode widgets missing!"
    fi

    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Launch World of Warcraft"
    echo "2. At character selection, click 'AddOns'"
    echo "3. Enable 'Better Boss Frames'"
    echo "4. Enter game and type: /bbf help"
    echo "5. Type /editmode to test the addon"
    echo ""

else
    echo -e "${RED}✗ Installation failed!${NC}"
    echo "Please check permissions and try again."
    exit 1
fi
