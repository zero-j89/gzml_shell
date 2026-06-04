import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  // Local state
  property string editProfilesDir: pluginApi?.pluginSettings?.profilesDir || pluginApi?.manifest?.metadata?.defaultSettings?.profilesDir || ""

  property string editIcon: pluginApi?.pluginSettings?.icon || pluginApi?.manifest?.metadata?.defaultSettings?.icon || "bookmark"

  property bool editIncludeWallpapers: pluginApi?.pluginSettings?.includeWallpapers ?? pluginApi?.manifest?.metadata?.defaultSettings?.includeWallpapers ?? true

  property string editIconColor: pluginApi?.pluginSettings?.iconColor || pluginApi?.manifest?.metadata?.defaultSettings?.iconColor || "primary"

  property bool editBackupEnabled: pluginApi?.pluginSettings?.backupEnabled ?? pluginApi?.manifest?.metadata?.defaultSettings?.backupEnabled ?? true

  property int editBackupCount: pluginApi?.pluginSettings?.backupCount ?? pluginApi?.manifest?.metadata?.defaultSettings?.backupCount ?? 5

  spacing: Style.marginM

  // ── Profiles directory ──────────────────────────────────────────────────

  NTextInputButton {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.dir-label")
    description: pluginApi?.tr("settings.dir-description")
    placeholderText: Settings.configDir + "profiles/"
    text: root.editProfilesDir
    buttonIcon: "folder"
    buttonTooltip: pluginApi?.tr("settings.dir-select")
    onInputEditingFinished: root.editProfilesDir = text
    onButtonClicked: dirPicker.openFilePicker()
  }

  NFilePicker {
    id: dirPicker
    selectionMode: "folders"
    title: pluginApi?.tr("settings.dir-select")
    initialPath: root.editProfilesDir || (Settings.configDir + "profiles/")
    onAccepted: paths => {
                  if (paths.length > 0)
                  root.editProfilesDir = paths[0];
                }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXS
    Layout.bottomMargin: Style.marginXS
  }

  // ── Widget icon ──────────────────────────────────────────────────────────

  RowLayout {
    spacing: Style.marginM

    NLabel {
      label: pluginApi?.tr("settings.icon-label")
      description: pluginApi?.tr("settings.icon-description")
    }

    NIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: root.editIcon || "bookmark"
      pointSize: Style.fontSizeXXXL
      color: Color.resolveColorKeyOptional(root.editIconColor).a > 0 ? Color.resolveColorKeyOptional(root.editIconColor) : Color.mOnSurface
    }
  }

  NButton {
    text: I18n.tr("bar.control-center.browse-library")
    onClicked: iconPicker.open()
  }

  NIconPicker {
    id: iconPicker
    initialIcon: root.editIcon
    onIconSelected: iconName => {
                      root.editIcon = iconName;
                    }
  }

  NColorChoice {
    label: pluginApi?.tr("settings.icon-color-label")
    currentKey: root.editIconColor
    onSelected: key => {
                  root.editIconColor = key;
                }
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.iconColor || "primary"
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXS
    Layout.bottomMargin: Style.marginXS
  }

  // ── Include wallpapers toggle ────────────────────────────────────────────

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.wallpapers-label")
    description: pluginApi?.tr("settings.wallpapers-description")
    checked: root.editIncludeWallpapers
    onToggled: checked => {
                 root.editIncludeWallpapers = checked;
               }
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.includeWallpapers ?? true
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXS
    Layout.bottomMargin: Style.marginXS
  }

  // ── Auto-backup ──────────────────────────────────────────────────────────

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.backup-label")
    description: pluginApi?.tr("settings.backup-description")
    checked: root.editBackupEnabled
    onToggled: checked => {
                 root.editBackupEnabled = checked;
               }
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.backupEnabled ?? true
  }

  NValueSlider {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.backup-count-label")
    description: pluginApi?.tr("settings.backup-count-description")
    from: 1
    to: 20
    stepSize: 1
    snapAlways: true
    value: root.editBackupCount
    text: String(Math.round(root.editBackupCount))
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.backupCount ?? 5
    showReset: true
    enabled: root.editBackupEnabled
    onMoved: function (v) {
      root.editBackupCount = Math.round(v);
    }
  }

  // ── Save ────────────────────────────────

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.pluginSettings.profilesDir = root.editProfilesDir.trim();
    pluginApi.pluginSettings.icon = root.editIcon.trim() || "bookmark";
    pluginApi.pluginSettings.iconColor = root.editIconColor || "primary";
    pluginApi.pluginSettings.includeWallpapers = root.editIncludeWallpapers;
    pluginApi.pluginSettings.backupEnabled = root.editBackupEnabled;
    pluginApi.pluginSettings.backupCount = root.editBackupCount;
    pluginApi.saveSettings();
    Logger.i("ShellProfiles", "Settings saved");
  }
}
