import QtQuick
import QtQuick.Controls
import Quickshell.Io

Button {
    text: "Naga"

    onClicked: nagaProc.running = true

    Process {
        id: nagaProc
        command: ["bash", "-lc", "/home/zer0/.config/hypr/scripts/naga_mode.sh"]
        running: false
    }
}
