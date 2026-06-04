import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  // Reactive state consumed by BarWidget and Panel
  property var profiles: []
  property var profileMeta: ({})
  property string lastAppliedProfile: pluginApi?.pluginSettings?.lastAppliedProfile || ""
  property bool isBusy: false

  // ─── Reactive derived properties ────────────────────────────────────────────

  readonly property string pluginIcon:
    pluginApi?.pluginSettings?.icon ||
    pluginApi?.manifest?.metadata?.defaultSettings?.icon ||
    "bookmark"

  readonly property string profilesDir: {
    var dir = pluginApi?.pluginSettings?.profilesDir || ""
    if (!dir || dir.trim() === "")
      return Settings.configDir + "profiles/"
    return dir.endsWith("/") ? dir : dir + "/"
  }

  readonly property string backupsDir: profilesDir + "_backups/"

  readonly property string scriptsDir: (pluginApi?.pluginDir ?? "") + "/assets/scripts"

  // ─── Helpers ────────────────────────────────────────────────────────────────

  function _profilePath(name) {
    return profilesDir + name.trim()
  }

  function _timestamp() {
    var now = new Date()
    var pad = function(n) { return String(n).padStart(2, '0') }
    return now.getFullYear() + '-' + pad(now.getMonth() + 1) + '-' + pad(now.getDate()) +
           '_' + pad(now.getHours()) + '-' + pad(now.getMinutes()) + '-' + pad(now.getSeconds())
  }

  function profileExists(name) {
    return root.profiles.indexOf(name ? name.trim() : "") !== -1
  }

  function validateName(name) {
    if (!name || name.trim() === "")
      return pluginApi?.tr("error.name-empty")
    var t = name.trim()
    if (t.length > 64)
      return pluginApi?.tr("error.name-too-long")
    if (/[\/\\.:<>"|?*\x00-\x1f]/.test(t))
      return pluginApi?.tr("error.name-invalid")
    return ""
  }

  // ─── Process: directory listing ─────────────────────────────────────────────

  Process {
    id: listProc
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: function(exitCode, exitStatus) {
      var names = []
      var meta = {}
      if (exitCode === 0) {
        var lines = listProc.stdout.text.split('\n')
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i]
          if (line.trim() === "") continue
          var parts = line.split('\t')
          var name = parts[0].trim()
          var savedAt = parts.length > 1 ? parts[1].trim() : ""
          if (name && !name.startsWith('.') && !name.startsWith('_')) {
            names.push(name)
            meta[name] = { savedAt: savedAt }
          }
        }
      }
      Logger.i("ShellProfiles", "Profiles found:", names.length)
      root.profiles = names
      root.profileMeta = meta
    }
  }

  // ─── Process: general commands ──────────────────────────────────

  Process {
    id: cmdProc
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    property var pendingCallback: null
    onExited: function(exitCode, exitStatus) {
      var cb = pendingCallback
      pendingCallback = null
      if (cb) cb(exitCode, cmdProc.stdout.text, cmdProc.stderr.text)
    }
  }

  function _runCommand(cmd, callback) {
    cmdProc.pendingCallback = callback
    cmdProc.command = cmd
    cmdProc.running = true
  }

  // ─── Backup helpers ──────────────────────────────────────────────────────────

  function _createBackup(beforeProfileName, callback) {
    var bDir = backupsDir
    var ts = _timestamp()
    var backupDir = bDir + ts
    var cfg = Settings.configDir
    var metaJson = JSON.stringify({
      "savedAt": new Date().toISOString(),
      "description": "auto-backup before applying: " + beforeProfileName
    })

    // Build wallpapers JSON from current state
    var screens = []
    try {
      var wmap = WallpaperService.currentWallpapers
      for (var wkey in wmap) {
        var we = wmap[wkey]
        if (!we) continue
        var wl = (typeof we === "string") ? we : (we.light || "")
        var wd = (typeof we === "string") ? we : (we.dark  || "")
        screens.push({ "name": wkey, "light": wl, "dark": wd })
      }
    } catch (e) {}
    var wallJson = JSON.stringify({ "screens": screens }, null, 2)

    var copyCmd = ["sh", scriptsDir + "/backup-configs.sh", cfg, backupDir]
    _runCommand(copyCmd, function(code) {
      if (code !== 0) { if (callback) callback(); return }
      // Write wallpapers
      _runCommand(["sh", scriptsDir + "/write-file.sh", wallJson, backupDir + "/wallpapers.json"], function() {
        // Write meta
        _runCommand(["sh", scriptsDir + "/write-file.sh", metaJson, backupDir + "/meta.json"], function() {
          Logger.i("ShellProfiles", "Backup created:", ts)
          _pruneBackups(bDir, callback)
        })
      })
    })
  }

  function _pruneBackups(bDir, callback) {
    var maxCount = Math.max(1, Math.min(20, pluginApi?.pluginSettings?.backupCount ?? 5))
    _runCommand(["sh", scriptsDir + "/prune-backups.sh", bDir, String(maxCount)], function(code) {
      Logger.i("ShellProfiles", "Pruned backups in:", bDir)
      if (callback) callback()
    })
  }

  // ─── IPC handlers ────────────────────────────────────────────────────────────

  IpcHandler {
    target: "plugin:shell-profiles"

    function toggleProfiles() {
      if (!pluginApi) return
      pluginApi.withCurrentScreen(screen => {
        pluginApi.togglePanel(screen)
      })
    }

    function applyProfile(name: string) {
      if (!pluginApi || !name) return
      var includeWallpapers = pluginApi.pluginSettings?.includeWallpapers ?? true
      root.applyProfile(name, includeWallpapers)
    }
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  Component.onCompleted: {
    Logger.i("ShellProfiles", "Main loaded")
    Quickshell.execDetached(["mkdir", "-p", profilesDir])
    Quickshell.execDetached(["mkdir", "-p", backupsDir])
    listProfiles()
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  function listProfiles() {
    if (listProc.running) return
    listProc.command = ["sh", scriptsDir + "/list-profiles.sh", profilesDir]
    listProc.running = true
  }

  function saveProfile(name, callback) {
    var err = validateName(name)
    if (err) { if (callback) callback(false, err); return }

    var trimmed = name.trim()
    var dirPath = _profilePath(trimmed)
    var cfg = Settings.configDir
    var savedAt = new Date().toISOString()

    // Build wallpapers JSON from current WallpaperService state
    var screens = []
    try {
      var map = WallpaperService.currentWallpapers
      for (var key in map) {
        var entry = map[key]
        if (!entry) continue
        var light = (typeof entry === "string") ? entry : (entry.light || "")
        var dark  = (typeof entry === "string") ? entry : (entry.dark  || "")
        screens.push({ "name": key, "light": light, "dark": dark })
      }
    } catch (e) {
      Logger.w("ShellProfiles", "Could not read WallpaperService:", e)
    }
    var wallpapersJson = JSON.stringify({ "screens": screens }, null, 2)
    var metaJson = JSON.stringify({ "savedAt": savedAt })

    var copyCmd = ["sh", scriptsDir + "/save-profile.sh", cfg, dirPath]

    isBusy = true
    _runCommand(copyCmd, function(code, stdout, stderr) {
      if (code !== 0) {
        root.isBusy = false
        var msg = stderr.trim() || pluginApi?.tr("error.save-failed")
        Logger.e("ShellProfiles", "Save failed:", msg)
        ToastService.showError(pluginApi?.tr("panel.title"), msg)
        if (callback) callback(false, msg)
        return
      }
      // Write wallpapers.json
      _runCommand(["sh", scriptsDir + "/write-file.sh", wallpapersJson, dirPath + "/wallpapers.json"], function(wCode, wStdout, wStderr) {
        if (wCode !== 0) {
          root.isBusy = false
          var wmsg = wStderr.trim() || pluginApi?.tr("error.save-failed")
          Logger.e("ShellProfiles", "Save failed (wallpapers):", wmsg)
          ToastService.showError(pluginApi?.tr("panel.title"), wmsg)
          if (callback) callback(false, wmsg)
          return
        }
        // Write meta.json
        _runCommand(["sh", scriptsDir + "/write-file.sh", metaJson, dirPath + "/meta.json"], function() {
          root.isBusy = false
          Logger.i("ShellProfiles", "Saved profile:", trimmed)
          root.listProfiles()
          ToastService.showNotice(
            pluginApi?.tr("panel.title"),
            pluginApi?.tr("toast.saved", { "name": trimmed }),
            pluginIcon
          )
          if (callback) callback(true, "")
        })
      })
    })
  }

  function applyProfile(name, includeWallpapers, callback) {
    var err = validateName(name)
    if (err) { if (callback) callback(false, err); return }

    var trimmed = name.trim()
    var dirPath = _profilePath(trimmed)
    var cfg = Settings.configDir

    var copyConfigFiles = function() {
      var cmd = ["sh", scriptsDir + "/apply-profile.sh", dirPath, cfg]
      _runCommand(cmd, function(code, stdout, stderr) {
        root.isBusy = false
        if (code === 0) {
          // Persist the last applied profile name
          root.lastAppliedProfile = trimmed
          if (pluginApi) {
            pluginApi.pluginSettings.lastAppliedProfile = trimmed
            pluginApi.saveSettings()
          }
          Logger.i("ShellProfiles", "Applied profile:", trimmed)
          ToastService.showNotice(
            pluginApi?.tr("panel.title"),
            pluginApi?.tr("toast.applied", { "name": trimmed }),
            pluginIcon
          )
          if (callback) callback(true, "")
        } else {
          var msg = stderr.trim() || pluginApi?.tr("error.apply-failed")
          Logger.e("ShellProfiles", "Apply failed:", msg)
          ToastService.showError(pluginApi?.tr("panel.title"), msg)
          if (callback) callback(false, msg)
        }
      })
    }

    var doApply = function() {
      if (includeWallpapers) {
        _runCommand(["cat", dirPath + "/wallpapers.json"], function(wCode, wStdout) {
          if (wCode === 0) {
            try {
              var data = JSON.parse(wStdout)
              if (data && data.screens && Array.isArray(data.screens)) {
                for (var i = 0; i < data.screens.length; i++) {
                  var entry = data.screens[i]
                  if (!entry || !entry.name) continue
                  if (entry.light)
                    WallpaperService.changeWallpaper(entry.light, entry.name, "light")
                  if (entry.dark && entry.dark !== entry.light)
                    WallpaperService.changeWallpaper(entry.dark, entry.name, "dark")
                }
              }
            } catch (e) {
              Logger.w("ShellProfiles", "Could not parse wallpapers.json:", e)
            }
          }
          copyConfigFiles()
        })
      } else {
        copyConfigFiles()
      }
    }

    isBusy = true

    // Create auto-backup before applying, if enabled
    var backupEnabled = pluginApi?.pluginSettings?.backupEnabled ?? true
    if (backupEnabled) {
      _createBackup(trimmed, doApply)
    } else {
      doApply()
    }
  }

  function deleteProfile(name, callback) {
    var err = validateName(name)
    if (err) { if (callback) callback(false, err); return }

    var trimmed = name.trim()
    isBusy = true
    _runCommand(["rm", "-rf", _profilePath(trimmed)], function(code, stdout, stderr) {
      root.isBusy = false
      if (code === 0) {
        // Clear active profile indicator if we deleted the active one
        if (root.lastAppliedProfile === trimmed) {
          root.lastAppliedProfile = ""
          if (pluginApi) {
            pluginApi.pluginSettings.lastAppliedProfile = ""
            pluginApi.saveSettings()
          }
        }
        Logger.i("ShellProfiles", "Deleted profile:", trimmed)
        root.listProfiles()
        ToastService.showNotice(
          pluginApi?.tr("panel.title"),
          pluginApi?.tr("toast.deleted", { "name": trimmed }),
          pluginIcon
        )
        if (callback) callback(true, "")
      } else {
        var msg = stderr.trim() || pluginApi?.tr("error.delete-failed")
        Logger.e("ShellProfiles", "Delete failed:", msg)
        ToastService.showError(pluginApi?.tr("panel.title"), msg)
        if (callback) callback(false, msg)
      }
    })
  }

  function renameProfile(oldName, newName, callback) {
    var err = validateName(oldName) || validateName(newName)
    if (err) { if (callback) callback(false, err); return }

    var oldT = oldName.trim()
    var newT = newName.trim()
    if (oldT === newT) { if (callback) callback(true, ""); return }

    isBusy = true
    _runCommand(["mv", _profilePath(oldT), _profilePath(newT)], function(code, stdout, stderr) {
      root.isBusy = false
      if (code === 0) {
        // Keep active profile in sync after rename
        if (root.lastAppliedProfile === oldT) {
          root.lastAppliedProfile = newT
          if (pluginApi) {
            pluginApi.pluginSettings.lastAppliedProfile = newT
            pluginApi.saveSettings()
          }
        }
        Logger.i("ShellProfiles", "Renamed:", oldT, "->", newT)
        root.listProfiles()
        if (callback) callback(true, "")
      } else {
        var msg = stderr.trim() || pluginApi?.tr("error.rename-failed")
        Logger.e("ShellProfiles", "Rename failed:", msg)
        ToastService.showError(pluginApi?.tr("panel.title"), msg)
        if (callback) callback(false, msg)
      }
    })
  }

}
