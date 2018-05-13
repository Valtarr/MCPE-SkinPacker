# MCPE-SkinPacker

## This is a PowerShell script to create MCPE skin pack from a folder.

Usage is simple. Just put all required skins (*.png) into some folder.
Name of the folder will be the name of the skin pack. Name of the PNG file will be the name of the skin.

Then just start **PowerShell** and run "**path_to_script\CreateSkinPack.ps1**" "**path_to_skins_directory**"

That's all - mcpack should be created near the script file.

If you want slim/girl skins - put your slim skins into the "**Slim**" subfolder (SkinsDir\Slim\*.png).

Only classical skins are supported (classical humanoid geometry).

As Minecraft doesn't support removing of SkinPacks you can remove them manually from the folder:  
**%LOCALAPPDATA%\Packages\Microsoft.MinecraftUWP_8wekyb3d8bbwe\LocalState\games\com.mojang\skin_packs**

*Why I have idea to do it? Just because MCPE doesn't give a possibility to select custom skin on Android TV.*