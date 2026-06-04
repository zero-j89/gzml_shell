import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Widgets

// GZML Shell lockscreen header
// Top-left transparent layout. Keeps settings-driven avatar/name/date/time.
Item {
  id: root

  readonly property bool animationsEnabled: Settings.data.general.lockScreenAnimations || false
  property date currentTime: new Date()
  property date currentDate: new Date()

  width: 420
  height: 145
  anchors.left: parent.left
  anchors.top: parent.top
  anchors.leftMargin: 34
  anchors.topMargin: 28

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.currentTime = new Date()
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: root.currentDate = new Date()
  }

  // Soft readable shadow/glass behind text, not a full solid card.
  Rectangle {
    anchors.fill: parent
    radius: Style.radiusL
    color: "transparent"
    border.color: Qt.alpha(Color.mPrimary, 0.25)
    border.width: 0
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 14

    Rectangle {
      Layout.preferredWidth: 52
      Layout.preferredHeight: 52
      Layout.alignment: Qt.AlignTop
      radius: width / 2
      color: Qt.alpha(Color.mSurface, 0.12)
      border.color: Qt.alpha(Color.mPrimary, 0.85)
      border.width: 2

      SequentialAnimation on border.color {
        loops: Animation.Infinite
        running: root.animationsEnabled
        ColorAnimation { to: Qt.alpha(Color.mPrimary, 1.0); duration: 1800; easing.type: Easing.InOutQuad }
        ColorAnimation { to: Qt.alpha(Color.mPrimary, 0.55); duration: 1800; easing.type: Easing.InOutQuad }
      }

      NImageRounded {
        anchors.centerIn: parent
        width: 46
        height: 46
        radius: width / 2
        imagePath: Settings.preprocessPath(Settings.data.general.avatarImage)
        fallbackIcon: "person"
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignTop
      spacing: 2

      NText {
        text: "GZML Shell"
        pointSize: Style.fontSizeS
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
        horizontalAlignment: Text.AlignLeft
      }

      NText {
        text: "Welcome back, " + HostService.displayName
        pointSize: Style.fontSizeS
        color: Color.mOnSurface
        horizontalAlignment: Text.AlignLeft
      }

      NText {
        text: {
          var dateString = I18n.locale.toString(root.currentDate, I18n.dateFormat());
          return dateString.charAt(0).toUpperCase() + dateString.slice(1);
        }
        pointSize: Style.fontSizeXS
        color: Qt.alpha(Color.mOnSurface, 0.78)
        horizontalAlignment: Text.AlignLeft
      }

      Item { Layout.preferredHeight: 4 }

      NText {
        text: I18n.locale.toString(root.currentTime, Settings.data.general.clockFormat || "hh:mm")
        pointSize: 30
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
        horizontalAlignment: Text.AlignLeft
      }
    }
  }
}
