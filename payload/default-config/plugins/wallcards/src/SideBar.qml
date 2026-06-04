import QtQuick
import qs.Commons
import qs.Widgets

Rectangle {
  id: sideBar

  property bool expanded: false
  property bool hideHelp: true

  color: Qt.alpha(Color.mSurface, 0.9)
  radius: Style.radiusS
  width: expanded ? shortcutColumn.width + Style.margin2L : !hideHelp ? collapsedColumn.width + Style.margin2L : 0
  height: expanded ? shortcutColumn.height + Style.margin2L : !hideHelp ? collapsedColumn.height + Style.margin2L : 0

  Behavior on width {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutCubic
    }
  }
  Behavior on height {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutCubic
    }
  }

  clip: true

  Column {
    id: collapsedColumn

    anchors.centerIn: parent
    spacing: Style.marginS
    visible: !sideBar.expanded && !sideBar.hideHelp

    ShortcutHint {
      keys: "?"
      label: root.pluginApi?.tr("shortcuts.label.help-title")
    }
  }

  Column {
    id: shortcutColumn

    anchors.centerIn: parent
    spacing: Style.marginXS
    visible: sideBar.expanded

    // Navigation
    NText {
      color: Qt.alpha(Color.mOnSurface, 0.35)
      font.bold: true
      font.pointSize: Style.fontSizeXXS
      text: root.pluginApi?.tr("shortcuts.header.navigation")
    }
    ShortcutHint {
      keys: "J / K"
      label: root.pluginApi?.tr("shortcuts.label.navigate")
    }
    ShortcutHint {
      keys: "H / L"
      label: root.pluginApi?.tr("shortcuts.label.jump")
    }
    ShortcutHint {
      keys: "R"
      label: root.pluginApi?.tr("shortcuts.label.shuffle")
    }

    // Separator
    Rectangle {
      color: Qt.alpha(Color.mOnSurface, 0.1)
      height: 1
      width: shortcutColumn.width
    }

    // Actions
    NText {
      color: Qt.alpha(Color.mOnSurface, 0.35)
      font.bold: true
      font.pointSize: Style.fontSizeXXS
      text: root.pluginApi?.tr("shortcuts.header.actions")
    }
    ShortcutHint {
      keys: "ENTER"
      label: root.pluginApi?.tr("shortcuts.label.apply-quit")
    }
    ShortcutHint {
      keys: "SPACE"
      label: root.pluginApi?.tr("shortcuts.label.apply")
    }
    ShortcutHint {
      keys: "ESC / Q"
      label: root.pluginApi?.tr("shortcuts.label.quit")
    }

    // Separator
    Rectangle {
      color: Qt.alpha(Color.mOnSurface, 0.1)
      height: 1
      width: shortcutColumn.width
    }

    // Filters
    NText {
      color: Qt.alpha(Color.mOnSurface, 0.35)
      font.bold: true
      font.pointSize: Style.fontSizeXXS
      text: root.pluginApi?.tr("shortcuts.header.filters")
    }
    ShortcutHint {
      keys: "A"
      label: root.pluginApi?.tr("shortcuts.label.filter-all")
    }
    ShortcutHint {
      keys: "I"
      label: root.pluginApi?.tr("shortcuts.label.filter-images")
    }
    ShortcutHint {
      keys: "V"
      label: root.pluginApi?.tr("shortcuts.label.filter-videos")
    }
    ShortcutHint {
      keys: "F"
      label: root.pluginApi?.tr("shortcuts.label.filter-colors")
    }

    // Separator
    Rectangle {
      color: Qt.alpha(Color.mOnSurface, 0.1)
      height: 1
      width: shortcutColumn.width
    }

    // View
    NText {
      color: Qt.alpha(Color.mOnSurface, 0.35)
      font.bold: true
      font.pointSize: Style.fontSizeXXS
      text: root.pluginApi?.tr("shortcuts.header.view")
    }
    ShortcutHint {
      keys: "T"
      label: root.pluginApi?.tr("shortcuts.label.top-bar")
    }
    ShortcutHint {
      keys: "P"
      label: root.pluginApi?.tr("shortcuts.label.live-preview")
    }

    // Separator
    Rectangle {
      color: Qt.alpha(Color.mOnSurface, 0.1)
      height: 1
      width: shortcutColumn.width
    }

    // Layout
    NText {
      color: Qt.alpha(Color.mOnSurface, 0.35)
      font.bold: true
      font.pointSize: Style.fontSizeXXS
      text: root.pluginApi?.tr("shortcuts.header.layout")
    }
    ShortcutHint {
      keys: "SHIFT + H / L"
      label: root.pluginApi?.tr("shortcuts.label.center-height")
    }
    ShortcutHint {
      keys: "SHIFT + J / K"
      label: root.pluginApi?.tr("shortcuts.label.center-width")
    }
    ShortcutHint {
      keys: "SHIFT + N / P"
      label: root.pluginApi?.tr("shortcuts.label.cards-shown")
    }
    ShortcutHint {
      keys: "CTRL + J / K"
      label: root.pluginApi?.tr("shortcuts.label.cards-spacing")
    }
    ShortcutHint {
      keys: "CTRL + H / L"
      label: root.pluginApi?.tr("shortcuts.label.cards-width")
    }

    // Separator
    Rectangle {
      color: Qt.alpha(Color.mOnSurface, 0.1)
      height: 1
      width: shortcutColumn.width
    }

    ShortcutHint {
      keys: "CTRL + S"
      label: root.pluginApi?.tr("shortcuts.label.save")
    }
    ShortcutHint {
      keys: "?"
      label: root.pluginApi?.tr("shortcuts.label.hide")
    }
  }
}
