import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "MarketplaceModel.js" as MarketplaceModel
import "MarketplaceSession.js" as MarketplaceSession

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool loading: false
  property bool catalogLoaded: false
  property bool catalogRequestParsed: false
  property bool installConfirmOpen: false
  property string pendingPlacement: "center" // "left" | "center" | "right"
  property string errorMessage: ""
  property string statusMessage: ""
  property string generatedAt: ""

  // Navigation & Views
  property string viewMode: "browse" // "browse" | "manage" | "updates"
  property string rightTabMode: "overview" // "overview" | "readme"
  property string categoryFilter: "all" // "all" | "verified" | "bar-widget" | "overlay" | "service" | "panel" | "menu"
  property string sortMode: "added"
  property bool sortAscending: false
  property string managementFilter: "all"
  property int selectedIndex: 0
  property bool preserveSelectionForNextRebuild: true

  // Data Stores
  property var catalogPlugins: []
  property var displayRows: []
  property var engagementStats: ({})
  property bool engagementAvailable: false
  property bool engagementRequestParsed: false

  property var installedIds: ({})
  property bool installedLoaded: false
  property bool installedRequestParsed: false
  property var installedPlugins: []
  property var managedRows: []
  property var updateRows: []

  property var gitManagedIds: ({})
  property var gitProbeQueue: []
  property int gitProbeGeneration: 0
  property int activeGitProbeGeneration: 0
  property var updateStatusById: ({})
  property bool updateCheckLoaded: false
  property int updateCheckGeneration: 0
  property int activeUpdateCheckGeneration: 0

  // Actions & Installs
  property var pendingPlugin: null
  property var pendingManagedPlugin: null
  property string pendingAction: ""
  property string pendingValidatedAction: ""
  property string pendingValidatedPluginId: ""
  property var pendingRevalidatedPlugin: null
  property string pendingUpdateLocalCommit: ""
  property string pendingUpdateRemoteCommit: ""
  property string installingPluginId: ""
  property string installingPluginName: ""
  property string failedPluginId: ""
  property string installStdout: ""
  property string installStderr: ""
  property string pendingInstallFailureMessage: ""
  property string managingPluginId: ""
  property string managingPluginName: ""
  property string managingAction: ""
  property string managementStdout: ""
  property string managementStderr: ""
  property string probingPluginId: ""
  property string installHandoffPluginId: ""

  // Preview & README
  property string previewPath: ""
  property string previewTargetFile: ""
  property string previewRequestUrl: ""
  property string previewActiveUrl: ""
  property string currentReadmeText: ""
  property bool loadingReadme: false
  property string currentReadmeRepo: ""

  readonly property var sortButtons: [
    {
      id: "copies",
      label: "📥 Copies",
      defaultTip: "Sort by downloads/copies (highest first)",
      descTip: "Sorted by copies (highest first) — Click for lowest first",
      ascTip: "Sorted by copies (lowest first) — Click for highest first"
    },
    {
      id: "stars",
      label: "★ Stars",
      defaultTip: "Sort by stars (highest first)",
      descTip: "Sorted by stars (highest first) — Click for lowest first",
      ascTip: "Sorted by stars (lowest first) — Click for highest first"
    },
    {
      id: "views",
      label: "👁 Views",
      defaultTip: "Sort by views (highest first)",
      descTip: "Sorted by views (highest first) — Click for lowest first",
      ascTip: "Sorted by views (lowest first) — Click for highest first"
    },
    {
      id: "hearts",
      label: "❤️ Likes",
      defaultTip: "Sort by likes (highest first)",
      descTip: "Sorted by likes (highest first) — Click for lowest first",
      ascTip: "Sorted by likes (lowest first) — Click for highest first"
    },
    {
      id: "added",
      label: "🕒 Added",
      defaultTip: "Sort by date added (newest first)",
      descTip: "Sorted by date added (newest first) — Click for oldest first",
      ascTip: "Sorted by date added (oldest first) — Click for newest first"
    },
    {
      id: "name",
      label: "🔤 Name",
      defaultTip: "Sort alphabetically (A to Z)",
      descTip: "Sorted by name (Z to A) — Click for A to Z",
      ascTip: "Sorted by name (A to Z) — Click for Z to A"
    }
  ]

  readonly property var managementOptions: [
    { value: "all", label: "All plugins" },
    { value: "enabled", label: "Enabled" },
    { value: "disabled", label: "Disabled" }
  ]

  readonly property var categoryChips: [
    { id: "all", label: "All" },
    { id: "verified", label: "Verified" },
    { id: "bar-widget", label: "Bar Widgets" },
    { id: "overlay", label: "Overlays" },
    { id: "service", label: "Services" },
    { id: "panel", label: "Panels" },
    { id: "menu", label: "Menus" }
  ]

  // Native Omarchy Colors & Tokens
  readonly property color background: Color.menu.background
  readonly property color foreground: Color.menu.text
  readonly property color border: Color.menu.border
  readonly property color scrim: Color.menu.scrim
  readonly property color accent: Color.menu.selectedText
  readonly property color selectedBackground: Color.menu.selectedBackground
  readonly property string fontFamily: Style.font.menuFamily
  readonly property int captionFontSize: Style.font.caption + 2
  readonly property int smallFontSize: Style.font.bodySmall + 2
  readonly property int bodyFontSize: Style.font.body + 2
  readonly property int titleFontSize: Style.font.title + 2
  readonly property int headingFontSize: Style.font.heading + 2
  readonly property int displayFontSize: Style.font.display + 2

  readonly property int cardWidth: Math.min(Style.space(1220), panel.width - Style.gapsOut * 2)
  readonly property int cardHeight: Math.min(Style.space(880), panel.height - Style.gapsOut * 2)
  readonly property bool compactManagementTable: cardWidth < Style.space(900)

  readonly property int updateCount: {
    var count = 0
    for (var i = 0; i < root.installedPlugins.length; i++) {
      var st = root.updateStatusById[root.installedPlugins[i].pluginId]
      if (st && st.status === "available") count++
    }
    return count
  }

  readonly property int updateErrorCount: {
    var count = 0
    for (var i = 0; i < root.installedPlugins.length; i++) {
      var st = root.updateStatusById[root.installedPlugins[i].pluginId]
      if (st && st.status === "error") count++
    }
    return count
  }

  readonly property int updateCheckedCount: {
    var count = 0
    for (var i = 0; i < root.installedPlugins.length; i++) {
      var st = root.updateStatusById[root.installedPlugins[i].pluginId]
      if (st && st.status !== "unsupported") count++
    }
    return count
  }

  readonly property var selectedPlugin: displayRows.length > 0 && selectedIndex >= 0 && selectedIndex < displayRows.length
    ? displayRows[selectedIndex]
    : null

  readonly property bool installHandoffActive: root.installHandoffPluginId !== ""
  readonly property bool operationRunning: installProc.running || managementProc.running
    || installedProc.running
    || postInstallEnableProc.running || postInstallRescanProc.running
    || postInstallPresenceProc.running
  readonly property bool installBusy: root.operationRunning || root.installHandoffActive
  readonly property string pluginId: (root.manifest && root.manifest.id) ? root.manifest.id : "waldseelen.market"
  readonly property string pluginDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/" + root.pluginId
  readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/omarchy"
  readonly property string localCatalogPath: cacheDir + "/plugins-catalog.json"

  // --------------------------------------------------------------------------
  // Lifecycle API
  // --------------------------------------------------------------------------
  function open(payloadJson) {
    MarketplaceSession.openRequested = true
    root.opened = true
    root.statusMessage = ""
    root.refreshInstalled()

    try {
      if (payloadJson) {
        var p = typeof payloadJson === "string" ? JSON.parse(payloadJson) : payloadJson
        if (p && p.view) root.setView(p.view)
      }
    } catch (e) {}

    if (!root.catalogLoaded) {
      // First try loading instantaneous local cache
      localCacheProc.running = true
      root.refreshCatalog()
    }
    if (!root.engagementAvailable && !engagementProc.running) root.refreshEngagement()

    Qt.callLater(function() {
      searchField.forceActiveFocus()
    })
  }

  function close() {
    MarketplaceSession.openRequested = false
    root.installConfirmOpen = false
    root.pendingPlugin = null
    root.pendingManagedPlugin = null
    root.pendingAction = ""
    root.opened = false
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function") {
      root.shell.hide(root.manifest ? root.manifest.id : "waldseelen.market")
    }
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  Component.onCompleted: {
    root.viewMode = MarketplaceSession.viewMode || "browse"
    root.managementFilter = MarketplaceSession.managementFilter || "all"
    root.installHandoffPluginId = MarketplaceSession.pendingInstallId || ""
    if (searchField && MarketplaceSession.searchText) searchField.text = MarketplaceSession.searchText
    if (MarketplaceSession.openRequested) Qt.callLater(function() { root.open("{}") })
    else if (MarketplaceSession.pendingInstallId) Qt.callLater(function() { root.refreshInstalled() })
  }

  // --------------------------------------------------------------------------
  // Catalog & Search Engine
  // --------------------------------------------------------------------------
  function refreshCatalog() {
    if (catalogProc.running) return
    root.loading = true
    root.errorMessage = ""
    root.catalogRequestParsed = false
    catalogProc.running = true
  }

  function loadCatalog(raw) {
    try {
      var catalog = JSON.parse(String(raw || ""))
      var schemaVersion = Number(catalog.stateSchemaVersion)
      if (!isFinite(schemaVersion) || schemaVersion < 1 || schemaVersion > 99
          || Math.floor(schemaVersion) !== schemaVersion
          || !Array.isArray(catalog.plugins) || catalog.plugins.length > 20000)
        throw new Error("Unsupported catalog format")

      var validPlugins = []
      for (var i = 0; i < catalog.plugins.length; i++) {
        if (MarketplaceModel.validateCatalogPlugin(catalog.plugins[i]))
          validPlugins.push(catalog.plugins[i])
      }
      if (validPlugins.length === 0)
        throw new Error("No usable plugins in catalog")

      root.catalogPlugins = validPlugins
      root.generatedAt = String(catalog.generatedAt || "")
      root.catalogLoaded = true
      root.catalogRequestParsed = true
      root.scheduleRebuild()
    } catch (error) {
      if (!root.catalogLoaded) {
        root.errorMessage = "Could not read the marketplace catalog: " + error
      }
    }
  }

  function refreshEngagement() {
    if (engagementProc.running) return
    root.engagementRequestParsed = false
    engagementProc.running = true
  }

  function loadEngagement(raw) {
    try {
      var response = JSON.parse(String(raw || ""))
      if (response.schemaVersion !== 1 || !response.plugins
          || typeof response.plugins !== "object" || Array.isArray(response.plugins))
        throw new Error("Unsupported engagement format")
      var stats = ({})
      var ids = Object.keys(response.plugins)
      if (ids.length > 20000) throw new Error("Engagement response is too large")
      for (var i = 0; i < ids.length; i++) {
        var id = ids[i]
        if (!MarketplaceModel.pluginIdIsSafe(id) || id.length > 128) continue
        var entry = response.plugins[id]
        if (!entry || typeof entry !== "object" || Array.isArray(entry)) continue
        var safeEntry = ({})
        var metrics = ["views", "copies", "hearts"]
        for (var j = 0; j < metrics.length; j++) {
          var metric = Number(entry[metrics[j]])
          if (isFinite(metric) && metric >= 0 && metric <= 1000000000)
            safeEntry[metrics[j]] = metric
        }
        stats[id] = safeEntry
      }
      root.engagementStats = stats
      root.engagementAvailable = true
      root.engagementRequestParsed = true
      if (root.catalogLoaded) root.scheduleRebuild()
    } catch (error) {
      root.engagementAvailable = false
    }
  }

  function matchesCategory(plugin, cat) {
    if (!cat || cat === "all") return true
    if (cat === "verified") return plugin.verificationStatus === "verified"
    var k = String(plugin.kind || "").toLowerCase()
    if (cat === "bar-widget") return k.indexOf("bar") !== -1
    if (cat === "overlay") return k.indexOf("overlay") !== -1
    if (cat === "service") return k.indexOf("service") !== -1
    if (cat === "panel") return k.indexOf("panel") !== -1
    if (cat === "menu") return k.indexOf("menu") !== -1
    return true
  }

  function rebuildDisplay() {
    var previousId = root.preserveSelectionForNextRebuild && root.selectedPlugin
      ? root.selectedPlugin.pluginId : ""
    root.preserveSelectionForNextRebuild = true

    var query = searchField ? searchField.text : ""
    var matchingPlugins = []
    for (var i = 0; i < root.catalogPlugins.length; i++) {
      var candidate = root.catalogPlugins[i]
      if (matchesCategory(candidate, root.categoryFilter) &&
          MarketplaceModel.matches(candidate, query, root.sortMode)) {
        matchingPlugins.push(candidate)
      }
    }
    matchingPlugins = MarketplaceModel.sortPlugins(matchingPlugins, root.sortMode, root.engagementStats, root.sortAscending)

    var rows = []
    for (var sortedIndex = 0; sortedIndex < matchingPlugins.length; sortedIndex++) {
      var plugin = matchingPlugins[sortedIndex]
      var pluginId = String(plugin.id || "")
      var stats = root.engagementStats[pluginId] || {}
      rows.push({
        pluginId: pluginId,
        pluginName: MarketplaceModel.plainText(plugin.name || plugin.id, "Unnamed plugin"),
        description: MarketplaceModel.plainText(plugin.description, "No description provided."),
        author: MarketplaceModel.plainText(plugin.author, "Unknown"),
        pluginVersion: String(plugin.version || ""),
        category: MarketplaceModel.plainText(plugin.category, "Other"),
        tagsText: (plugin.tags || []).map(function(tag) { return MarketplaceModel.plainText(tag) }).join("  ·  "),
        repo: String(plugin.repo || ""),
        kind: MarketplaceModel.plainText(plugin.kind, "Plugin"),
        verificationStatus: String(plugin.verificationStatus || "unverified"),
        installAvailable: plugin.installAvailable === true && MarketplaceModel.repoIsSafe(plugin.repo),
        installNote: MarketplaceModel.plainText(plugin.installNote),
        previewImage: MarketplaceModel.previewUrl(plugin.previewImage || plugin.previewThumbnail),
        listingCommit: String(plugin.listingValidatedCommit || ""),
        upstreamCommit: String(plugin.upstreamValidatedCommit || ""),
        installed: root.installedIds[pluginId] === true,
        viewsText: MarketplaceModel.formatCount(root.engagementAvailable ? stats.views : -1),
        copiesText: MarketplaceModel.formatCount(root.engagementAvailable ? stats.copies : -1),
        starsText: MarketplaceModel.formatCount(plugin.stars),
        heartsText: MarketplaceModel.formatCount(root.engagementAvailable ? stats.hearts : -1)
      })
    }

    var nextIndex = 0
    if (previousId) {
      for (var j = 0; j < rows.length; j++) {
        if (rows[j].pluginId === previousId) {
          nextIndex = j
          break
        }
      }
    }
    root.displayRows = rows
    root.selectedIndex = rows.length > 0 ? nextIndex : 0
    Qt.callLater(function() {
      if (root.displayRows.length > 0 && pluginList) pluginList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
      previewDebounceTimer.restart()
    })
  }

  function scheduleRebuild(preserveSelection) {
    if (preserveSelection === false) root.preserveSelectionForNextRebuild = false
    rebuildTimer.restart()
  }

  function select(index) {
    if (index < 0 || index >= root.displayRows.length) return
    if (root.selectedIndex === index) return
    root.selectedIndex = index
    if (pluginList) pluginList.positionViewAtIndex(index, ListView.Contain)
    previewDebounceTimer.restart()
  }

  function selectRelative(delta) {
    if (root.viewMode !== "browse") return
    if (root.displayRows.length === 0) return
    root.selectedIndex = (root.selectedIndex + delta + root.displayRows.length) % root.displayRows.length
    if (pluginList) pluginList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    previewDebounceTimer.restart()
  }

  function setView(mode) {
    if (root.viewMode === mode) return
    root.viewMode = mode
    MarketplaceSession.viewMode = mode
    MarketplaceSession.searchText = ""
    if (searchField) searchField.clear()
    root.statusMessage = ""
    if (mode !== "browse" && !root.installedLoaded) root.refreshInstalled()
    else if (mode !== "browse") root.scheduleManagedRebuild()
    Qt.callLater(function() { if (searchField) searchField.forceActiveFocus() })
  }

  function setCategory(cat) {
    if (root.categoryFilter === cat) return
    root.categoryFilter = cat
    root.scheduleRebuild(false)
  }

  function setSort(mode) {
    root.toggleSort(mode)
  }

  function toggleSort(mode) {
    if (root.sortMode === mode) {
      root.sortAscending = !root.sortAscending
    } else {
      root.sortMode = mode
      root.sortAscending = (mode === "name")
    }
    root.scheduleRebuild(false)
  }

  // --------------------------------------------------------------------------
  // Preview & README Helpers
  // --------------------------------------------------------------------------
  function refreshPreview() {
    var source = root.selectedPlugin ? String(root.selectedPlugin.previewImage || "") : ""
    root.previewRequestUrl = source
    if (!source) {
      root.previewPath = ""
      root.previewTargetFile = ""
      return
    }

    var cleanName = source.substring(source.lastIndexOf("/") + 1) || "preview.webp"
    var targetFile = root.cacheDir + "/previews/" + cleanName
    root.previewTargetFile = targetFile

    if (previewProc.running) return
    root.previewActiveUrl = source
    previewProc.command = ["bash", root.pluginDir + "/fetch-preview", source, targetFile]
    previewProc.running = true
  }

  function refreshReadme() {
    if (!root.selectedPlugin || !root.selectedPlugin.repo) {
      root.currentReadmeText = ""
      root.currentReadmeRepo = ""
      return
    }
    var repo = root.selectedPlugin.repo
    if (root.currentReadmeRepo === repo && root.currentReadmeText) return
    root.currentReadmeRepo = repo
    root.loadingReadme = true
    root.currentReadmeText = "Loading README from GitHub..."
    readmeProc.command = ["bash", root.pluginDir + "/fetch-readme", repo]
    readmeProc.running = true
  }

  function copyInstallCommand(plugin) {
    if (!plugin || !plugin.repo) return
    var cmd = "omarchy plugin add " + plugin.repo + " --enable"
    copyCmdProc.command = ["bash", "-c", "echo -n '" + cmd + "' | wl-copy && notify-send 'Omarchy Market' 'Install command copied to clipboard:\n" + cmd + "' -i software-properties"]
    copyCmdProc.running = true
  }

  function openGithubRepo(plugin) {
    if (!plugin || !plugin.repo) return
    openBrowserProc.command = ["xdg-open", plugin.repo]
    openBrowserProc.running = true
  }

  function openOmarchyPluginPage(plugin) {
    if (!plugin || !plugin.pluginId) return
    var url = "https://plugins.omarchy.org/?q=" + encodeURIComponent(plugin.pluginId) + "#catalog"
    openBrowserProc.command = ["xdg-open", url]
    openBrowserProc.running = true
  }

  function copyTextToClipboard(text) {
    if (!text) return
    var safeText = text.replace(/'/g, "'\\''")
    copyCmdProc.command = ["bash", "-c", "echo -n '" + safeText + "' | wl-copy && notify-send 'Omarchy Market' 'Copied to clipboard:\n" + safeText + "' -i software-properties 2>/dev/null || true"]
    copyCmdProc.running = true
    root.statusMessage = "Copied to clipboard."
  }

  function installCommandFor(plugin) {
    if (!plugin) return ""
    var repo = plugin.repo || ""
    return "omarchy plugin add " + repo + " --enable"
  }

  function enableCommandFor(plugin, placement) {
    if (!plugin) return ""
    var cmd = "omarchy plugin enable " + plugin.pluginId
    if (root.isBarWidget(plugin) && placement) {
      cmd += " --section " + placement
    }
    return cmd
  }

  function updateCommandFor(plugin) {
    if (!plugin) return ""
    return "omarchy plugin update " + plugin.pluginId
  }

  function removeCommandFor(plugin) {
    if (!plugin) return ""
    return "omarchy plugin remove " + plugin.pluginId
  }

  function currentPendingCommand() {
    if (root.pendingAction === "install") {
      return root.installCommandFor(root.pendingPlugin)
    } else if (root.pendingAction === "enable") {
      return root.enableCommandFor(root.pendingManagedPlugin, root.pendingPlacement)
    } else if (root.pendingAction === "update") {
      return root.updateCommandFor(root.pendingManagedPlugin)
    } else if (root.pendingAction === "remove") {
      return root.removeCommandFor(root.pendingManagedPlugin)
    }
    return ""
  }

  function runInTerminal(command) {
    if (!command) return
    var targetCmd = command
    root.dismiss()
    Util.execDetached("omarchy-launch-floating-terminal-with-presentation " + targetCmd)
  }

  // --------------------------------------------------------------------------
  // Installed Plugins & Management
  // --------------------------------------------------------------------------
  function refreshInstalled() {
    if (installedProc.running || installProc.running || managementProc.running) return
    root.installedRequestParsed = false
    installedProc.running = true
  }

  function loadInstalled(raw) {
    try {
      var rows = JSON.parse(String(raw || ""))
      if (!Array.isArray(rows)) throw new Error("Plugin list is not an array")
      var ids = {}
      var plugins = []
      for (var i = 0; i < rows.length; i++) {
        var id = String(rows[i].id || "")
        if (!MarketplaceModel.pluginIdIsSafe(id)) continue
        var kinds = Array.isArray(rows[i].kinds) ? rows[i].kinds.map(String) : []
        ids[id] = true
        plugins.push({
          pluginId: id,
          pluginName: String(rows[i].name || id),
          kinds: kinds,
          kindsText: kinds.join(", "),
          enabled: rows[i].enabled === true,
          active: rows[i].active === true,
          canDisable: rows[i].canDisable === true,
          firstParty: rows[i].firstParty === true,
          clonedFrom: String(rows[i].clonedFrom || "")
        })
      }
      root.installedIds = ids
      root.installedPlugins = plugins
      root.gitManagedIds = ({})
      root.gitProbeQueue = []
      root.gitProbeGeneration++
      root.installedLoaded = true
      root.installedRequestParsed = true
      root.rebuildManaged()
      root.queueGitProbes()
      root.queueUpdateCheck()
      if (root.catalogLoaded) root.scheduleRebuild()
      if (MarketplaceSession.pendingInstallId)
        Qt.callLater(function() { root.continuePendingInstall() })
    } catch (error) {
      root.statusMessage = "Installed plugin status is unavailable."
    }
  }

  function rebuildManaged() {
    var query = searchField ? searchField.text : ""
    var matching = []
    var updates = []
    for (var i = 0; i < root.installedPlugins.length; i++) {
      var plugin = root.installedPlugins[i]
      if (MarketplaceModel.matchesInstalled(plugin, query, root.managementFilter)) matching.push(plugin)
      var update = root.updateStatusById[plugin.pluginId]
      if (update && update.status === "available"
          && MarketplaceModel.matchesInstalled(plugin, query, "all")) {
        updates.push(Object.assign({}, plugin, {
          localCommit: String(update.localCommit || ""),
          remoteCommit: String(update.remoteCommit || "")
        }))
      }
    }
    root.managedRows = MarketplaceModel.sortInstalled(matching)
    root.updateRows = MarketplaceModel.sortInstalled(updates)
  }

  function scheduleManagedRebuild() {
    managedRebuildTimer.restart()
  }

  function setManagementFilter(filter) {
    if (root.managementFilter === filter) return
    root.managementFilter = filter
    MarketplaceSession.managementFilter = filter
    root.scheduleManagedRebuild()
  }

  function queueUpdateCheck() {
    root.updateCheckGeneration++
    root.updateCheckLoaded = false
    root.rebuildManaged()
    if (!updateCheckProc.running) root.startUpdateCheck()
  }

  function startUpdateCheck() {
    if (updateCheckProc.running) return
    var ids = []
    for (var i = 0; i < root.installedPlugins.length; i++) {
      var plugin = root.installedPlugins[i]
      if (!plugin.firstParty && MarketplaceModel.pluginIdIsSafe(plugin.pluginId)) ids.push(plugin.pluginId)
    }
    root.activeUpdateCheckGeneration = root.updateCheckGeneration
    if (ids.length === 0) {
      root.updateStatusById = ({})
      root.updateCheckLoaded = true
      root.rebuildManaged()
      return
    }
    updateCheckProc.command = ["bash", root.pluginDir + "/plugin-update-status"].concat(ids)
    updateCheckProc.running = true
  }

  function loadUpdateStatus(raw) {
    try {
      var payload = JSON.parse(String(raw || ""))
      var statuses = {}
      var list = payload.plugins || []
      for (var i = 0; i < list.length; i++) {
        var result = list[i]
        var id = String(result.id || "")
        var status = String(result.status || "")
        if (!MarketplaceModel.pluginIdIsSafe(id)) continue
        statuses[id] = {
          status: status,
          localCommit: String(result.localCommit || ""),
          remoteCommit: String(result.remoteCommit || ""),
          error: String(result.error || "")
        }
      }
      root.updateStatusById = statuses
      root.updateCheckLoaded = true
      root.rebuildManaged()
    } catch (e) {
      root.updateStatusById = ({})
      root.updateCheckLoaded = false
      root.rebuildManaged()
    }
  }

  function queueGitProbes() {
    var queue = []
    for (var i = 0; i < root.installedPlugins.length; i++) {
      var plugin = root.installedPlugins[i]
      if (!plugin.firstParty && MarketplaceModel.pluginIdIsSafe(plugin.pluginId))
        queue.push({ id: plugin.pluginId, generation: root.gitProbeGeneration })
    }
    root.gitProbeQueue = queue
    root.startNextGitProbe()
  }

  function startNextGitProbe() {
    if (gitProbeProc.running || root.gitProbeQueue.length === 0) return
    var queue = root.gitProbeQueue.slice()
    var entry = queue.shift()
    root.gitProbeQueue = queue
    root.probingPluginId = entry.id
    root.activeGitProbeGeneration = entry.generation
    gitProbeProc.command = ["test", "-d",
      Quickshell.env("HOME") + "/.config/omarchy/plugins/" + entry.id + "/.git"]
    gitProbeProc.running = true
  }

  function installedPluginById(id) {
    for (var i = 0; i < root.installedPlugins.length; i++) {
      if (root.installedPlugins[i].pluginId === id) return root.installedPlugins[i]
    }
    return null
  }

  // --------------------------------------------------------------------------
  // Installation & Management Actions
  // --------------------------------------------------------------------------
  function requestInstall(plugin) {
    if (!plugin) return
    if (plugin.installed) {
      root.statusMessage = plugin.pluginName + " is already installed."
      return
    }
    if (root.installBusy) {
      root.statusMessage = "Another installation or update is in progress."
      return
    }
    root.pendingPlugin = plugin
    root.pendingAction = "install"
    root.pendingPlacement = "center"
    root.installConfirmOpen = true
  }

  function cancelInstall() {
    root.installConfirmOpen = false
    root.pendingPlugin = null
    root.pendingManagedPlugin = null
    root.pendingAction = ""
    root.pendingUpdateLocalCommit = ""
    root.pendingUpdateRemoteCommit = ""
    Qt.callLater(function() { if (searchField) searchField.forceActiveFocus() })
  }

  function confirmInstall() {
    var plugin = root.pendingPlugin
    root.installConfirmOpen = false
    if (!plugin || !MarketplaceModel.pluginIdIsSafe(plugin.pluginId)
        || !MarketplaceModel.repoIsSafe(plugin.repo)) {
      root.pendingPlugin = null
      root.pendingAction = ""
      root.statusMessage = "Installation blocked: plugin repository is not valid."
      return
    }
    root.installingPluginId = plugin.pluginId
    root.installingPluginName = plugin.pluginName
    root.failedPluginId = ""
    root.installStdout = ""
    root.installStderr = ""
    MarketplaceSession.pendingInstallId = plugin.pluginId
    root.installHandoffPluginId = plugin.pluginId
    MarketplaceSession.pendingInstallName = plugin.pluginName
    MarketplaceSession.pendingInstallStage = "installing"
    MarketplaceSession.pendingInstallToken = String(Date.now())
    MarketplaceSession.pendingInstallAllowEnable = !root.pluginReplacesBar(plugin)
    MarketplaceSession.pendingPlacement = root.pendingPlacement || "center"
    MarketplaceSession.pendingInstallAttempts = 0
    MarketplaceSession.pendingEnableAttempts = 0
    root.statusMessage = "Installing " + plugin.pluginName + "…"
    installProc.command = ["bash", root.pluginDir + "/plugin-add-checked", plugin.repo,
      plugin.pluginId, MarketplaceSession.pendingInstallToken]
    installProc.running = true
  }

  function clearInstallHandoff() {
    var token = MarketplaceSession.pendingInstallToken
    if (token && !installReceiptCleanupProc.running) {
      installReceiptCleanupProc.command = ["bash", root.pluginDir + "/plugin-add-checked",
        "--remove-receipt", token]
      installReceiptCleanupProc.running = true
    }
    MarketplaceSession.pendingInstallId = ""
    root.installHandoffPluginId = ""
    MarketplaceSession.pendingInstallName = ""
    MarketplaceSession.pendingInstallStage = ""
    MarketplaceSession.pendingInstallToken = ""
    MarketplaceSession.pendingInstallAllowEnable = false
    MarketplaceSession.pendingInstallAttempts = 0
    MarketplaceSession.pendingEnableAttempts = 0
  }

  function continuePendingInstall() {
    var id = MarketplaceSession.pendingInstallId
    if (!id || installedProc.running) return
    var name = MarketplaceSession.pendingInstallName || id
    if (MarketplaceSession.pendingInstallStage === "installing") {
      if (!postInstallPresenceProc.running) {
        postInstallPresenceProc.command = ["bash", root.pluginDir + "/plugin-add-checked",
          "--consume-receipt", MarketplaceSession.pendingInstallToken, id]
        postInstallPresenceProc.running = true
      }
      return
    }
    var plugin = root.installedPluginById(id)
    if (!plugin) {
      MarketplaceSession.pendingInstallAttempts++
      if (MarketplaceSession.pendingInstallAttempts > 40) {
        root.clearInstallHandoff()
        root.statusMessage = "Installation finished, but " + name + " could not be discovered."
        return
      }
      root.statusMessage = "Waiting for " + name + " to be discovered…"
      if (MarketplaceSession.pendingInstallAttempts === 8 && !postInstallRescanProc.running) {
        postInstallRescanProc.running = true
      } else pendingInstallTimer.restart()
      return
    }

    root.failedPluginId = ""
    root.rebuildManaged()
    if (root.catalogLoaded) root.scheduleRebuild()
    if (plugin.kinds.indexOf("bar") !== -1) {
      root.clearInstallHandoff()
      root.statusMessage = name + " was installed. Activate full-bar plugins from CLI."
      return
    }
    if (!MarketplaceSession.pendingInstallAllowEnable) {
      root.clearInstallHandoff()
      root.statusMessage = name + " was installed without activation."
      return
    }
    if (plugin.enabled) {
      root.clearInstallHandoff()
      root.statusMessage = name + " was installed and enabled."
      return
    }

    if (MarketplaceSession.pendingInstallStage !== "enabling") {
      MarketplaceSession.pendingInstallStage = "enabling"
      MarketplaceSession.pendingInstallAttempts = 0
      MarketplaceSession.pendingEnableAttempts++
      var enableCmd = ["omarchy", "plugin", "enable", id]
      if (plugin.kinds && plugin.kinds.indexOf("bar-widget") !== -1 && plugin.kinds.indexOf("bar") === -1) {
        enableCmd.push("--section", MarketplaceSession.pendingPlacement || "center")
      }
      postInstallEnableProc.command = enableCmd
      postInstallEnableProc.running = true
      return
    }

    MarketplaceSession.pendingInstallAttempts++
    if (MarketplaceSession.pendingInstallAttempts >= 8) {
      root.clearInstallHandoff()
      root.statusMessage = name + " was installed. Enable it from Manage."
    } else pendingInstallTimer.restart()
  }

  function requestManagementAction(action, plugin) {
    if (root.operationRunning || !root.installedRequestParsed || !plugin
        || !MarketplaceModel.pluginIdIsSafe(plugin.pluginId)) return
    if (plugin.pluginId === "waldseelen.market") {
      root.statusMessage = "Manage the running marketplace itself from the command line."
      return
    }
    if (action === "enable" && plugin.kinds.indexOf("bar") !== -1) {
      root.statusMessage = "Enable full-bar plugins from the command line."
      return
    }
    if (action === "remove" && plugin.active) {
      root.statusMessage = "Remove the active bar from the command line."
      return
    }
    if (action === "update" && plugin.active) {
      root.statusMessage = "Update the active bar from the command line."
      return
    }
    if (plugin.pluginId === root.installHandoffPluginId) {
      root.statusMessage = "Wait until " + plugin.pluginName + " finishes installing."
      return
    }

    var needsConfirmation = action === "update" || action === "remove"
      || (action === "enable" && !plugin.firstParty)
      || (action === "enable" && root.isBarWidget(plugin))
    if (needsConfirmation) {
      root.pendingUpdateLocalCommit = action === "update" ? String(plugin.localCommit || "") : ""
      root.pendingUpdateRemoteCommit = action === "update" ? String(plugin.remoteCommit || "") : ""
      root.pendingManagedPlugin = plugin
      root.pendingAction = action
      root.pendingPlacement = "center"
      root.installConfirmOpen = true
      return
    }
    root.runManagementAction(action, plugin)
  }

  function confirmPendingAction() {
    if (root.pendingAction === "install") {
      root.confirmInstall()
      return
    }
    var action = root.pendingAction
    var plugin = root.pendingManagedPlugin
    root.installConfirmOpen = false
    root.pendingManagedPlugin = null
    root.pendingAction = ""
    if (!plugin || !MarketplaceModel.pluginIdIsSafe(plugin.pluginId)) return
    root.pendingValidatedAction = action
    root.pendingValidatedPluginId = plugin.pluginId
    root.statusMessage = "Checking current plugin state…"
    root.refreshInstalled()
  }

  function runManagementAction(action, plugin) {
    root.managingPluginId = plugin.pluginId
    root.managingPluginName = plugin.pluginName
    root.managingAction = action
    root.managementStdout = ""
    root.managementStderr = ""

    if (action === "enable") {
      var enableCmd = ["omarchy", "plugin", "enable", plugin.pluginId]
      if (root.isBarWidget(plugin)) {
        enableCmd.push("--section", root.pendingPlacement || "center")
      }
      managementProc.command = enableCmd
    }
    else if (action === "disable") managementProc.command = ["omarchy", "plugin", "disable", plugin.pluginId]
    else if (action === "update") {
      if (plugin.localCommit && plugin.remoteCommit) {
        managementProc.command = ["bash", root.pluginDir + "/plugin-update-checked",
          plugin.pluginId, plugin.localCommit, plugin.remoteCommit]
      } else {
        managementProc.command = ["omarchy", "plugin", "update", plugin.pluginId, "--yes"]
      }
    }
    else if (action === "remove") {
      managementProc.command = ["bash", root.pluginDir + "/plugin-remove-checked", plugin.pluginId]
    }
    else return

    root.statusMessage = (action === "update" ? "Updating " : action.charAt(0).toUpperCase() + action.slice(1) + " ")
      + plugin.pluginName + "…"
    managementProc.running = true
  }

  function confirmationMessage() {
    if (root.pendingAction === "install" && root.pendingPlugin)
      return "Install and enable " + root.pendingPlugin.pluginName + "?\n\nCommunity plugins run as unsandboxed code inside omarchy-shell. Continue only if you trust this repository."
    var plugin = root.pendingManagedPlugin
    if (!plugin) return ""
    if (root.pendingAction === "enable")
      return "Enable " + plugin.pluginName + "?\n\nThis third-party plugin will run inside omarchy-shell."
    if (root.pendingAction === "update")
      return "Update " + plugin.pluginName + " to the latest verified commit?\n\nFast-forward update will be applied automatically."
    if (root.pendingAction === "remove")
      return "Remove " + plugin.pluginName + "?\n\nInstalled plugin directory will be deleted."
    return ""
  }

  function confirmationButtonText() {
    if (root.pendingAction === "install") return "Install"
    if (root.pendingAction === "enable") return "Enable"
    if (root.pendingAction === "update") return "Update"
    if (root.pendingAction === "remove") return "Remove"
    return "Confirm"
  }

  function pluginReplacesBar(plugin) {
    var kind = String(plugin && plugin.kind || "").toLowerCase().trim()
    return kind === "bar" || kind === "full bar"
  }

  function isBarWidget(plugin) {
    if (!plugin) return false
    if (Array.isArray(plugin.kinds)) {
      return plugin.kinds.indexOf("bar-widget") !== -1 && plugin.kinds.indexOf("bar") === -1
    }
    var k = String(plugin.kind || "").toLowerCase().replace(/[\s_-]+/g, "-")
    return k === "bar-widget" || (k.indexOf("bar") !== -1 && k.indexOf("full") === -1 && k !== "bar")
  }

  // --------------------------------------------------------------------------
  // Timers & Background Processes
  // --------------------------------------------------------------------------
  Timer { id: rebuildTimer; interval: 35; onTriggered: root.rebuildDisplay() }
  Timer { id: managedRebuildTimer; interval: 35; onTriggered: root.rebuildManaged() }
  Timer { id: pendingInstallTimer; interval: 250; onTriggered: { if (MarketplaceSession.pendingInstallId) root.refreshInstalled() } }
  Timer {
    id: previewDebounceTimer
    interval: 80
    repeat: false
    onTriggered: {
      root.refreshPreview()
      if (root.rightTabMode === "readme") root.refreshReadme()
    }
  }

  // Instant local cache loader
  Process {
    id: localCacheProc
    command: ["cat", root.localCatalogPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (text && text.length > 100 && !root.catalogLoaded) root.loadCatalog(text)
      }
    }
  }

  // Remote catalog sync
  Process {
    id: catalogProc
    command: ["curl", "-fsS", "--max-time", "20", "--max-filesize", "16777216",
      "https://plugins.omarchy.org/catalog.json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (text && text.length > 100) {
          root.loadCatalog(text)
          // Update disk cache in background
          Util.execDetached("cat << 'EOF' > " + root.localCatalogPath + "\n" + text + "\nEOF")
        }
      }
    }
    onExited: function(code) {
      root.loading = false
      if (code !== 0 && !root.catalogLoaded) root.errorMessage = "Could not connect to plugins.omarchy.org."
    }
  }

  Process {
    id: engagementProc
    command: ["curl", "-fsS", "--max-time", "12", "https://api.omarchyplugins.com/v1/stats"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.loadEngagement(text)
    }
  }

  Process {
    id: installedProc
    command: ["omarchy", "plugin", "list", "--json"]
    stdout: StdioCollector { id: installedStdout; waitForEnd: true }
    onExited: function(code) {
      if (code === 0) root.loadInstalled(installedStdout.text)
      var act = root.pendingValidatedAction
      var id = root.pendingValidatedPluginId
      root.pendingValidatedAction = ""
      root.pendingValidatedPluginId = ""
      if (act && code === 0 && root.installedRequestParsed) {
        var pl = root.installedPluginById(id)
        if (pl) Qt.callLater(function() { root.runManagementAction(act, pl) })
      }
    }
  }

  Process {
    id: previewProc
    onExited: function(code) {
      var selectedSource = root.selectedPlugin ? String(root.selectedPlugin.previewImage || "") : ""
      if (root.previewActiveUrl !== selectedSource) {
        Qt.callLater(function() { root.refreshPreview() })
        return
      }
      if (code === 0 && root.previewTargetFile) {
        root.previewPath = root.previewTargetFile
      } else {
        root.previewPath = ""
      }
    }
  }

  Process {
    id: readmeProc
    stdout: StdioCollector { id: readmeStdout; waitForEnd: true }
    onExited: function(code) {
      root.loadingReadme = false
      var raw = String(readmeStdout.text || "").trim()
      root.currentReadmeText = raw ? raw : "*No README available for this plugin.*"
    }
  }

  Process {
    id: installProc
    stdout: StdioCollector { id: installOut; waitForEnd: true }
    stderr: StdioCollector { id: installErr; waitForEnd: true }
    onExited: function(code) {
      if (code === 0) {
        root.statusMessage = (root.installingPluginName || root.installingPluginId) + " installed. Discovered in registry…"
        MarketplaceSession.pendingInstallStage = "discovering"
        pendingInstallTimer.restart()
      } else {
        root.failedPluginId = root.installingPluginId
        var err = String(installErr.text || installOut.text || "").trim()
        root.statusMessage = "Install failed: " + (err.length > 120 ? err.slice(0, 117) + "…" : err)
        root.clearInstallHandoff()
      }
      root.installingPluginId = ""
      root.installingPluginName = ""
    }
  }

  Process {
    id: managementProc
    stdout: StdioCollector { id: mgmtOut; waitForEnd: true }
    stderr: StdioCollector { id: mgmtErr; waitForEnd: true }
    onExited: function(code) {
      var act = root.managingAction
      var name = root.managingPluginName
      root.managingPluginId = ""
      root.managingPluginName = ""
      root.managingAction = ""
      if (code === 0) {
        root.statusMessage = name + " " + (act === "remove" ? "removed" : act + "d") + " successfully."
        root.refreshInstalled()
      } else {
        var err = String(mgmtErr.text || mgmtOut.text || "").trim()
        root.statusMessage = "Action failed: " + (err.length > 120 ? err.slice(0, 117) + "…" : err)
        root.refreshInstalled()
      }
    }
  }

  Process {
    id: updateCheckProc
    stdout: StdioCollector { id: updateCheckOut; waitForEnd: true }
    onExited: function(code) {
      if (code === 0) root.loadUpdateStatus(updateCheckOut.text)
    }
  }

  Process {
    id: gitProbeProc
    onExited: function(code) {
      if (root.activeGitProbeGeneration === root.gitProbeGeneration && root.probingPluginId) {
        root.gitManagedIds[root.probingPluginId] = (code === 0)
        root.rebuildManaged()
      }
      root.probingPluginId = ""
      root.startNextGitProbe()
    }
  }

  Process { id: postInstallRescanProc; command: ["omarchy-shell", "shell", "rescanPlugins"] }
  Process { id: postInstallPresenceProc }
  Process { id: postInstallEnableProc }
  Process { id: installReceiptCleanupProc }
  Process { id: copyCmdProc }
  Process { id: openBrowserProc }
  Process {
    id: restartShellProc
    command: ["omarchy-restart-shell"]
    onExited: function(code) {
      if (code === 0) root.statusMessage = "Omarchy shell restarted."
      else root.statusMessage = "Failed to restart shell."
    }
  }

  // --------------------------------------------------------------------------
  // Main Overlay Surface UI
  // --------------------------------------------------------------------------
  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.namespace: "omarchy-market"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (root.opened && !root.operationRunning && !root.installBusy)
      ? WlrKeyboardFocus.Exclusive
      : (root.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
    exclusionMode: ExclusionMode.Ignore

    // Dark Scrim background with smooth fade
    Rectangle {
      anchors.fill: parent
      color: root.scrim
      opacity: 0.94
    }

    // Click outside modal card to close
    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    // Centered Modal Window Card
    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      anchors.centerIn: parent
      color: root.background
      borderSpec: Border.surfaceSpec("menu", "border", root.border, Math.max(1, Style.normalBorderWidth))
      radius: Style.cornerRadius
      clip: true

      // Intercept clicks inside card
      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      // Keyboard handler
      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (root.installConfirmOpen) {
            if (event.key === Qt.Key_Escape) {
              root.cancelInstall()
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              var cmd = root.currentPendingCommand()
              root.cancelInstall()
              root.runInTerminal(cmd)
              event.accepted = true
            }
            return
          }
          if (managementDropdown.popupOpen) return

          if (event.key === Qt.Key_Escape) {
            if (searchField && searchField.activeFocus && searchField.text) searchField.clear()
            else root.dismiss()
            event.accepted = true
          } else if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_1) { root.setView("browse"); event.accepted = true }
            else if (event.key === Qt.Key_2) { root.setView("manage"); event.accepted = true }
            else if (event.key === Qt.Key_3) { root.setView("updates"); event.accepted = true }
            else if (event.key === Qt.Key_C && root.selectedPlugin) {
              root.copyInstallCommand(root.selectedPlugin)
              event.accepted = true
            }
          } else if (event.key === Qt.Key_Up) {
            root.selectRelative(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.selectRelative(1)
            event.accepted = true
          }
        }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset + Style.space(8)
        anchors.rightMargin: card.contentRightInset + Style.space(12)
        anchors.bottomMargin: card.contentBottomInset + Style.space(8)
        anchors.leftMargin: card.contentLeftInset + Style.space(12)
        spacing: Style.space(10)

        // --------------------------------------------------------------------
        // Top Header: Title, Tabs & Refresh
        // --------------------------------------------------------------------
        Row {
          width: parent.width
          height: Style.space(40)
          spacing: Style.space(12)

          // App Title + Status
          Row {
            width: parent.width - viewTabsRow.width - headerActions.width - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(10)

            Rectangle {
              width: Style.space(34)
              height: Style.space(34)
              radius: Style.space(8)
              color: Util.alpha(root.accent, 0.16)
              anchors.verticalCenter: parent.verticalCenter

              Text {
                anchors.centerIn: parent
                text: "🛍️"
                font.pixelSize: Style.space(18)
              }
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              spacing: 0

              Text {
                text: "OMARCHY MARKET"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: root.titleFontSize
                font.bold: true
              }
              Text {
                text: root.viewMode === "browse"
                  ? (root.catalogLoaded ? root.displayRows.length + " community plugins" : "Connecting to registry…")
                  : root.viewMode === "manage"
                    ? root.managedRows.length + " installed plugins"
                    : (root.updateCount > 0 ? root.updateCount + " updates available" : "All plugins up to date")
                color: root.foreground
                opacity: 0.6
                font.family: root.fontFamily
                font.pixelSize: root.captionFontSize
              }
            }
          }

          // View Mode Tabs (Browse / Manage / Updates)
          Row {
            id: viewTabsRow
            anchors.verticalCenter: parent.verticalCenter
            height: Style.space(32)
            spacing: Style.space(6)

            Button {
              text: "Browse"
              height: parent.height
              bordered: true
              focusable: true
              selected: root.viewMode === "browse"
              foreground: root.foreground
              accent: root.accent
              fontSize: root.smallFontSize
              onClicked: root.setView("browse")
            }
            Button {
              text: "Manage"
              height: parent.height
              bordered: true
              focusable: true
              selected: root.viewMode === "manage"
              foreground: root.foreground
              accent: root.accent
              fontSize: root.smallFontSize
              onClicked: root.setView("manage")
            }
            Button {
              text: "Updates (" + root.updateCount + ")"
              height: parent.height
              bordered: true
              focusable: true
              selected: root.viewMode === "updates"
              foreground: root.updateCount > 0 ? root.accent : root.foreground
              accent: root.accent
              fontSize: root.smallFontSize
              onClicked: root.setView("updates")
            }
          }

          // Header Actions: Restart Shell & Refresh
          Row {
            id: headerActions
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Button {
              id: restartShellButton
              anchors.verticalCenter: parent.verticalCenter
              text: restartShellProc.running ? "Restarting…" : "Restart Shell"
              height: Style.space(32)
              bordered: true
              focusable: true
              enabled: !restartShellProc.running
              foreground: root.foreground
              accent: root.accent
              fontSize: root.smallFontSize
              onClicked: {
                root.statusMessage = "Restarting Omarchy shell…"
                restartShellProc.running = true
              }
            }

            Button {
              id: refreshButton
              anchors.verticalCenter: parent.verticalCenter
              text: root.loading || installedProc.running || updateCheckProc.running ? "Refreshing…" : "Refresh"
              height: Style.space(32)
              bordered: true
              focusable: true
              enabled: !root.operationRunning
              foreground: root.foreground
              accent: root.accent
              fontSize: root.smallFontSize
              onClicked: {
                if (root.viewMode === "browse") {
                  root.refreshCatalog()
                  root.refreshInstalled()
                } else root.refreshInstalled()
              }
            }
          }
        }

        // --------------------------------------------------------------------
        // Search & Filter Toolbar
        // --------------------------------------------------------------------
        Row {
          width: parent.width
          height: Style.space(38)
          spacing: Style.space(10)

          TextField {
            id: searchField
            width: root.viewMode === "browse" ? Math.max(Style.space(160), parent.width - sortBar.implicitWidth - parent.spacing)
              : (root.viewMode === "manage" ? parent.width - managementDropdown.width - parent.spacing : parent.width)
            height: parent.height
            placeholderText: root.viewMode === "browse"
              ? "Search 5,450+ plugins by name, tags, description, or author… (Esc to clear)"
              : (root.viewMode === "manage" ? "Filter installed plugins by name, id, or type…" : "Search available updates…")
            foreground: root.foreground
            accent: root.accent
            font.pixelSize: root.bodyFontSize
            onTextChanged: {
              MarketplaceSession.searchText = text
              if (root.viewMode === "browse" && root.catalogLoaded) root.scheduleRebuild()
              else if (root.viewMode !== "browse" && root.installedLoaded) root.scheduleManagedRebuild()
            }
            Keys.onDownPressed: root.selectRelative(1)
            Keys.onUpPressed: root.selectRelative(-1)
          }

          Row {
            id: sortBar
            visible: root.viewMode === "browse"
            height: parent.height
            spacing: Style.space(4)

            Repeater {
              model: root.sortButtons
              delegate: Button {
                required property var modelData
                height: parent.height
                bordered: true
                focusable: false
                horizontalPadding: Style.space(8)
                selected: root.sortMode === modelData.id
                foreground: root.foreground
                accent: root.accent
                fontSize: root.captionFontSize
                text: {
                  var base = modelData.label
                  if (root.sortMode === modelData.id) {
                    return base + (root.sortAscending ? " ↑" : " ↓")
                  }
                  return base
                }
                tooltipText: {
                  if (root.sortMode === modelData.id) {
                    return root.sortAscending ? modelData.ascTip : modelData.descTip
                  }
                  return modelData.defaultTip
                }
                onClicked: root.toggleSort(modelData.id)
              }
            }
          }

          Dropdown {
            id: managementDropdown
            visible: root.viewMode === "manage"
            width: Style.space(170)
            height: parent.height
            options: root.managementOptions
            value: root.managementFilter
            foreground: root.foreground
            accent: root.accent
            onChanged: function(val) { root.setManagementFilter(val) }
          }
        }

        // Category Filter Chips (Browse mode only)
        Row {
          visible: root.viewMode === "browse"
          width: parent.width
          height: Style.space(26)
          spacing: Style.space(6)

          Repeater {
            model: root.categoryChips
            delegate: Button {
              required property var modelData
              text: modelData.label
              height: parent.height
              bordered: true
              focusable: false
              selected: root.categoryFilter === modelData.id
              foreground: root.foreground
              accent: root.accent
              fontSize: root.captionFontSize
              onClicked: root.setCategory(modelData.id)
            }
          }
        }

        // --------------------------------------------------------------------
        // Main Content Area
        // --------------------------------------------------------------------
        Item {
          width: parent.width
          height: parent.height - Style.space(136) - (root.viewMode === "browse" ? Style.space(32) : 0)

          // ------------------------------------------------------------------
          // VIEW: Browse (Split Pane)
          // ------------------------------------------------------------------
          Row {
            visible: root.viewMode === "browse"
            anchors.fill: parent
            spacing: Style.space(14)

            // Left: Plugin List
            Item {
              id: pluginListPane
              width: Math.round((parent.width - parent.spacing) * 0.45)
              height: parent.height

              ListView {
                id: pluginList
                anchors.fill: parent
                model: root.displayRows
                clip: true
                spacing: Style.space(4)
                boundsBehavior: Flickable.StopAtBounds

                delegate: BorderSurface {
                  id: pluginRow
                  required property int index
                  required property var modelData

                  readonly property bool selectedRow: index === root.selectedIndex
                  width: ListView.view.width
                  height: Style.space(86)
                  color: selectedRow ? root.selectedBackground : "transparent"
                  borderSpec: selectedRow
                    ? Border.flat(root.accent, Math.max(1, Style.normalBorderWidth))
                    : Border.none()
                  radius: Style.cornerRadius

                  Column {
                    anchors.fill: parent
                    anchors.margins: Style.space(10)
                    spacing: Style.space(3)

                    Row {
                      width: parent.width
                      spacing: Style.space(8)

                      Text {
                        width: parent.width - statusBadge.width - parent.spacing
                        text: String(pluginRow.modelData.pluginName || "")
                        color: pluginRow.selectedRow ? root.accent : root.foreground
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: root.bodyFontSize + 1
                        font.bold: true
                      }

                      BorderSurface {
                        id: statusBadge
                        width: badgeText.implicitWidth + Style.space(12)
                        height: Style.space(20)
                        color: pluginRow.modelData.installed
                          ? Util.alpha(Color.accent, 0.2)
                          : (pluginRow.modelData.verificationStatus === "verified"
                            ? Util.alpha(root.accent, 0.16)
                            : Util.alpha(root.foreground, 0.05))
                        borderSpec: Border.none()
                        radius: Style.space(4)

                        Text {
                          id: badgeText
                          anchors.centerIn: parent
                          text: pluginRow.modelData.installed ? "INSTALLED" : pluginRow.modelData.verificationStatus.toUpperCase()
                          color: pluginRow.modelData.installed || pluginRow.modelData.verificationStatus === "verified"
                            ? root.accent : root.foreground
                          opacity: pluginRow.modelData.installed || pluginRow.modelData.verificationStatus === "verified" ? 1 : 0.45
                          font.family: root.fontFamily
                          font.pixelSize: root.captionFontSize - 1
                          font.bold: true
                        }
                      }
                    }

                    Text {
                      width: parent.width
                      text: String(pluginRow.modelData.description || "")
                      color: root.foreground
                      opacity: 0.72
                      elide: Text.ElideRight
                      font.family: root.fontFamily
                      font.pixelSize: root.smallFontSize
                    }

                    Row {
                      width: parent.width
                      spacing: Style.space(8)

                      Text {
                        width: Math.max(0, parent.width - metricsText.implicitWidth - parent.spacing)
                        text: "@" + pluginRow.modelData.author + "  ·  " + pluginRow.modelData.kind
                        color: root.foreground
                        opacity: 0.52
                        elide: Text.ElideRight
                        font.family: root.fontFamily
                        font.pixelSize: root.captionFontSize
                      }

                      Text {
                        id: metricsText
                        text: {
                          var m = "★ " + pluginRow.modelData.starsText
                          if (pluginRow.modelData.copiesText && pluginRow.modelData.copiesText !== "—")
                            m += "  📥 " + pluginRow.modelData.copiesText
                          if (pluginRow.modelData.viewsText && pluginRow.modelData.viewsText !== "—")
                            m += "  👁 " + pluginRow.modelData.viewsText
                          return m
                        }
                        color: root.foreground
                        opacity: 0.65
                        font.family: root.fontFamily
                        font.pixelSize: root.captionFontSize
                      }
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.select(pluginRow.index)
                    onClicked: root.select(pluginRow.index)
                  }
                }
              }

              Text {
                visible: root.displayRows.length === 0 && !root.loading
                anchors.centerIn: parent
                text: "No plugins found matching criteria."
                color: root.foreground
                opacity: 0.5
                font.family: root.fontFamily
                font.pixelSize: root.bodyFontSize
              }
            }

            // Divider Line
            Rectangle {
              width: Math.max(1, Style.normalBorderWidth)
              height: parent.height
              color: Util.alpha(root.border, 0.3)
            }

            // Right: Detail & README Pane
            Item {
              id: detailPane
              width: parent.width - pluginListPane.width - parent.spacing * 2
              height: parent.height

              Column {
                anchors.fill: parent
                spacing: Style.space(10)

                // Sub-tab switcher: Overview vs README
                Row {
                  width: parent.width
                  height: Style.space(32)
                  spacing: Style.space(8)

                  Button {
                    text: "Overview & Setup"
                    height: parent.height
                    bordered: true
                    selected: root.rightTabMode === "overview"
                    foreground: root.foreground
                    accent: root.accent
                    fontSize: root.smallFontSize
                    onClicked: root.rightTabMode = "overview"
                  }
                  Button {
                    text: "README Viewer"
                    height: parent.height
                    bordered: true
                    selected: root.rightTabMode === "readme"
                    foreground: root.foreground
                    accent: root.accent
                    fontSize: root.smallFontSize
                    onClicked: {
                      root.rightTabMode = "readme"
                      root.refreshReadme()
                    }
                  }
                }

                // ------------------------------------------------------------
                // Pane Sub-View: Overview
                // ------------------------------------------------------------
                Flickable {
                  visible: root.rightTabMode === "overview" && root.selectedPlugin !== null
                  width: parent.width
                  height: parent.height - Style.space(42)
                  contentWidth: width
                  contentHeight: overviewContentCol.implicitHeight
                  clip: true
                  boundsBehavior: Flickable.StopAtBounds

                  Column {
                    id: overviewContentCol
                    width: parent.width
                    spacing: Style.space(10)

                    // Optional preview thumbnail
                    BorderSurface {
                      id: previewFrame
                      visible: detailPreview.status === Image.Ready
                      readonly property bool portraitImage: detailPreview.status === Image.Ready
                        && detailPreview.sourceSize.height > detailPreview.sourceSize.width * 1.15
                      width: parent.width
                      height: visible ? (portraitImage
                        ? Math.min(Style.space(380), detailPane.height * 0.55)
                        : Math.min(Style.space(260), detailPane.height * 0.4)) : 0
                      color: Util.alpha(root.foreground, 0.035)
                      borderSpec: Border.flat(Util.alpha(root.border, 0.25), Math.max(1, Style.normalBorderWidth))
                      radius: Style.cornerRadius
                      clip: true

                      Image {
                        id: detailPreview
                        anchors.fill: parent
                        anchors.margins: Style.space(8)
                        source: root.previewPath ? ("file://" + root.previewPath) : (root.selectedPlugin ? String(root.selectedPlugin.previewImage || "") : "")
                        visible: source.toString() !== ""
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectFit
                      }
                    }

                    // Title & Badges
                    Row {
                      width: parent.width
                      spacing: Style.space(10)

                      Text {
                        width: parent.width - badgeRow.width - parent.spacing
                        text: root.selectedPlugin ? root.selectedPlugin.pluginName : ""
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: root.headingFontSize
                        font.bold: true
                        wrapMode: Text.WordWrap
                      }

                      Row {
                        id: badgeRow
                        spacing: Style.space(6)

                        // Stars Badge
                        BorderSurface {
                          visible: root.selectedPlugin && root.selectedPlugin.starsText !== "—"
                          width: starsBadgeText.implicitWidth + Style.space(12)
                          height: Style.space(24)
                          color: Util.alpha(root.foreground, 0.06)
                          borderSpec: Border.none()
                          radius: Style.space(4)
                          Text {
                            id: starsBadgeText
                            anchors.centerIn: parent
                            text: root.selectedPlugin ? "★ " + root.selectedPlugin.starsText : ""
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: root.captionFontSize
                          }
                        }

                        // Downloads / Installs Badge
                        BorderSurface {
                          visible: root.selectedPlugin && root.selectedPlugin.copiesText && root.selectedPlugin.copiesText !== "—"
                          width: copiesBadgeText.implicitWidth + Style.space(12)
                          height: Style.space(24)
                          color: Util.alpha(root.accent, 0.12)
                          borderSpec: Border.none()
                          radius: Style.space(4)
                          Text {
                            id: copiesBadgeText
                            anchors.centerIn: parent
                            text: root.selectedPlugin ? "📥 " + root.selectedPlugin.copiesText : ""
                            color: root.accent
                            font.family: root.fontFamily
                            font.pixelSize: root.captionFontSize
                            font.bold: true
                          }
                        }

                        // Verification Badge
                        BorderSurface {
                          width: detailBadgeText.implicitWidth + Style.space(14)
                          height: Style.space(24)
                          color: root.selectedPlugin && root.selectedPlugin.verificationStatus === "verified"
                            ? Util.alpha(root.accent, 0.16) : Util.alpha(root.foreground, 0.06)
                          borderSpec: Border.none()
                          radius: Style.space(4)
                          Text {
                            id: detailBadgeText
                            anchors.centerIn: parent
                            text: root.selectedPlugin ? root.selectedPlugin.verificationStatus.toUpperCase() : ""
                            color: root.selectedPlugin && root.selectedPlugin.verificationStatus === "verified" ? root.accent : root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: root.captionFontSize
                          }
                        }
                      }
                    }

                    // Meta: Author & Category
                    Text {
                      width: parent.width
                      text: root.selectedPlugin
                        ? "by " + root.selectedPlugin.author + "  ·  " + root.selectedPlugin.kind + "  ·  " + root.selectedPlugin.category
                        : ""
                      color: root.foreground
                      opacity: 0.65
                      font.family: root.fontFamily
                      font.pixelSize: root.smallFontSize
                    }

                    // Full Description
                    Text {
                      width: parent.width
                      text: root.selectedPlugin ? root.selectedPlugin.description : ""
                      color: root.foreground
                      opacity: 0.85
                      wrapMode: Text.WordWrap
                      font.family: root.fontFamily
                      font.pixelSize: root.bodyFontSize
                    }

                    // Tags
                    Text {
                      width: parent.width
                      visible: root.selectedPlugin && root.selectedPlugin.tagsText !== ""
                      text: root.selectedPlugin ? "Tags: " + root.selectedPlugin.tagsText : ""
                      color: root.accent
                      font.family: root.fontFamily
                      font.pixelSize: root.captionFontSize
                      wrapMode: Text.WordWrap
                    }

                    // Install Note
                    Text {
                      width: parent.width
                      visible: root.selectedPlugin && root.selectedPlugin.installNote !== ""
                      text: root.selectedPlugin ? "Note: " + root.selectedPlugin.installNote : ""
                      color: root.foreground
                      opacity: 0.6
                      font.family: root.fontFamily
                      font.pixelSize: root.captionFontSize
                      wrapMode: Text.WordWrap
                    }

                    Item { width: 1; height: Style.space(4) }

                    // Action Buttons Flow (wraps cleanly to avoid clipping)
                    Flow {
                      width: parent.width
                      spacing: Style.space(8)

                      readonly property var instPlugin: root.selectedPlugin ? root.installedPluginById(root.selectedPlugin.pluginId) : null
                      readonly property var updateInfo: root.selectedPlugin ? root.updateStatusById[root.selectedPlugin.pluginId] : null

                      // 1. Install & Enable (when not installed)
                      Button {
                        visible: !root.selectedPlugin || !root.selectedPlugin.installed
                        text: root.selectedPlugin && root.selectedPlugin.pluginId === root.installingPluginId
                          ? "Installing…" : "Install & Enable"
                        bordered: true
                        selected: true
                        enabled: root.selectedPlugin && !root.installBusy
                        foreground: root.foreground
                        accent: root.accent
                        fontSize: root.smallFontSize
                        onClicked: if (root.selectedPlugin) root.requestInstall(root.selectedPlugin)
                      }

                      // 2. Enable / Disable Toggle (when installed)
                      Button {
                        visible: root.selectedPlugin && root.selectedPlugin.installed && parent.instPlugin !== null && parent.instPlugin.canDisable !== false
                        text: parent.instPlugin && parent.instPlugin.enabled ? "Disable" : "Enable"
                        bordered: true
                        selected: parent.instPlugin && !parent.instPlugin.enabled
                        enabled: !root.operationRunning
                        foreground: root.foreground
                        accent: root.accent
                        fontSize: root.smallFontSize
                        onClicked: {
                          if (parent.instPlugin) root.requestManagementAction(parent.instPlugin.enabled ? "disable" : "enable", parent.instPlugin)
                        }
                      }

                      // 3. Update Button (when update is available)
                      Button {
                        visible: root.selectedPlugin && root.selectedPlugin.installed && parent.instPlugin !== null && parent.updateInfo && parent.updateInfo.status === "available"
                        text: "Update"
                        bordered: true
                        selected: true
                        enabled: !root.operationRunning
                        foreground: root.foreground
                        accent: root.accent
                        fontSize: root.smallFontSize
                        onClicked: {
                          if (parent.instPlugin) {
                            var pWithCommits = Object.assign({}, parent.instPlugin, {
                              localCommit: String(parent.updateInfo.localCommit || ""),
                              remoteCommit: String(parent.updateInfo.remoteCommit || "")
                            })
                            root.requestManagementAction("update", pWithCommits)
                          }
                        }
                      }

                      // 4. Remove / Uninstall Button (when installed, third-party)
                      Button {
                        visible: root.selectedPlugin && root.selectedPlugin.installed && parent.instPlugin !== null && !parent.instPlugin.firstParty && parent.instPlugin.pluginId !== "waldseelen.market"
                        text: "Remove"
                        bordered: true
                        enabled: !root.operationRunning
                        foreground: Color.urgent
                        accent: Color.urgent
                        fontSize: root.smallFontSize
                        onClicked: {
                          if (parent.instPlugin) root.requestManagementAction("remove", parent.instPlugin)
                        }
                      }

                      // 5. View on GitHub
                      Button {
                        text: "🌐 View on GitHub"
                        bordered: true
                        foreground: root.foreground
                        accent: root.accent
                        fontSize: root.smallFontSize
                        onClicked: if (root.selectedPlugin) root.openGithubRepo(root.selectedPlugin)
                      }

                      // 6. View on Omarchy Website (Next to GitHub)
                      Button {
                        text: "🛍️ Omarchy Page"
                        bordered: true
                        foreground: root.foreground
                        accent: root.accent
                        fontSize: root.smallFontSize
                        onClicked: if (root.selectedPlugin) root.openOmarchyPluginPage(root.selectedPlugin)
                      }

                      // 7. Copy Command
                      Button {
                        text: "📋 Copy Command"
                        bordered: true
                        foreground: root.foreground
                        accent: root.accent
                        fontSize: root.smallFontSize
                        onClicked: if (root.selectedPlugin) root.copyInstallCommand(root.selectedPlugin)
                      }
                    }
                  }
                }

                // ------------------------------------------------------------
                // Pane Sub-View: README Viewer
                // ------------------------------------------------------------
                Item {
                  visible: root.rightTabMode === "readme" && root.selectedPlugin !== null
                  width: parent.width
                  height: parent.height - Style.space(42)

                  Column {
                    anchors.fill: parent
                    spacing: Style.space(8)

                    // Toolbar
                    Flow {
                      width: parent.width
                      spacing: Style.space(8)

                      Button {
                        text: "📋 Copy Install Command"
                        bordered: true
                        foreground: root.foreground
                        accent: root.accent
                        fontSize: root.captionFontSize
                        onClicked: if (root.selectedPlugin) root.copyInstallCommand(root.selectedPlugin)
                      }

                      Button {
                        text: "🌐 Open on GitHub"
                        bordered: true
                        foreground: root.foreground
                        accent: root.accent
                        fontSize: root.captionFontSize
                        onClicked: if (root.selectedPlugin) root.openGithubRepo(root.selectedPlugin)
                      }

                      Button {
                        text: "🛍️ Omarchy Page"
                        bordered: true
                        foreground: root.foreground
                        accent: root.accent
                        fontSize: root.captionFontSize
                        onClicked: if (root.selectedPlugin) root.openOmarchyPluginPage(root.selectedPlugin)
                      }

                      Button {
                        text: root.loadingReadme ? "Loading…" : "🔄 Refresh"
                        bordered: true
                        foreground: root.foreground
                        accent: root.accent
                        fontSize: root.captionFontSize
                        onClicked: root.refreshReadme()
                      }
                    }

                    // Markdown Container
                    BorderSurface {
                      width: parent.width
                      height: parent.height - Style.space(36)
                      color: Util.alpha(root.foreground, 0.025)
                      borderSpec: Border.flat(Util.alpha(root.border, 0.25), Math.max(1, Style.normalBorderWidth))
                      radius: Style.cornerRadius
                      padding: Style.space(12)

                      Flickable {
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: readmeTextItem.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Text {
                          id: readmeTextItem
                          width: parent.width
                          text: root.currentReadmeText
                          color: root.foreground
                          wrapMode: Text.WordWrap
                          font.family: "monospace"
                          font.pixelSize: root.smallFontSize
                          lineHeight: 1.25
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          // ------------------------------------------------------------------
          // VIEW: Manage Installed Plugins
          // ------------------------------------------------------------------
          Item {
            visible: root.viewMode === "manage"
            anchors.fill: parent

            Item {
              id: managedPane
              anchors.fill: parent
              readonly property real rowMargin: Style.space(16)
              readonly property real tableInnerWidth: Math.max(100, width - rowMargin * 2)
              readonly property real colActions: Style.space(260)
              readonly property real colStatus: Style.space(85)
              readonly property real colSource: Style.space(80)
              readonly property real colType: Style.space(100)
              readonly property real colPlugin: Math.max(Style.space(150), tableInnerWidth - colActions - colStatus - colSource - colType)

              // Table Header
              Rectangle {
                id: mgmtHeader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Style.space(32)
                color: Util.alpha(root.foreground, 0.04)

                Row {
                  anchors.fill: parent
                  anchors.leftMargin: managedPane.rowMargin
                  anchors.rightMargin: managedPane.rowMargin

                  Text {
                    width: managedPane.colPlugin
                    anchors.verticalCenter: parent.verticalCenter
                    text: "PLUGIN"
                    color: root.foreground
                    opacity: 0.5
                    font.family: root.fontFamily
                    font.pixelSize: root.captionFontSize
                    font.bold: true
                  }
                  Text {
                    width: managedPane.colType
                    anchors.verticalCenter: parent.verticalCenter
                    text: "TYPE"
                    color: root.foreground
                    opacity: 0.5
                    font.family: root.fontFamily
                    font.pixelSize: root.captionFontSize
                    font.bold: true
                  }
                  Text {
                    width: managedPane.colSource
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SOURCE"
                    color: root.foreground
                    opacity: 0.5
                    font.family: root.fontFamily
                    font.pixelSize: root.captionFontSize
                    font.bold: true
                  }
                  Text {
                    width: managedPane.colStatus
                    anchors.verticalCenter: parent.verticalCenter
                    text: "STATUS"
                    color: root.foreground
                    opacity: 0.5
                    font.family: root.fontFamily
                    font.pixelSize: root.captionFontSize
                    font.bold: true
                  }
                  Text {
                    width: managedPane.colActions
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ACTIONS"
                    color: root.foreground
                    opacity: 0.5
                    horizontalAlignment: Text.AlignRight
                    font.family: root.fontFamily
                    font.pixelSize: root.captionFontSize
                    font.bold: true
                  }
                }
              }

              // List
              ListView {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: mgmtHeader.bottom
                anchors.bottom: parent.bottom
                model: root.managedRows
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                  id: mRow
                  required property int index
                  required property var modelData

                  width: ListView.view.width
                  height: Style.space(56)
                  color: index % 2 === 0 ? Util.alpha(root.foreground, 0.015) : "transparent"

                  Row {
                    anchors.fill: parent
                    anchors.leftMargin: managedPane.rowMargin
                    anchors.rightMargin: managedPane.rowMargin

                    Column {
                      width: managedPane.colPlugin
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: Style.space(2)
                      Text {
                        text: String(mRow.modelData.pluginName || "")
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: root.bodyFontSize
                        font.bold: true
                        elide: Text.ElideRight
                      }
                      Text {
                        text: String(mRow.modelData.pluginId || "")
                        color: root.foreground
                        opacity: 0.45
                        font.family: root.fontFamily
                        font.pixelSize: root.captionFontSize
                        elide: Text.ElideRight
                      }
                    }

                    Text {
                      width: managedPane.colType
                      anchors.verticalCenter: parent.verticalCenter
                      text: String(mRow.modelData.kindsText || "Plugin")
                      color: root.foreground
                      opacity: 0.6
                      font.family: root.fontFamily
                      font.pixelSize: root.captionFontSize
                    }

                    Text {
                      width: managedPane.colSource
                      anchors.verticalCenter: parent.verticalCenter
                      text: mRow.modelData.firstParty ? "Built-in" : (root.gitManagedIds[mRow.modelData.pluginId] ? "Git" : "Manual")
                      color: root.foreground
                      opacity: 0.6
                      font.family: root.fontFamily
                      font.pixelSize: root.captionFontSize
                    }

                    Text {
                      width: managedPane.colStatus
                      anchors.verticalCenter: parent.verticalCenter
                      text: mRow.modelData.enabled ? "ENABLED" : "DISABLED"
                      color: mRow.modelData.enabled ? root.accent : root.foreground
                      opacity: mRow.modelData.enabled ? 1 : 0.45
                      font.family: root.fontFamily
                      font.pixelSize: root.captionFontSize
                      font.bold: true
                    }

                    Item {
                      width: managedPane.colActions
                      height: parent.height

                      Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.space(6)

                        Button {
                          visible: mRow.modelData.pluginId !== "waldseelen.market" && (!mRow.modelData.enabled || mRow.modelData.canDisable)
                          text: mRow.modelData.enabled ? "Disable" : "Enable"
                          height: Style.space(28)
                          bordered: true
                          selected: !mRow.modelData.enabled
                          foreground: root.foreground
                          accent: root.accent
                          fontSize: root.captionFontSize
                          onClicked: root.requestManagementAction(mRow.modelData.enabled ? "disable" : "enable", mRow.modelData)
                        }

                        Button {
                          visible: !mRow.modelData.firstParty && mRow.modelData.pluginId !== "waldseelen.market" && root.gitManagedIds[mRow.modelData.pluginId] === true
                          text: "Update"
                          height: Style.space(28)
                          bordered: true
                          foreground: root.foreground
                          accent: root.accent
                          fontSize: root.captionFontSize
                          onClicked: root.requestManagementAction("update", mRow.modelData)
                        }

                        Button {
                          visible: !mRow.modelData.firstParty && mRow.modelData.pluginId !== "waldseelen.market"
                          text: "Remove"
                          height: Style.space(28)
                          bordered: true
                          foreground: Color.urgent
                          accent: Color.urgent
                          fontSize: root.captionFontSize
                          onClicked: root.requestManagementAction("remove", mRow.modelData)
                        }
                      }
                    }
                  }

                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Math.max(1, Style.normalBorderWidth)
                    color: Util.alpha(root.border, 0.2)
                  }
                }
              }
            }
          }

          // ------------------------------------------------------------------
          // VIEW: Updates View
          // ------------------------------------------------------------------
          Item {
            visible: root.viewMode === "updates"
            anchors.fill: parent

            Column {
              anchors.fill: parent
              spacing: Style.space(12)

              ListView {
                width: parent.width
                height: parent.height - Style.space(40)
                model: root.updateRows
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: BorderSurface {
                  id: uRow
                  required property int index
                  required property var modelData

                  width: ListView.view.width
                  height: Style.space(64)
                  color: Util.alpha(root.foreground, 0.02)
                  borderSpec: Border.flat(Util.alpha(root.border, 0.25), Math.max(1, Style.normalBorderWidth))
                  radius: Style.cornerRadius

                  Row {
                    anchors.fill: parent
                    anchors.leftMargin: Style.space(12)
                    anchors.rightMargin: Style.space(12)

                    Column {
                      width: parent.width - updateBtn.width - Style.space(20)
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: Style.space(2)

                      Text {
                        text: String(uRow.modelData.pluginName || "")
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: root.bodyFontSize
                        font.bold: true
                      }

                      Text {
                        text: String(uRow.modelData.pluginId || "") + "  ·  "
                          + MarketplaceModel.shortCommit(uRow.modelData.localCommit) + " → "
                          + MarketplaceModel.shortCommit(uRow.modelData.remoteCommit)
                        color: root.accent
                        font.family: root.fontFamily
                        font.pixelSize: root.captionFontSize
                      }
                    }

                    Button {
                      id: updateBtn
                      anchors.verticalCenter: parent.verticalCenter
                      text: "Update Now"
                      height: Style.space(32)
                      bordered: true
                      selected: true
                      foreground: root.foreground
                      accent: root.accent
                      fontSize: root.smallFontSize
                      onClicked: root.requestManagementAction("update", uRow.modelData)
                    }
                  }
                }
              }

              Text {
                visible: root.updateRows.length === 0
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 40
                bottomPadding: 40
                text: updateCheckProc.running ? "Checking Git repositories for updates…" : "All installed community plugins are up to date!"
                color: root.foreground
                opacity: 0.6
                font.family: root.fontFamily
                font.pixelSize: root.titleFontSize
              }
            }
          }
        }

        // --------------------------------------------------------------------
        // Footer Bar: Status & Shortcuts
        // --------------------------------------------------------------------
        Row {
          width: parent.width
          height: Style.space(22)
          spacing: Style.space(12)

          Text {
            width: parent.width - shortcutsHelp.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: root.statusMessage || root.errorMessage || "Ready"
            color: root.statusMessage.indexOf("failed") !== -1 || root.errorMessage ? Color.urgent : root.foreground
            opacity: root.statusMessage || root.errorMessage ? 1 : 0.6
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: root.captionFontSize
          }

          Text {
            id: shortcutsHelp
            anchors.verticalCenter: parent.verticalCenter
            text: "Esc: Close  ·  ↑/↓: Walk  ·  Ctrl+1/2/3: Tabs  ·  Ctrl+C: Copy"
            color: root.foreground
            opacity: 0.45
            font.family: root.fontFamily
            font.pixelSize: root.captionFontSize
          }
        }
      }
    }

    // ------------------------------------------------------------------------
    // Action Confirmation & Choice Dialog (z: 100 overlay)
    // ------------------------------------------------------------------------
    Rectangle {
      id: confirmOverlay
      anchors.fill: parent
      visible: root.installConfirmOpen
      z: 100
      color: Util.alpha(Color.background, 0.8)

      // Prevent clicks from reaching card/background
      MouseArea {
        anchors.fill: parent
        onClicked: root.cancelInstall()
      }

      BorderSurface {
        id: confirmCard
        width: Math.min(parent.width - Style.space(32), Style.space(520))
        height: confirmContentCol.implicitHeight + Style.space(40)
        anchors.centerIn: parent
        color: root.background
        borderSpec: Border.surfaceSpec("menu", "border", root.pendingAction === "remove" ? Color.urgent : root.border, Math.max(1, Style.normalBorderWidth))
        radius: Style.cornerRadius
        clip: true

        MouseArea {
          anchors.fill: parent
          onClicked: {} // Intercept clicks inside card
        }

        Column {
          id: confirmContentCol
          width: confirmCard.width - Style.space(40)
          x: Style.space(20)
          y: Style.space(20)
          spacing: Style.space(12)

          // 1. Title & Icon
          Row {
            width: parent.width
            spacing: Style.space(10)

            Text {
              text: root.pendingAction === "remove" ? "🗑️"
                  : root.pendingAction === "update" ? "🔄"
                  : root.pendingAction === "enable" ? "⚡"
                  : "📦"
              font.pixelSize: Style.space(22)
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              width: parent.width - Style.space(34)
              anchors.verticalCenter: parent.verticalCenter
              spacing: 2

              Text {
                width: parent.width
                text: root.pendingAction === "install" ? "Install Plugin"
                    : root.pendingAction === "remove" ? "Remove Plugin"
                    : root.pendingAction === "update" ? "Update Plugin"
                    : root.pendingAction === "enable" ? "Enable Plugin"
                    : "Confirmation"
                color: root.pendingAction === "remove" ? Color.urgent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                visible: root.pendingPlugin !== null || root.pendingManagedPlugin !== null
                text: (root.pendingPlugin || root.pendingManagedPlugin ? (root.pendingPlugin || root.pendingManagedPlugin).pluginName : "")
                color: root.accent
                font.family: root.fontFamily
                font.pixelSize: root.smallFontSize
                elide: Text.ElideRight
              }
            }
          }

          // 2. Explanatory message
          Text {
            width: parent.width
            text: root.pendingPlugin || root.pendingManagedPlugin ? root.confirmationMessage() : ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: root.captionFontSize
            wrapMode: Text.WordWrap
            opacity: 0.8
            lineHeight: 1.25
          }

          // 3. Auto-Inserted CLI Command Box
          Column {
            width: parent.width
            spacing: Style.space(6)
            visible: root.currentPendingCommand() !== ""

            Text {
              text: root.pendingAction === "install" ? "Download / Run Command:" : "CLI Command:"
              color: root.foreground
              opacity: 0.85
              font.family: root.fontFamily
              font.pixelSize: root.captionFontSize
              font.bold: true
            }

            BorderSurface {
              width: parent.width
              height: Style.space(42)
              color: Util.alpha(Color.foreground, 0.05)
              borderSpec: Border.flat(Util.alpha(root.foreground, 0.25), 1)
              radius: Style.cornerRadius

              Row {
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(6)
                spacing: Style.space(6)

                Text {
                  id: cmdPreviewText
                  width: parent.width - copyCmdBtn.width - parent.spacing
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.currentPendingCommand()
                  color: root.accent
                  font.family: Style.font.monospaceFamily || "monospace"
                  font.pixelSize: root.captionFontSize
                  elide: Text.ElideMiddle
                }

                Button {
                  id: copyCmdBtn
                  anchors.verticalCenter: parent.verticalCenter
                  text: "📋 Copy"
                  bordered: true
                  height: Style.space(30)
                  fontSize: root.captionFontSize
                  onClicked: root.copyTextToClipboard(cmdPreviewText.text)
                }
              }
            }
          }

          // 4. Bar-Widget Placement Choice & Hint
          Column {
            width: parent.width
            spacing: Style.space(6)
            visible: (root.pendingAction === "install" || root.pendingAction === "enable") &&
                     root.isBarWidget(root.pendingPlugin || root.pendingManagedPlugin)

            Text {
              visible: root.pendingAction === "install"
              width: parent.width
              text: "💡 Section placement (Left / Center / Right) will be asked interactively in the terminal."
              color: root.accent
              opacity: 0.9
              font.family: root.fontFamily
              font.pixelSize: root.captionFontSize
              wrapMode: Text.WordWrap
            }

            Column {
              width: parent.width
              spacing: Style.space(6)
              visible: root.pendingAction === "enable"

              Text {
                text: "Bar Section Placement:"
                color: root.foreground
                opacity: 0.85
                font.family: root.fontFamily
                font.pixelSize: root.captionFontSize
                font.bold: true
              }

              Row {
                spacing: Style.space(8)

                Repeater {
                  model: [
                    { id: "left", label: "Left" },
                    { id: "center", label: "Center" },
                    { id: "right", label: "Right" }
                  ]

                  Button {
                    required property var modelData
                    text: modelData.label
                    bordered: true
                    selected: root.pendingPlacement === modelData.id
                    foreground: root.foreground
                    accent: root.accent
                    fontSize: root.captionFontSize
                    height: Style.space(30)
                    onClicked: root.pendingPlacement = modelData.id
                  }
                }
              }
            }
          }

          Item { width: 1; height: Style.space(4) }

          // 5. Action Buttons Row
          Row {
            anchors.right: parent.right
            spacing: Style.space(10)

            Button {
              text: "Cancel"
              height: Style.space(34)
              bordered: true
              foreground: root.foreground
              accent: root.accent
              fontSize: Style.font.caption
              onClicked: root.cancelInstall()
            }

            Button {
              visible: root.pendingAction !== "remove"
              text: "⚡ Background"
              height: Style.space(34)
              bordered: true
              foreground: root.foreground
              accent: root.accent
              fontSize: Style.font.caption
              onClicked: root.confirmPendingAction()
            }

            Button {
              text: root.pendingAction === "remove" ? "🗑️ Remove in Terminal"
                  : root.pendingAction === "update" ? "🔄 Update in Terminal"
                  : root.pendingAction === "enable" ? "⚡ Enable in Terminal"
                  : "🚀 Install in Terminal"
              height: Style.space(34)
              bordered: true
              selected: true
              foreground: root.pendingAction === "remove" ? Color.urgent : root.foreground
              accent: root.pendingAction === "remove" ? Color.urgent : root.accent
              fontSize: Style.font.caption
              onClicked: {
                var cmd = root.currentPendingCommand()
                root.cancelInstall()
                root.runInTerminal(cmd)
              }
            }
          }
        }
      }
    }
  }
}
