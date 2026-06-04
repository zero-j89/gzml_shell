import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
    spacing: Style.marginL
    anchors.margins: Style.marginL

    Process {
        id: runner
    }

    NText {
        text: "Ground ZeR0 ML"
        font.pointSize: 28
        color: Color.mPrimary
    }

    Image {
        source: "file:///home/zer0/Downloads/GZML.png"

        Layout.preferredWidth: 460 * Style.uiScaleRatio
        Layout.preferredHeight: 460 * Style.uiScaleRatio
        Layout.alignment: Qt.AlignHCenter

        width: 460 * Style.uiScaleRatio
        height: 460 * Style.uiScaleRatio

        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
    }

    // =========================
    // VISUALS
    // =========================

    NText {
        text: "VISUALS"
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
    }

    NButton {
        text: "Wallpaper Effects"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/UserScripts/WallpaperEffects.sh"]
            runner.running = true
        }
    }

    NButton {
        text: "Animations"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/scripts/Animations.sh"]
            runner.running = true
        }
    }

    NButton {
        text: "Blur"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/scripts/ChangeBlur.sh"]
            runner.running = true
        }
    }

    NButton {
        text: "SDDM Wallpaper"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/scripts/sddm_wallpaper.sh"]
            runner.running = true
        }
    }
   
    // =========================
    // THEMES
    // =========================

    NText {
        text: "THEMES"
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
    }

    NButton {
        text: "Rofi Themes"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/scripts/RofiThemeSelector.sh"]
            runner.running = true
        }
    }

    NButton {
        text: "Kitty Themes"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/scripts/Kitty_themes.sh"]
            runner.running = true
        }
    }

    NButton {
        text: "ZSH Theme"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/UserScripts/ZshChangeTheme.sh"]
            runner.running = true
        }
    }

    // =========================
    // TOOLS
    // =========================

    NText {
        text: "TOOLS"
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
    }

    NButton {
    text: "Keybind Search"

    onClicked: {
        runner.command = ["bash", "-lc", "~/.config/hypr/scripts/KeyBinds.sh"]
        runner.running = true
        }
    }

    NButton {
        text: "Keyboard Hints"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/scripts/KeyHints.sh"]
            runner.running = true
        }
    }

    NButton {
        text: "Drop Terminal"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/scripts/Dropterminal.sh"]
            runner.running = true
        }
    }

    NButton {
        text: "Rofi Calculator"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/UserScripts/RofiCalc.sh"]
            runner.running = true
        }
    }

    NButton {
        text: "Google Search"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/scripts/RofiSearch.sh"]
            runner.running = true
        }
    }

    // =========================
    // GZML
    // =========================

    NText {
        text: "GZML"
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
    }

    NButton {
        text: "Sync Custom Buttons Across Profiles"

        onClicked: {
            runner.command = ["bash", "-lc", "~/.config/hypr/UserScripts/SyncGZMLButtons.sh"]
            runner.running = true
        }
    }
      NButton {
        text: "GZML-Shell Quick settings"

        onClicked: {

            runner.command = ["bash", "-lc", "~/.config/hypr/scripts/gzml_quick_settings.sh"]
            runner.running = true
        }
}

}
