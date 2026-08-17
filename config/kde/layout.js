// Eclipse OS Two-Panel Layout: Top Status Bar + Bottom Taskbar/Dock

// 1. TOP STATUS BAR (Clock, System Tray, Menu)
var topPanel = new Panel("org.kde.plasma.panel");
topPanel.location = "top";
topPanel.height = 32;

var kickoff = topPanel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["Shortcuts"];
kickoff.writeConfig("global", "Alt+F1");

topPanel.addWidget("org.kde.plasma.marginsseparator");
topPanel.addWidget("org.kde.plasma.systemtray");
topPanel.addWidget("org.kde.plasma.digitalclock");

// 2. BOTTOM DOCK / TASKBAR (Pinned Apps + Running Windows)
var bottomPanel = new Panel("org.kde.plasma.panel");
bottomPanel.location = "bottom";
bottomPanel.height = 48;
bottomPanel.alignment = "center";

var icontasks = bottomPanel.addWidget("org.kde.plasma.icontasks");
icontasks.currentConfigGroup = ["General"];
icontasks.writeConfig("launchers", [
    "applications:zen-browser.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.kate.desktop",
    "applications:code.desktop",
    "applications:eclipse-sysinfo.desktop",
    "applications:eclipse-installer.desktop",
    "applications:eclipse-drivers.desktop"
]);

bottomPanel.addWidget("org.kde.plasma.showdesktop");

// 3. DESKTOP WALLPAPER CONFIGURATION
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
    desktopsArray[j].currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
    desktopsArray[j].writeConfig('Image', 'file:///usr/share/backgrounds/eclipse/eclipse-wallpaper.png');
}
