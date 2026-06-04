import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
    spacing: Style.marginL
    anchors.margins: Style.marginL

    function runCmd(cmd) {
        runner.command = ["bash", "-lc", cmd]
        runner.running = true
    }

    Process {
        id: runner
    }

    NText {
        text: "GZML"
        font.pointSize: 24
        color: Color.mPrimary
    }

    Image {
        source: "file:////home/zer0/.config/noctalia/plugins/hyprland-visual-editor/assets/owl_neon.png"
        Layout.preferredWidth: 400
        Layout.preferredHeight: 300
        fillMode: Image.PreserveAspectFit
    }

    NText {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Just Testing My Programming and Injection Skills.."
        color: Color.mOnSurface
    }

    Rectangle {
        Layout.fillWidth: true
        radius: Style.radiusL
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NText {
                text: "GZML Visual Tools"
                font.pointSize: 16
                color: Color.mPrimary
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Style.marginM
                rowSpacing: Style.marginM

                NButton {
                    Layout.fillWidth: true
                    text: "Wallpaper Effects"
                    onClicked: runCmd("bash ~/.config/hypr/UserScripts/WallpaperEffects.sh")
                }

                NButton {
                    Layout.fillWidth: true
                    text: "Animations"
                    onClicked: runCmd("bash ~/.config/hypr/scripts/Animations.sh")
                }

                NButton {
                    Layout.fillWidth: true
                    text: "Kitty Themes"
                    onClicked: runCmd("bash ~/.config/hypr/scripts/Kitty_themes.sh")
                }

                NButton {
                    Layout.fillWidth: true
                    text: "Rofi Themes"
                    onClicked: runCmd("bash ~/.config/hypr/scripts/RofiThemeSelector.sh")
                }

                NButton {
                    Layout.fillWidth: true
                    text: "Set SDDM Wallpaper"
                    onClicked: runCmd("bash ~/.config/hypr/scripts/sddm_wallpaper.sh --normal")
                }

                NButton {
                    Layout.fillWidth: true
                    text: "Sync GZML Buttons"
                    onClicked: runCmd("bash ~/.config/hypr/UserScripts/SyncGZMLButtons.sh")
                }

                NButton {
                    Layout.fillWidth: true
                    text: "Blur Toggle"
                    onClicked: runCmd("bash ~/.config/hypr/scripts/ChangeBlur.sh")
                }

                NButton {
                    Layout.fillWidth: true
                    text: "Monitor Profiles"
                    onClicked: runCmd("bash ~/.config/hypr/scripts/MonitorProfiles.sh")
                }
            }
        }
    }
}
