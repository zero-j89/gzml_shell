import qs.Commons
import qs.Widgets
import QtQuick

Rectangle {
  id: loadingBar

  property bool loading: pending > 0
  required property int pending
  property real progress: total > 0 ? 1 - (pending / total) : 0
  required property int total

  color: Qt.alpha(Color.mSurface, 0.9)
  height: upperRow.height + Style.margin2S + progressBar.height
  radius: Style.radiusXS
  visible: loading
  width: upperRow.width + Style.margin2L

  Behavior on opacity {
    NumberAnimation {
      duration: 300
      easing.type: Easing.OutCubic
    }
  }

  Row {
    id: upperRow

    anchors.centerIn: parent
    anchors.verticalCenterOffset: -progressBar.height / 2

    Item {
      anchors.verticalCenter: parent.verticalCenter

      Repeater {
        model: 3

        Rectangle {
          property real angle: index * (2 * Math.PI / 3)

          color: Color.mPrimary
          height: Style.marginXS
          radius: Style.marginXXS
          width: Style.marginXS
          x: Style.marginS + Style.marginS * Math.cos(angle + spinAnimation.value)
          y: Style.marginS + Style.marginS * Math.sin(angle + spinAnimation.value)

          NumberAnimation on opacity {
            duration: 600
            from: 0.3
            loops: Animation.Infinite
            running: loadingBar.loading
            to: 1
          }
        }
      }
      NumberAnimation {
        id: spinAnimation

        property real value: 0

        duration: 1200
        from: 0
        loops: Animation.Infinite
        property: "value"
        running: loadingBar.loading
        target: spinAnimation
        to: 2 * Math.PI
      }
    }

    NText {
      text: `${root.pluginApi?.tr("widget.generate-thumbs-message")} ${String(Math.max(loadingBar.total - loadingBar.pending, 0)).padStart(String(loadingBar.total).length, " ")} / ${loadingBar.total}`
    }
  }

  Rectangle {
    id: progressBar

    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    color: Qt.alpha(Color.mOnSurface, 0.1)
    height: Style.marginS
    radius: loadingBar.radius

    Rectangle {
      color: Color.mPrimary
      height: parent.height
      radius: parent.radius
      width: parent.width * loadingBar.progress

      Behavior on width {
        NumberAnimation {
          duration: 200
          easing.type: Easing.OutCubic
        }
      }
    }
  }
}
