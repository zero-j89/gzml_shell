import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

ColumnLayout {
    id: root
    spacing: Style.marginL
    anchors.margins: Style.marginL

    property string activeEffect: "Disable"
    property string originalWallpaper: ""
    property string pendingOutput: ""
    property string pendingScreen: ""

    readonly property string effectsDir: Quickshell.shellDir + "/Assets/wallpaper-effects"
    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/gzml/wallpaper-effects"

    function currentScreenName() {
        if (Quickshell.screens.length > 0)
            return Quickshell.screens[0].name
        return ""
    }

    function niceName(fileName) {
        return fileName.replace(".sh", "").replace(/([a-z])([A-Z])/g, "$1 $2")
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function isEffectPath(path) {
        return path && path.indexOf(cacheDir + "/") === 0
    }

    function activeFromPath(path, screenName) {
        if (!isEffectPath(path))
            return "Disable"

        var base = path.split("/").pop().replace(".png", "")
        var prefix = screenName + "_"

        if (base.indexOf(prefix) === 0)
            return base.substring(prefix.length)

        return "Disable"
    }

    function stateOriginalFile(screenName) {
        return cacheDir + "/" + screenName + ".original"
    }

    function stateActiveFile(screenName) {
        return cacheDir + "/" + screenName + ".active"
    }

    function defaultWallpaper() {
        return Quickshell.shellDir + "/Assets/Wallpaper/gzml-shell.png"
    }

    function syncEffectState() {
        var screenName = currentScreenName()
        if (screenName === "")
            return

        var current = WallpaperService.getWallpaper(screenName)

        if (!isEffectPath(current)) {
            originalWallpaper = current || ""
            activeEffect = "Disable"
            return
        }

        activeEffect = activeFromPath(current, screenName)

        stateReader.command = [
            "bash",
            "-lc",
            "cat " + shellQuote(stateOriginalFile(screenName)) + " 2>/dev/null || true"
        ]
        stateReader.running = true
    }

    function applyEffect(fileName) {
        var screenName = currentScreenName()
        if (screenName === "")
            return

        var current = WallpaperService.getWallpaper(screenName)

        if (fileName === "Disable.sh") {
            var restore = originalWallpaper

            if (!restore || restore === "" || isEffectPath(restore))
                restore = defaultWallpaper()

            WallpaperService.changeWallpaper(restore, screenName)

            originalWallpaper = restore
            activeEffect = "Disable"
            pendingOutput = ""
            pendingScreen = ""

            stateWriter.command = [
                "bash",
                "-lc",
                "mkdir -p " + shellQuote(cacheDir) +
                " && rm -f " + shellQuote(stateActiveFile(screenName)) +
                " && printf '%s\n' " + shellQuote(restore) + " > " + shellQuote(stateOriginalFile(screenName))
            ]
            stateWriter.running = true
            return
        }

        if (!current || current === "")
            current = defaultWallpaper()

        // Only update the original source when the current wallpaper is a real wallpaper.
        // If the current wallpaper is already an effect cache file, keep using the saved original.
        if (!isEffectPath(current))
            originalWallpaper = current

        if (!originalWallpaper || originalWallpaper === "" || isEffectPath(originalWallpaper))
            originalWallpaper = defaultWallpaper()

        var effectName = fileName.replace(".sh", "")
        var output = cacheDir + "/" + screenName + "_" + effectName + ".png"

        pendingOutput = output
        pendingScreen = screenName

        runner.command = [
            "bash",
            "-lc",
            "mkdir -p " + shellQuote(cacheDir) +
            " && printf '%s\n' " + shellQuote(originalWallpaper) + " > " + shellQuote(stateOriginalFile(screenName)) +
            " && printf '%s\n' " + shellQuote(effectName) + " > " + shellQuote(stateActiveFile(screenName)) +
            " && " + shellQuote(effectsDir + "/" + fileName) + " " + shellQuote(originalWallpaper) + " " + shellQuote(output)
        ]
        runner.running = true
        activeEffect = effectName
    }

    function syncButtons() {
        buttonSyncRunner.command = ["bash", "-lc", shellQuote(Quickshell.shellDir + "/Assets/ButtonSync/ButtonSync.sh")]
        buttonSyncRunner.running = true
    }

    Component.onCompleted: syncEffectState()

    Process {
        id: stateReader

        stdout: StdioCollector {
            onStreamFinished: {
                var saved = this.text.trim()
                if (saved !== "" && !root.isEffectPath(saved))
                    root.originalWallpaper = saved
                else if (root.originalWallpaper === "")
                    root.originalWallpaper = root.defaultWallpaper()
            }
        }
    }

    Process {
        id: stateWriter
    }

    Process {
        id: buttonSyncRunner
    }

    Process {
        id: runner

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && pendingOutput !== "" && pendingScreen !== "") {
                WallpaperService.changeWallpaper(pendingOutput, pendingScreen)
            }

            pendingOutput = ""
            pendingScreen = ""
        }
    }

    NText {
        text: "GZML Shell"
        font.pointSize: 28
        color: Color.mPrimary
    }

    Image {
        source: "../../../../../Assets/gzml-small.png"
        Layout.preferredWidth: 220 * Style.uiScaleRatio
        Layout.preferredHeight: 220 * Style.uiScaleRatio
        Layout.alignment: Qt.AlignHCenter
        fillMode: Image.PreserveAspectFit
    }

    Rectangle {
        Layout.fillWidth: true
        radius: Style.radiusL
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: 1
        implicitHeight: effectsColumn.implicitHeight + Style.margin2L

        ColumnLayout {
            id: effectsColumn
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NText {
                text: "Wallpaper Effects"
                font.pointSize: 18
                font.weight: Font.Bold
                color: Color.mPrimary
            }

            NText {
                Layout.fillWidth: true
                text: "Apply ImageMagick effects to the current GZML wallpaper. Disable restores the original wallpaper for this session."
                wrapMode: Text.WordWrap
                color: Color.mOnSurfaceVariant
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Style.marginM
                rowSpacing: Style.marginM

                Repeater {
                    model: [
                        "Disable.sh",
                        "BlackAndWhite.sh",
                        "Charcoal.sh",
                        "EdgeDetect.sh",
                        "Emboss.sh",
                        "FrameRaised.sh",
                        "FrameSunk.sh",
                        "Negate.sh",
                        "OilPaint.sh",
                        "Polaroid.sh",
                        "Posterize.sh",
                        "Sepia.sh",
                        "Sharpen.sh",
                        "Solarize.sh",
                        "Vignette.sh",
                        "VignetteBlack.sh",
                        "Zoomed.sh"
                    ]

                    NButton {
                        Layout.fillWidth: true
                        text: root.niceName(modelData)
                        outlined: root.activeEffect !== modelData.replace(".sh", "")
                        onClicked: root.applyEffect(modelData)
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        radius: Style.radiusL
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: 1
        implicitHeight: profileColumn.implicitHeight + Style.margin2L

        ColumnLayout {
            id: profileColumn
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NText {
                text: "Profiles"
                font.pointSize: 18
                font.weight: Font.Bold
                color: Color.mPrimary
            }

            NButton {
                Layout.fillWidth: true
                text: "Sync Cards/Widgets/Tray Icons Across Profiles"
                onClicked: root.syncButtons()
            }
        }
    }
}
