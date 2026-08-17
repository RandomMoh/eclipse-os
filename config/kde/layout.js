var topPanel = new Panel
topPanel.location = "top"
topPanel.height = 2 * Math.floor(gridUnit * 2.5 / 2)

var kickoff = topPanel.addWidget("org.kde.plasma.kickoff")
kickoff.currentConfigGroup = ["Shortcuts"]
kickoff.writeConfig("global", "Alt+F1")

topPanel.addWidget("org.kde.plasma.marginsseparator")
topPanel.addWidget("org.kde.plasma.systemtray")
topPanel.addWidget("org.kde.plasma.digitalclock")

var bottomPanel = new Panel
bottomPanel.location = "bottom"
bottomPanel.height = 2 * Math.floor(gridUnit * 3.5 / 2)
bottomPanel.alignment = "center"

var icontasks = bottomPanel.addWidget("org.kde.plasma.icontasks")
icontasks.currentConfigGroup = ["General"]
icontasks.writeConfig("launchers", [
    "applications:zen-browser.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.kate.desktop",
    "applications:code.desktop",
    "applications:eclipse-sysinfo.desktop",
    "applications:eclipse-installer.desktop",
    "applications:eclipse-drivers.desktop"
])

bottomPanel.addWidget("org.kde.plasma.showdesktop")
