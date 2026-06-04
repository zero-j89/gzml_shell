import QtQuick
import qs.Commons
import qs.Widgets

Row {
  id: hint

  required property string keys
  required property string label

  spacing: Style.marginXS

  Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.marginXXS

    Repeater {
      model: hint.keys.split(" / ")

      Row {
        required property int index
        required property var modelData

        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginXXS

        // Separator between keys
        NText {
          anchors.verticalCenter: parent.verticalCenter
          color: Qt.alpha(Color.mOnSurface, 0.3)
          font.pointSize: Style.fontSizeXXS
          text: root.pluginApi?.tr("shortcuts.key-separator")
          visible: index > 0
        }

        // Keycap
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          border.color: Qt.alpha(Color.mOnSurface, 0.2)
          border.width: Style.borderS
          color: Qt.alpha(Color.mOnSurface, 0.08)
          height: Style.marginL + 2
          radius: Style.radiusXS
          width: Math.max(Style.marginL + 2, keycapText.width + Style.marginS)

          Rectangle {
            anchors.bottomMargin: 2
            anchors.fill: parent
            border.color: Qt.alpha(Color.mOnSurface, 0.15)
            border.width: Style.borderS
            color: Qt.alpha(Color.mOnSurface, 0.05)
            radius: Style.radiusXS

            NText {
              id: keycapText

              anchors.centerIn: parent
              color: Qt.alpha(Color.mOnSurface, 0.6)
              font.bold: true
              font.pointSize: Style.fontSizeXXS
              text: modelData.trim()
            }
          }
        }
      }
    }
  }

  NText {
    anchors.verticalCenter: parent.verticalCenter
    color: Qt.alpha(Color.mOnSurface, 0.4)
    font.pointSize: Style.fontSizeXXS
    text: hint.label
  }
}
