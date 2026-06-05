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

    function applyEffect(fileName) {
        var screenName = currentScreenName()
        if (screenName === "")
            return

        if (fileName === "Disable.sh") {
            if (originalWallpaper !== "") {
                WallpaperService.changeWallpaper(originalWallpaper, screenName)
            }
            activeEffect = "Disable"
            return
        }

        var current = WallpaperService.getWallpaper(screenName)
        if (!current || current === "")
            return

        if (originalWallpaper === "" || current.indexOf(cacheDir) !== 0)
            originalWallpaper = current

        var effectName = fileName.replace(".sh", "")
        var output = cacheDir + "/" + screenName + "_" + effectName + ".png"

        pendingOutput = output
        pendingScreen = screenName

        runner.command = [
            "bash",
            "-lc",
            "mkdir -p '" + cacheDir + "' && '" + effectsDir + "/" + fileName + "' '" + originalWallpaper + "' '" + output + "'"
        ]
        runner.running = true
        activeEffect = effectName
    }

    function syncButtons() {
        runner.command = ["bash", "-lc", "'" + Quickshell.shellDir + "/Assets/ButtonSync/ButtonSync.sh'"]
        runner.running = true
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
                text: "Sync Custom Buttons Across Profiles"
                onClicked: root.syncButtons()
            }
        }
    }
}
