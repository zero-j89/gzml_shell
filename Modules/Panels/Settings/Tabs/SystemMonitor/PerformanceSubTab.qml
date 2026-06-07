import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  NToggle {
    Layout.fillWidth: true
    label: "Enable wallpapers in performance mode"
    description: "Hide wallpapers while Performance Mode is enabled."
    checked: !Settings.data.noctaliaPerformance.disableWallpaper
    defaultValue: !Settings.getDefaultValue("noctaliaPerformance.disableWallpaper")
    onToggled: checked => Settings.data.noctaliaPerformance.disableWallpaper = !checked
  }

  NToggle {
    Layout.fillWidth: true
    label: "Enable desktop widgets in performance mode"
    description: "Hide desktop widgets while Performance Mode is enabled."
    checked: !Settings.data.noctaliaPerformance.disableDesktopWidgets
    defaultValue: !Settings.getDefaultValue("noctaliaPerformance.disableDesktopWidgets")
    onToggled: checked => Settings.data.noctaliaPerformance.disableDesktopWidgets = !checked
  }
  NToggle {
    Layout.fillWidth: true
    label: "Enable audio visualizers in performance mode"
    description: "Hide audio spectrum/CAVA visualizers while Performance Mode is enabled."
    checked: !Settings.data.noctaliaPerformance.disableAudioVisualizers
    defaultValue: !Settings.getDefaultValue("noctaliaPerformance.disableAudioVisualizers")
    onToggled: checked => Settings.data.noctaliaPerformance.disableAudioVisualizers = !checked
  }

}

