import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  NTabBar {
    id: subTabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    // YOUR PAGE
    NTabButton {
      text: "GZML"
      tabIndex: 0
      checked: subTabBar.currentIndex === 0
    }

    // FASTFETCH / INFO TAB
    NTabButton {
      text: I18n.tr("common.info")
      tabIndex: 1
      checked: subTabBar.currentIndex === 1
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Style.marginL
  }

  NTabView {
    id: tabView
    currentIndex: subTabBar.currentIndex

    // ===== YOUR CUSTOM PAGE =====
    ColumnLayout {
      spacing: Style.marginL
      anchors.margins: Style.marginL

      NText {
        text: "Ground ZeR0 ML"
        font.pointSize: 28
        color: Color.mPrimary
      }

     Image {
      source: "/home/zer0/Downloads/GZML.png"

      Layout.preferredWidth: 460 * Style.uiScaleRatio
      Layout.preferredHeight: 460 * Style.uiScaleRatio
      Layout.alignment: Qt.AlignHCenter

      width: 460 * Style.uiScaleRatio
      height: 460 * Style.uiScaleRatio

      sourceSize.width: width
      sourceSize.height: height
      fillMode: Image.PreserveAspectFit
 }
      NText {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Testing My Programming and Injection Skills...."
        color: Color.mOnSurface
      }
    }

    // ===== ORIGINAL SYSTEM INFO TAB =====
    VersionSubTab {}
  }
}
