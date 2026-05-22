import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    spacing: Style.marginL
    anchors.margins: Style.marginL

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
}
