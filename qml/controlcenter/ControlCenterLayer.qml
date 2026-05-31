import QtQuick
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import IslandBackend

Item {
    id: controlCenter

    signal connectivityPanelRequested(string kind, bool open)

    readonly property var userConfig: UserConfig
    readonly property var configuredItems: userConfig.controlCenterItems || []
    readonly property bool showHeaderBattery: userConfig.showControlCenterBattery !== false
    readonly property bool showTray: hasControlCenterItem("tray")
    readonly property bool showWifi: hasControlCenterItem("wifi")
    readonly property bool showBluetooth: hasControlCenterItem("bluetooth")
    readonly property bool showTlp: hasControlCenterItem("tlp")
    readonly property bool showBrightness: hasControlCenterItem("brightness")
    readonly property bool showVolume: hasControlCenterItem("volume")
    readonly property var quickCardItems: orderedQuickCardItems()
    readonly property bool showQuickCards: quickCardItems.length > 0
    readonly property int configuredControlItemCount: (showTray ? 1 : 0)
        + (showWifi ? 1 : 0)
        + (showBluetooth ? 1 : 0)
        + (showTlp ? 1 : 0)
        + (showBrightness ? 1 : 0)
        + (showVolume ? 1 : 0)
    readonly property bool showDetailsDrawer: quickCardItems.length > 2

    property bool showCondition: false
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property var menuParentWindow: null
    // ... rest of properties ...

    scale: showCondition ? 1.0 : 0.12
    transformOrigin: Item.Top

    Behavior on scale {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuint
        }
    }
    property string currentTime: "00:00"
    property string currentDateLabel: ""
    property int batteryCapacity: 0
    property bool isCharging: false
    property real volumeLevel: -1
    property real brightnessLevel: -1
    property int sliderIntroDelay: 400
    property int currentWorkspace: 1
    property string currentTrack: ""
    property string currentArtist: ""

    property real localVolume: 0.5
    property real localBrightness: 0.5
    property real displayedVolume: 0.5
    property real displayedBrightness: 0.5
    property real pendingVolume: 0.5
    property real pendingBrightness: 0.5
    property real lastAppliedVolume: -1
    property real lastAppliedBrightness: -1
    property bool brightnessSetterRunning: false
    property bool volumeSetterRunning: false
    property bool sliderIntroPending: false
    property bool wifiPanelOpen: false
    property bool bluetoothPanelOpen: false
    property bool detailsDrawerOpen: false
    property bool detailsDrawerDragging: false
    property real detailsDrawerProgress: 0
    property bool detailsDrawerSettling: false
    readonly property bool detailsDrawerMoving: detailsDrawerDragging
        || detailsDrawerSettling
        || detailsDrawerProgressAnimation.running
    property bool batteryModeBusy: false
    property bool batteryModeStateRunning: false
    property bool batteryModeSetterRunning: false
    property bool batteryModeSliderDragging: false
    property bool batteryTlpAvailable: false
    property bool batteryTlpChecked: false
    property int batteryModeIndex: 1
    property int batteryModeAppliedIndex: 1
    property int batteryModePendingIndex: 1
    property real batteryModeDragOffset: 0
    property string batteryModeInfoMessage: ""
    property string batteryModeError: ""
    property string batteryModeLastCommandOutput: ""
    property int batteryModeRefreshPollsRemaining: 0

    property string wifiLocalInfoMessage: ""
    property string wifiLocalError: ""
    property string wifiPendingPasswordSsid: ""
    property string wifiPendingPasswordValue: ""

    property string bluetoothInfoMessage: ""
    property string bluetoothError: ""
    property string bluetoothPairAndConnectPath: ""
    property string bluetoothPendingSecretValue: ""
    readonly property var wifiController: WifiController
    readonly property var bluetoothPairingAgent: BluetoothPairingAgent
    readonly property var wifiNetworks: wifiController ? wifiController.networks : null

    readonly property real sliderKnobSize: 24
    readonly property color panelColor: StyleTokens.panel
    readonly property color moduleColor: StyleTokens.module
    readonly property color moduleHover: StyleTokens.moduleHover
    readonly property color trackColor: StyleTokens.track
    readonly property color textPrimary: StyleTokens.textPrimary
    readonly property color textSecondary: StyleTokens.textSecondary
    readonly property color cardAccent: StyleTokens.accent
    readonly property color cardAccentPressed: StyleTokens.accentPressed
    readonly property color cardFillActive: StyleTokens.cardFillActive
    readonly property color cardFillHover: StyleTokens.cardFillHover
    readonly property color buttonFill: StyleTokens.buttonFill
    readonly property color buttonFillHover: StyleTokens.buttonFillHover
    readonly property color buttonFillPressed: StyleTokens.buttonFillPressed
    readonly property string wifiGlyph: ""
    readonly property string bluetoothGlyph: ""
    readonly property string chargingIconGlyph: "\uf0e7"
    readonly property string brightnessIconGlyph: "\u{F00DF}"
    readonly property string volumeIconGlyph: "\u{F057E}"
    readonly property var batteryModeGlyphs: ["", "", ""]
    readonly property real detailsDrawerHandleHeight: 20
    readonly property real detailsDrawerContentGap: 8
    readonly property real batteryModeCardHeight: 80
    readonly property real batteryModeSlotWidth: 44
    readonly property real sectionSpacing: 12
    readonly property real headerHeight: 28
    readonly property real connectivityHeight: 80
    readonly property real sliderCardHeight: 76
    readonly property bool headerTrayVisible: !showHeaderBattery && showTray && systemTrayRepeater.count > 0
    readonly property real systemTrayHeight: systemTrayVisible ? 34 : 0
    readonly property bool systemTrayVisible: showHeaderBattery && showTray && systemTrayRepeater.count > 0
    readonly property real connectivitySectionHeight: showQuickCards ? connectivityHeight : 0
    readonly property int connectivityItemCount: Math.min(2, quickCardItems.length)
    readonly property int drawerItemCount: Math.max(0, quickCardItems.length - 2)
    readonly property real quickCardWidth: connectivityItemCount > 0
        ? (connectivityCardsRow.width - connectivityCardsRow.spacing * Math.max(0, connectivityItemCount - 1)) / connectivityItemCount
        : 0
    readonly property real drawerCardWidth: drawerItemCount > 0
        ? (detailsDrawerContentRow.width - detailsDrawerContentRow.spacing * Math.max(0, drawerItemCount - 1)) / drawerItemCount
        : 0
    readonly property real detailsDrawerSectionHeight: showDetailsDrawer
        ? detailsDrawerHandleHeight + detailsDrawerProgress * (detailsDrawerContentGap + connectivityHeight)
        : 0
    readonly property real detailsDrawerMaximumSectionHeight: showDetailsDrawer
        ? detailsDrawerHandleHeight + detailsDrawerContentGap + connectivityHeight
        : 0
    readonly property real brightnessSectionHeight: showBrightness ? sliderCardHeight : 0
    readonly property real volumeSectionHeight: showVolume ? sliderCardHeight : 0
    readonly property int visibleSectionCount: 1
        + (showQuickCards ? 1 : 0)
        + (showDetailsDrawer ? 1 : 0)
        + (showBrightness ? 1 : 0)
        + (showVolume ? 1 : 0)
        + (systemTrayVisible ? 1 : 0)
    readonly property real controlCenterPreferredHeight: 24
        + headerHeight
        + connectivitySectionHeight
        + systemTrayHeight
        + detailsDrawerSectionHeight
        + brightnessSectionHeight
        + volumeSectionHeight
        + Math.max(0, visibleSectionCount - 1) * sectionSpacing
    readonly property real controlCenterMaximumPreferredHeight: 24
        + headerHeight
        + connectivitySectionHeight
        + systemTrayHeight
        + detailsDrawerMaximumSectionHeight
        + brightnessSectionHeight
        + volumeSectionHeight
        + Math.max(0, visibleSectionCount - 1) * sectionSpacing
    readonly property real controlCenterExtraHeight: Math.max(0, controlCenterPreferredHeight - 320)
    readonly property real controlCenterMaximumExtraHeight: Math.max(0, controlCenterMaximumPreferredHeight - 320)
    readonly property bool bluetoothAvailable: !!bluetoothAdapter
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var bluetoothDeviceValues: bluetoothAdapter ? bluetoothAdapter.devices.values : []
    readonly property bool wifiSupported: wifiController ? wifiController.supported : false
    readonly property bool wifiReadOnly: wifiController ? wifiController.readOnly : true
    readonly property bool wifiAvailable: wifiController ? wifiController.available : false
    readonly property bool wifiEnabled: wifiController ? wifiController.enabled : false
    readonly property bool wifiBusy: wifiController ? wifiController.busy : false
    readonly property bool wifiListRunning: wifiController ? wifiController.scanning : false
    readonly property string wifiCurrentSsid: wifiController ? wifiController.currentSsid : ""
    readonly property string wifiInfoMessage: wifiLocalInfoMessage.length > 0
        ? wifiLocalInfoMessage
        : (wifiController ? wifiController.infoMessage : "")
    readonly property string wifiError: wifiLocalError.length > 0
        ? wifiLocalError
        : (wifiController ? wifiController.errorMessage : "")
    readonly property string wifiUnsupportedReason: wifiController ? wifiController.unsupportedReason : ""
    readonly property string wifiAvailabilityMessage: {
        if (wifiUnsupportedReason.length > 0) return wifiUnsupportedReason;
        if (wifiSupported && !wifiAvailable) return "No Wi-Fi device is available.";
        return "";
    }
    readonly property bool bluetoothEnabled: bluetoothAdapter ? bluetoothAdapter.enabled : false
    readonly property bool bluetoothBusy: bluetoothAdapter
        ? bluetoothAdapter.state === BluetoothAdapterState.Enabling
            || bluetoothAdapter.state === BluetoothAdapterState.Disabling
        : false
    readonly property bool bluetoothPairingActive: bluetoothPairingAgent ? bluetoothPairingAgent.requestActive : false
    readonly property bool bluetoothPairingRequiresInput: bluetoothPairingAgent ? bluetoothPairingAgent.requestRequiresInput : false
    readonly property bool bluetoothPairingNumericInput: bluetoothPairingAgent ? bluetoothPairingAgent.requestNumericInput : false
    readonly property bool bluetoothPairingRequiresConfirmation: bluetoothPairingAgent ? bluetoothPairingAgent.requestRequiresConfirmation : false
    readonly property string bluetoothPairingTitle: bluetoothPairingAgent ? bluetoothPairingAgent.promptTitle : ""
    readonly property string bluetoothPairingMessage: bluetoothPairingAgent ? bluetoothPairingAgent.promptMessage : ""
    readonly property string bluetoothPairingDisplayedCode: bluetoothPairingAgent ? bluetoothPairingAgent.displayedCode : ""
    readonly property bool hasConnectivityPrompt: wifiPendingPasswordSsid.length > 0 || bluetoothPairingActive
    readonly property bool anyConnectivityPanelOpen: wifiPanelOpen || bluetoothPanelOpen
    readonly property string wifiStatusText: wifiController ? wifiController.statusText : "Unavailable"
    readonly property string bluetoothStatusText: buildBluetoothStatusText()
    readonly property string bluetoothAvailabilityMessage: bluetoothAvailable ? "" : "No Bluetooth adapter is available."
    readonly property string batteryModeStatusText: buildBatteryModeStatusText()

    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }

    function trimString(value) {
        if (value === undefined || value === null) return "";
        return String(value).trim();
    }

    function hasControlCenterItem(name) {
        if (!configuredItems)
            return false;

        for (let i = 0; i < configuredItems.length; ++i) {
            if (trimString(configuredItems[i]) === name)
                return true;
        }

        return false;
    }

    function orderedQuickCardItems() {
        const result = [];
        if (!configuredItems)
            return result;

        for (let i = 0; i < configuredItems.length; ++i) {
            const item = trimString(configuredItems[i]);
        if (item === "wifi" || item === "bluetooth" || item === "tlp")
                result.push(item);
        }

        return result;
    }

    function quickCardIndex(name) {
        for (let i = 0; i < quickCardItems.length; ++i) {
            if (quickCardItems[i] === name)
                return i;
        }

        return -1;
    }

    function quickCardInMainRow(name) {
        const index = quickCardIndex(name);
        return index >= 0 && index < 2;
    }

    function quickCardInDrawer(name) {
        return quickCardIndex(name) >= 2;
    }

	function handleTrayItemClicked(item, visualItem, mouse) {
		if (mouse.button === Qt.MiddleButton) {
			item.secondaryActivate();
			return;
		}

		if (mouse.button === Qt.RightButton && item.hasMenu && menuParentWindow) {
			const pos = visualItem.mapToItem(
				menuParentWindow.contentItem,
				mouse.x,
				mouse.y
			);

			item.display(menuParentWindow, Math.round(pos.x), Math.round(pos.y));
			return;
		}

		if (item.onlyMenu && item.hasMenu && menuParentWindow) {
			const pos = visualItem.mapToItem(
				menuParentWindow.contentItem,
				mouse.x,
				mouse.y
			);

			item.display(menuParentWindow, Math.round(pos.x), Math.round(pos.y));
			return;
		}

		item.activate();
	}

    function batteryModeLabel(index) {
        if (index <= 0) return "Power Saver";
        if (index >= 2) return "Performance";
        return "Balanced";
    }

    function batteryModeCommand(index) {
        if (index <= 0) return "power-saver";
        if (index >= 2) return "performance";
        return "balanced";
    }

    function batteryModeIndexForCommand(command) {
        const normalized = trimString(command).toLowerCase();
        if (normalized === "power-saver" || normalized === "bat") return 0;
        if (normalized === "performance" || normalized === "ac") return 2;
        return 1;
    }

    function setBatteryModeVisualIndex(index, animate) {
        const nextIndex = Math.max(0, Math.min(2, index));
        batteryModeIndex = nextIndex;
    }

    function setDetailsDrawerOpen(open) {
        const nextOpen = !!open;
        detailsDrawerOpen = nextOpen;
        detailsDrawerSettling = true;
        detailsDrawerProgress = nextOpen ? 1 : 0;
        detailsDrawerSettleTimer.restart();
        if (nextOpen && !batteryTlpChecked)
            refreshBatteryModeState();
    }

    function toggleDetailsDrawer() {
        setDetailsDrawerOpen(!detailsDrawerOpen);
    }

    function refreshBatteryModeState() {
        if (!showTlp)
            return;
        if (batteryModeStateRunning)
            return;

        batteryModeStateRunning = true;
        SystemServices.requestTlpState();
    }

    function applyBatteryModeState(available, profile, output, errorString) {
        batteryModeStateRunning = false;
        batteryTlpChecked = true;
        batteryTlpAvailable = !!available;

        if (!batteryTlpAvailable) {
            batteryModeBusy = false;
            batteryModeError = trimString(errorString).length > 0 ? errorString : "TLP is not installed.";
            setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
            return;
        }

        if (batteryModeError === "TLP is not installed.")
            batteryModeError = "";

        let resolvedProfile = trimString(profile);
        if (resolvedProfile.length === 0) {
            const profileMatch = String(output || "").match(/TLP profile\s*=\s*([a-z-]+)/i);
            if (profileMatch)
                resolvedProfile = profileMatch[1];
        }

        if (resolvedProfile.length > 0) {
            const nextIndex = batteryModeIndexForCommand(resolvedProfile);
            batteryModeAppliedIndex = nextIndex;
            setBatteryModeVisualIndex(nextIndex, true);

            if (batteryModeRefreshPollsRemaining > 0 && nextIndex === batteryModePendingIndex) {
                batteryModeRefreshPollsRemaining = 0;
                batteryModeRefreshTimer.stop();
                batteryModeError = "";
                batteryModeInfoMessage = batteryModeLabel(nextIndex) + " active.";
            }
        }
    }

    function buildBatteryModeStatusText() {
        if (batteryModeBusy) return "Applying " + batteryModeLabel(batteryModePendingIndex);
        if (trimString(userConfig.tlpPermissionMode) === "skip") return "TLP disabled";
        if (!batteryTlpChecked) return "Checking TLP";
        if (!batteryTlpAvailable) return "TLP is not installed";
        return batteryModeLabel(batteryModeIndex);
    }

    function rollbackBatteryMode(message) {
        batteryModeBusy = false;
        batteryModeError = message;
        batteryModeInfoMessage = "";
        batteryModeDragOffset = 0;
        setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
    }

    function classifyBatteryModeFailure(exitCode) {
        const details = trimString(batteryModeLastCommandOutput).toLowerCase();

        if (details.indexOf("sorry, try again") >= 0 || details.indexOf("incorrect password attempt") >= 0)
            return "The configured sudo password did not work.";
        if (details.indexOf("pkexec") >= 0 && details.indexOf("not installed") >= 0)
            return "Install pkexec or set tlpSudoPassword in userconfig.json.";
        if (details.indexOf("sudo is not installed") >= 0)
            return "sudo is not installed.";
        if (details.indexOf("sudo:") >= 0 && details.indexOf("password") >= 0) {
            if (trimString(userConfig.tlpPermissionMode) === "ask")
                return "Install pkexec or set tlpSudoPassword in userconfig.json.";
            return "sudo needs a password; set tlpSudoPassword in userconfig.json.";
        }
        if (details.indexOf("sudo:") >= 0 && details.indexOf("no new privileges") >= 0)
            return "sudo is blocked by the current process security flags.";
        if (details.indexOf("sudo:") >= 0 && details.indexOf("a terminal is required") >= 0)
            return "sudo needs a real terminal, but the panel could not open one.";
        if (details.indexOf("missing root privilege") >= 0)
            return "TLP needs admin permission.";
        if (details.indexOf("command not found") >= 0 || details.indexOf("not found") >= 0) {
            if (details.indexOf("tlp") >= 0)
                return "TLP is not installed.";
        }

        if (exitCode === 127)
            return "TLP is not installed.";
        if (exitCode === 126)
            return "Install pkexec or set tlpSudoPassword in userconfig.json.";
        return "TLP could not apply that mode.";
    }

    function queueBatteryModeStateRefresh(polls) {
        batteryModeRefreshPollsRemaining = Math.max(0, polls);
        if (batteryModeRefreshPollsRemaining > 0)
            batteryModeRefreshTimer.restart();
        else
            batteryModeRefreshTimer.stop();
    }

    function selectBatteryMode(index) {
        if (batteryModeBusy) {
            if (batteryModeSetterRunning)
                SystemServices.cancelTlpApply();
            batteryModeBusy = false;
            batteryModeSetterRunning = false;
        }

        queueBatteryModeStateRefresh(0);

        const nextIndex = Math.max(0, Math.min(2, index));

        if (trimString(userConfig.tlpPermissionMode) === "skip") {
            rollbackBatteryMode("TLP mode switching is disabled in userconfig.json.");
            return;
        }

        if (!batteryTlpChecked) {
            refreshBatteryModeState();
            rollbackBatteryMode("Checking TLP. Try again in a moment.");
            return;
        }

        if (!batteryTlpAvailable) {
            rollbackBatteryMode("TLP is not installed.");
            return;
        }

        if (nextIndex === batteryModeAppliedIndex) {
            batteryModeError = "";
            batteryModeInfoMessage = batteryModeLabel(nextIndex) + " active.";
            setBatteryModeVisualIndex(nextIndex, true);
            return;
        }

        batteryModePendingIndex = nextIndex;
        batteryModeBusy = true;
        batteryModeSetterRunning = true;
        batteryModeError = "";
        batteryModeInfoMessage = "Applying " + batteryModeLabel(nextIndex) + "...";
        setBatteryModeVisualIndex(nextIndex, true);
        batteryModeLastCommandOutput = "";
        SystemServices.setTlpMode(batteryModeCommand(nextIndex), trimString(userConfig.tlpSudoPassword));
    }

    function finishBatteryModeApply(success, exitCode, output, errorString) {
        batteryModeSetterRunning = false;
        batteryModeBusy = false;
        batteryModeLastCommandOutput = trimString(output);
        if (batteryModeLastCommandOutput.length === 0)
            batteryModeLastCommandOutput = trimString(errorString);

        if (!success) {
            rollbackBatteryMode(classifyBatteryModeFailure(exitCode));
            return;
        }

        batteryModeAppliedIndex = batteryModePendingIndex;
        batteryModeError = "";
        batteryModeInfoMessage = batteryModeLabel(batteryModeAppliedIndex) + " active.";
        setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
        refreshBatteryModeState();
    }

    function clearWifiPrompt() {
        wifiPendingPasswordSsid = "";
        wifiPendingPasswordValue = "";
        wifiLocalInfoMessage = "";
        wifiLocalError = "";
    }

    function clearWifiMessages() {
        wifiLocalInfoMessage = "";
        wifiLocalError = "";
        if (wifiController)
            wifiController.clearMessages();
    }

    function clearBluetoothMessages() {
        bluetoothInfoMessage = "";
        bluetoothError = "";
    }

    function submitBluetoothPairingSecret() {
        if (!bluetoothPairingAgent || !bluetoothPairingRequiresInput)
            return;

        const secret = trimString(bluetoothPendingSecretValue);
        if (!secret) {
            bluetoothError = bluetoothPairingNumericInput
                ? "Enter the 6-digit passkey first."
                : "Enter the PIN first.";
            return;
        }

        if (bluetoothPairingNumericInput && !/^\d{1,6}$/.test(secret)) {
            bluetoothError = "Passkeys must be 1 to 6 digits.";
            return;
        }

        bluetoothError = "";
        bluetoothPairingAgent.submitSecret(secret);
        bluetoothPendingSecretValue = "";
    }

    function confirmBluetoothPairing() {
        if (!bluetoothPairingAgent)
            return;

        bluetoothError = "";
        bluetoothPairingAgent.confirmRequest();
    }

    function cancelBluetoothPairing() {
        if (!bluetoothPairingAgent)
            return;

        bluetoothPairingAgent.cancelRequest();
        bluetoothPendingSecretValue = "";
    }

    function isConnectivityPanelOpen(kind) {
        if (kind === "wifi") return wifiPanelOpen;
        if (kind === "bluetooth") return bluetoothPanelOpen;
        return false;
    }

    function setConnectivityPanelOpen(kind, open, emitSignal) {
        if (emitSignal === undefined)
            emitSignal = true;

        const nextOpen = !!open;
        let changed = false;

        if (kind === "wifi") {
            changed = wifiPanelOpen !== nextOpen;
            wifiPanelOpen = nextOpen;

            if (nextOpen) {
                if (showCondition) {
                    requestWifiStateRefresh();
                    if (wifiSupported && wifiEnabled)
                        requestWifiListRefresh(true);
                }
            } else {
                clearWifiPrompt();
                clearWifiMessages();
            }
        } else if (kind === "bluetooth") {
            changed = bluetoothPanelOpen !== nextOpen;
            bluetoothPanelOpen = nextOpen;

            if (!nextOpen) {
                if (bluetoothPairingActive)
                    cancelBluetoothPairing();
                if (bluetoothAdapter && bluetoothAdapter.discovering)
                    bluetoothAdapter.discovering = false;
                bluetoothScanStopTimer.stop();
                bluetoothPairAndConnectPath = "";
                bluetoothPendingSecretValue = "";
                clearBluetoothMessages();
            }
        } else {
            return;
        }

        if (changed && emitSignal)
            connectivityPanelRequested(kind, nextOpen);
    }

    function toggleConnectivityOverlay(kind) {
        setConnectivityPanelOpen(kind, !isConnectivityPanelOpen(kind));
    }

    function closeConnectivityPanels(emitSignals) {
        if (emitSignals === undefined)
            emitSignals = true;

        setConnectivityPanelOpen("wifi", false, emitSignals);
        setConnectivityPanelOpen("bluetooth", false, emitSignals);
        clearWifiPrompt();
        clearWifiMessages();
        clearBluetoothMessages();
    }

    function requestWifiStateRefresh() {
        if (!showCondition || !wifiController) return;
        wifiController.refreshState();
    }

    function requestWifiListRefresh(rescan) {
        if (!showCondition || !wifiController) return;
        if (!wifiSupported || !wifiAvailable || !wifiEnabled) return;
        wifiController.refreshNetworks(!!rescan);
    }

    function toggleWifiEnabled() {
        clearWifiPrompt();
        clearWifiMessages();
        if (wifiController)
            wifiController.setEnabled(!wifiEnabled);
    }

    function disconnectWifi() {
        if (!wifiSupported || !wifiAvailable) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "No Wi-Fi device is available.";
            return;
        }

        clearWifiPrompt();
        clearWifiMessages();
        if (wifiController)
            wifiController.disconnectCurrent();
    }

    function connectWifiNetwork(network) {
        if (!network) return;
        if (!wifiSupported) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "Wi-Fi control is unavailable.";
            return;
        }
        if (!wifiAvailable) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "No Wi-Fi device is available.";
            return;
        }
        if (!wifiEnabled) {
            wifiLocalError = "Turn on Wi-Fi first.";
            return;
        }
        if (network.connected) return;

        const ssid = trimString(network.ssid);
        const networkType = trimString(network.type);
        const secure = !!network.secure;
        const savedConnection = !!network.savedConnection;

        if (!ssid) {
            wifiLocalError = "Hidden networks are not supported in this panel yet.";
            return;
        }

        if (!savedConnection && networkType === "wep") {
            wifiLocalError = "WEP networks aren't supported by this panel.";
            return;
        }

        if (!savedConnection && networkType === "8021x") {
            wifiLocalError = "802.1X networks need to be provisioned first.";
            return;
        }

        clearWifiPrompt();
        clearWifiMessages();

        if (savedConnection) {
            if (wifiController)
                wifiController.connectToNetwork(ssid);
            return;
        }

        if (!secure) {
            if (wifiController)
                wifiController.connectToNetwork(ssid);
            return;
        }

        wifiPendingPasswordSsid = ssid;
        wifiPendingPasswordValue = "";
        wifiLocalInfoMessage = "Enter the password for " + ssid + ".";
    }

    function submitWifiPassword() {
        const ssid = trimString(wifiPendingPasswordSsid);
        if (!ssid) return;

        if (trimString(wifiPendingPasswordValue).length === 0) {
            wifiLocalError = "Enter a password first.";
            return;
        }

        const password = wifiPendingPasswordValue;
        clearWifiPrompt();
        clearWifiMessages();
        if (wifiController)
            wifiController.connectToNetwork(ssid, password);
    }

    function applyBrightnessSnapshot(value) {
        if (value >= 0)
            syncBrightnessFromLevel(value);
    }

    function applyVolumeSnapshot(value) {
        if (value >= 0)
            syncVolumeFromLevel(value);
    }

    function flushBrightness(force) {
        const nextValue = clamp01(pendingBrightness);
        if (!force && Math.abs(nextValue - lastAppliedBrightness) < 0.01) return;
        if (brightnessSetterRunning) {
            brightnessApplyTimer.restart();
            return;
        }

        lastAppliedBrightness = nextValue;
        brightnessSetterRunning = true;
        SystemServices.setBrightness(nextValue);
    }

    function queueBrightness(value) {
        localBrightness = clamp01(value);
        if (showCondition && !sliderIntroPending) displayedBrightness = localBrightness;
        pendingBrightness = localBrightness;
        brightnessApplyTimer.restart();
    }

    function flushVolume(force) {
        const nextValue = clamp01(pendingVolume);
        if (!force && Math.abs(nextValue - lastAppliedVolume) < 0.01) return;
        if (volumeSetterRunning) {
            volumeApplyTimer.restart();
            return;
        }

        lastAppliedVolume = nextValue;
        volumeSetterRunning = true;
        SystemServices.setVolume(nextValue);
    }

    function queueVolume(value) {
        localVolume = clamp01(value);
        if (showCondition && !sliderIntroPending) displayedVolume = localVolume;
        pendingVolume = localVolume;
        volumeApplyTimer.restart();
    }

    function syncBrightnessFromLevel(level) {
        if (level < 0) return;
        localBrightness = clamp01(level);
        if (showCondition && !sliderIntroPending) displayedBrightness = localBrightness;
        pendingBrightness = localBrightness;
        lastAppliedBrightness = localBrightness;
    }

    function syncVolumeFromLevel(level) {
        if (level < 0) return;
        localVolume = clamp01(level);
        if (showCondition && !sliderIntroPending) displayedVolume = localVolume;
        pendingVolume = localVolume;
        lastAppliedVolume = localVolume;
    }

    function syncLevelsFromProps() {
        syncBrightnessFromLevel(brightnessLevel);
        syncVolumeFromLevel(volumeLevel);
    }

    function bluetoothDeviceName(device) {
        if (!device) return "Unknown device";
        const preferred = trimString(device.deviceName);
        if (preferred.length > 0) return preferred;

        const alias = trimString(device.name);
        if (alias.length > 0) return alias;

        const address = trimString(device.address);
        return address.length > 0 ? address : "Unknown device";
    }

    function bluetoothDeviceStateText(device) {
        if (!device) return "";
        if (device.pairing) return "Pairing";

        switch (device.state) {
        case BluetoothDeviceState.Connecting:
            return "Connecting";
        case BluetoothDeviceState.Connected:
            return "Connected";
        case BluetoothDeviceState.Disconnecting:
            return "Disconnecting";
        default:
            break;
        }

        if (device.paired || device.bonded) return "Paired";
        return "Available";
    }

    function bluetoothDeviceSubtitle(device) {
        const parts = [];
        const stateLabel = bluetoothDeviceStateText(device);
        if (stateLabel.length > 0) parts.push(stateLabel);
        if (device && device.batteryAvailable) parts.push(bluetoothBatteryPercent(device) + "%");
        return parts.join(" • ");
    }

    function bluetoothBatteryPercent(device) {
        if (!device || !device.batteryAvailable)
            return -1;

        const rawValue = Math.max(0, Number(device.battery) || 0);
        return Math.max(0, Math.min(100, Math.round(rawValue <= 1 ? rawValue * 100 : rawValue)));
    }

    function bluetoothDeviceMatchesSection(device, section) {
        if (!device) return false;

        const paired = device.paired || device.bonded;
        if (section === "connected") return device.connected;
        if (section === "paired") return !device.connected && paired;
        if (section === "available") return !paired;
        return false;
    }

    function buildBluetoothStatusText() {
        if (!bluetoothAvailable) return "Unavailable";
        if (!bluetoothEnabled) return "Off";

        const devices = bluetoothDeviceValues || [];
        const connectedNames = [];

        for (let index = 0; index < devices.length; index++) {
            const device = devices[index];
            if (device && device.connected)
                connectedNames.push(bluetoothDeviceName(device));
        }

        if (connectedNames.length === 1) return connectedNames[0];
        if (connectedNames.length > 1) return connectedNames[0] + " +" + (connectedNames.length - 1);
        if (bluetoothAdapter.discovering) return "Scanning";
        return bluetoothBusy ? "Working..." : "On";
    }

    function toggleBluetoothEnabled() {
        if (!bluetoothAdapter) {
            bluetoothError = "No Bluetooth adapter is available.";
            return;
        }

        bluetoothError = "";
        bluetoothInfoMessage = "";
        bluetoothPairAndConnectPath = "";

        if (bluetoothAdapter.discovering)
            bluetoothAdapter.discovering = false;

        bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
    }

    function toggleBluetoothScan() {
        if (!bluetoothAdapter) {
            bluetoothError = "No Bluetooth adapter is available.";
            return;
        }
        if (!bluetoothEnabled) {
            bluetoothError = "Turn on Bluetooth first.";
            return;
        }

        bluetoothError = "";
        if (bluetoothAdapter.discovering) {
            bluetoothAdapter.discovering = false;
            bluetoothInfoMessage = "";
            bluetoothScanStopTimer.stop();
        } else {
            bluetoothAdapter.discovering = true;
            bluetoothInfoMessage = "Scanning for nearby devices...";
            bluetoothScanStopTimer.restart();
        }
    }

    function handleBluetoothDevicePressed(device) {
        if (!device) return;
        if (!bluetoothAdapter || !bluetoothEnabled) {
            bluetoothError = "Turn on Bluetooth first.";
            return;
        }

        bluetoothError = "";

        if (device.connected) {
            bluetoothInfoMessage = "";
            device.disconnect();
            return;
        }

        if (device.paired || device.bonded) {
            bluetoothInfoMessage = "";
            device.connect();
            return;
        }

        bluetoothPairAndConnectPath = device.dbusPath;
        bluetoothInfoMessage = "Pairing " + bluetoothDeviceName(device) + "...";
        device.pair();
    }

    function forgetBluetoothDevice(device) {
        if (!device) return;
        if (bluetoothPairAndConnectPath === device.dbusPath)
            bluetoothPairAndConnectPath = "";
        device.forget();
    }

    anchors.fill: parent
    anchors.margins: 12
    opacity: showCondition ? 1 : 0
    visible: opacity > 0

    onBrightnessLevelChanged: syncBrightnessFromLevel(brightnessLevel)
    onVolumeLevelChanged: syncVolumeFromLevel(volumeLevel)
    onShowConditionChanged: {
        if (showCondition) {
            syncLevelsFromProps();
            sliderIntroPending = true;
            displayedBrightness = localBrightness;
            displayedVolume = localVolume;
            sliderIntroTimer.interval = sliderIntroDelay;
            sliderIntroTimer.restart();
            if (showTlp)
                refreshBatteryModeState();
            requestWifiStateRefresh();
            if (wifiPanelOpen && wifiSupported && wifiEnabled)
                requestWifiListRefresh(true);
        } else {
            sliderIntroTimer.stop();
            sliderIntroPending = false;
            displayedBrightness = localBrightness;
            displayedVolume = localVolume;
            closeConnectivityPanels();
        }
    }

    Component.onCompleted: {
        syncLevelsFromProps();
        displayedBrightness = localBrightness;
        displayedVolume = localVolume;
        SystemServices.requestBrightness();
        SystemServices.requestVolume();
        if (showTlp)
            refreshBatteryModeState();
    }

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 240 : 100
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on displayedBrightness {
        enabled: controlCenter.showCondition && !controlCenter.sliderIntroPending && !brightnessCard.pressed

        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    Behavior on displayedVolume {
        enabled: controlCenter.showCondition && !controlCenter.sliderIntroPending && !volumeCard.pressed

        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    Behavior on detailsDrawerProgress {
        enabled: !controlCenter.detailsDrawerDragging

        NumberAnimation {
            id: detailsDrawerProgressAnimation
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: SystemServices

        function onTlpStateReady(available, profile, output, errorString) {
            controlCenter.applyBatteryModeState(available, profile, output, errorString);
        }

        function onTlpSetFinished(success, exitCode, output, errorString) {
            controlCenter.finishBatteryModeApply(success, exitCode, output, errorString);
        }

        function onBrightnessSnapshotReady(value, errorString) {
            if (errorString === "")
                controlCenter.applyBrightnessSnapshot(value);
        }

        function onBrightnessSetFinished(value, success, errorString) {
            controlCenter.brightnessSetterRunning = false;
            if (success)
                controlCenter.applyBrightnessSnapshot(value);
            if (success && Math.abs(controlCenter.pendingBrightness - controlCenter.lastAppliedBrightness) >= 0.01)
                brightnessApplyTimer.restart();
        }

        function onVolumeSnapshotReady(value, muted, errorString) {
            if (errorString === "")
                controlCenter.applyVolumeSnapshot(value);
        }

        function onVolumeSetFinished(value, success, errorString) {
            controlCenter.volumeSetterRunning = false;
            if (success)
                controlCenter.applyVolumeSnapshot(value);
            if (success && Math.abs(controlCenter.pendingVolume - controlCenter.lastAppliedVolume) >= 0.01)
                volumeApplyTimer.restart();
        }
    }

    Timer {
        id: brightnessApplyTimer
        interval: 55
        repeat: false
        onTriggered: controlCenter.flushBrightness(false)
    }

    Timer {
        id: volumeApplyTimer
        interval: 55
        repeat: false
        onTriggered: controlCenter.flushVolume(false)
    }

    Timer {
        id: sliderIntroTimer
        interval: controlCenter.sliderIntroDelay
        repeat: false

        onTriggered: {
            controlCenter.sliderIntroPending = false;
            controlCenter.displayedBrightness = controlCenter.localBrightness;
            controlCenter.displayedVolume = controlCenter.localVolume;
        }
    }

    Timer {
        id: batteryModeRefreshTimer
        interval: 1500
        repeat: true
        onTriggered: {
            if (controlCenter.batteryModeRefreshPollsRemaining <= 0) {
                stop();
                return;
            }

            controlCenter.batteryModeRefreshPollsRemaining -= 1;
            controlCenter.refreshBatteryModeState();

            if (controlCenter.batteryModeRefreshPollsRemaining <= 0)
                stop();
        }
    }

    Timer {
        id: bluetoothScanStopTimer
        interval: 8000
        repeat: false
        onTriggered: {
            if (controlCenter.bluetoothAdapter && controlCenter.bluetoothAdapter.discovering)
                controlCenter.bluetoothAdapter.discovering = false;
            controlCenter.bluetoothInfoMessage = "";
        }
    }

    Timer {
        id: detailsDrawerSettleTimer
        interval: 300
        repeat: false
        onTriggered: controlCenter.detailsDrawerSettling = false
    }

    Connections {
        target: wifiController

        function onEnabledChanged() {
            if (!controlCenter.wifiEnabled)
                controlCenter.clearWifiPrompt();
        }
    }

    Connections {
        target: bluetoothAdapter

        function onEnabledChanged() {
            if (!controlCenter.bluetoothAdapter.enabled) {
                controlCenter.bluetoothPairAndConnectPath = "";
                controlCenter.bluetoothInfoMessage = "";
                controlCenter.bluetoothError = "";
                controlCenter.bluetoothScanStopTimer.stop();
            }
        }

        function onDiscoveringChanged() {
            if (!controlCenter.bluetoothAdapter.discovering)
                controlCenter.bluetoothScanStopTimer.stop();
        }
    }

    Connections {
        target: bluetoothPairingAgent

        function onRequestChanged() {
            controlCenter.bluetoothPendingSecretValue = "";
            if (controlCenter.bluetoothPairingActive) {
                controlCenter.bluetoothError = "";
                controlCenter.setConnectivityPanelOpen("bluetooth", true);
            }
        }

        function onRegistrationErrorChanged() {
            if (!controlCenter.bluetoothPairingAgent)
                return;

            if (!controlCenter.bluetoothPairingAgent.registered
                    && controlCenter.bluetoothPairingAgent.registrationError.length > 0
                    && controlCenter.bluetoothPanelOpen) {
                controlCenter.bluetoothError = controlCenter.bluetoothPairingAgent.registrationError;
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Item {
            width: parent.width
            height: 28

            Item {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 220
                height: parent.height

                Text {
                    id: timeLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: currentTime
                    color: StyleTokens.textPrimaryBright
                    font.pixelSize: 19
                    font.family: heroFontFamily
                    font.weight: Font.Bold
                    font.letterSpacing: -0.45
                }

                Text {
                    anchors.left: timeLabel.right
                    anchors.leftMargin: 10
                    anchors.baseline: timeLabel.baseline
                    text: currentDateLabel
                    color: textSecondary
                    font.pixelSize: 12
                    font.family: textFontFamily
                    font.weight: Font.Medium
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                visible: controlCenter.showHeaderBattery

                Text {
                    text: controlCenter.chargingIconGlyph
                    color: StyleTokens.white
                    font.pixelSize: 13
                    font.family: iconFontFamily
                    visible: isCharging
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: batteryCapacity + "%"
                    color: StyleTokens.white
                    font.pixelSize: 13
                    font.family: textFontFamily
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: 28
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        anchors.rightMargin: 2
                        radius: 4
                        color: StyleTokens.transparent
                        border.color: StyleTokens.textSecondary
                        border.width: 1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 2
                            radius: 2
                            width: (parent.width - 4) * (batteryCapacity / 100.0)
                            color: {
                                if (batteryCapacity <= 10) return StyleTokens.danger;
                                if (batteryCapacity <= 20) return StyleTokens.warning;
                                return StyleTokens.success;
                            }

                            Behavior on width {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 2
                        height: 6
                        radius: 1
                        color: StyleTokens.textSecondary
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(parent.width - 230, headerTrayRow.implicitWidth + 18)
                height: 28
                radius: 14
                color: StyleTokens.module
                visible: controlCenter.headerTrayVisible

                Row {
                    id: headerTrayRow
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: SystemTray.items

                        delegate: Item {
                            id: headerTrayButton
                            width: 20
                            height: 20

                            IconImage {
                                anchors.fill: parent
                                source: modelData.icon
                                implicitSize: 20
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                hoverEnabled: true
                                onClicked: function(mouse) { controlCenter.handleTrayItemClicked(modelData, headerTrayButton, mouse); }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: systemTraySection
            width: parent.width
            height: controlCenter.systemTrayHeight
            visible: controlCenter.systemTrayVisible

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(parent.width, systemTrayRow.implicitWidth + 18)
                height: 34
                radius: 17
                color: StyleTokens.module

                Row {
                    id: systemTrayRow
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        id: systemTrayRepeater
                        model: SystemTray.items

                        delegate: Item {
                            id: trayButton
                            width: 22
                            height: 22

                            IconImage {
                                anchors.fill: parent
                                source: modelData.icon
                                implicitSize: 22
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                hoverEnabled: true

                                onClicked: function(mouse) { controlCenter.handleTrayItemClicked(modelData, trayButton, mouse); }
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: controlCenter.connectivitySectionHeight
            visible: controlCenter.showQuickCards

            Row {
                id: connectivityCardsRow
                anchors.fill: parent
                spacing: 12

                Rectangle {
                    id: wifiCard
                    visible: controlCenter.quickCardInMainRow("wifi")
                    width: controlCenter.quickCardWidth
                    height: connectivityCardsRow.height
                    radius: 20
                    color: (wifiCardMouse.containsMouse || wifiPanelOpen) ? StyleTokens.connectivityCardHover : StyleTokens.connectivityCard

                    Behavior on color {
                        ColorAnimation {
                            duration: StyleTokens.durationFast
                        }
                    }

                    MouseArea {
                        id: wifiCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        text: wifiGlyph
                        color: wifiEnabled ? cardAccent : StyleTokens.textDisabled
                        font.pixelSize: 18
                        font.family: iconFontFamily
                    }

                    Rectangle {
                        id: wifiSwitchTrack
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        width: 34
                        height: 20
                        radius: 10
                        color: wifiEnabled ? StyleTokens.success : StyleTokens.switchOff

                        Behavior on color {
                            ColorAnimation {
                                duration: StyleTokens.durationFast
                            }
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            y: 2
                            x: wifiEnabled ? 16 : 2
                            color: StyleTokens.white

                            Behavior on x {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            id: wifiToggleArea
                            anchors.fill: parent
                            enabled: wifiSupported && wifiAvailable && !wifiBusy
                            onClicked: controlCenter.toggleWifiEnabled()
                        }
                    }

                    Item {
                        id: wifiDetailButton
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 8
                        height: 30

                        Text {
                            anchors.left: parent.left
                            anchors.right: wifiChevron.left
                            anchors.rightMargin: 8
                            anchors.top: parent.top
                            text: "Wi-Fi"
                            color: textPrimary
                            font.pixelSize: 13
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: wifiChevron.left
                            anchors.rightMargin: 8
                            anchors.bottom: parent.bottom
                            text: wifiStatusText
                            color: StyleTokens.textMuted
                            font.pixelSize: 10
                            font.family: textFontFamily
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            id: wifiChevron
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: wifiPanelOpen ? "#c7c9cf" : StyleTokens.textSubtle
                            font.pixelSize: 17
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: controlCenter.toggleConnectivityOverlay("wifi")
                        }
                    }
                }

                Rectangle {
                    id: bluetoothCard
                    visible: controlCenter.quickCardInMainRow("bluetooth")
                    width: controlCenter.quickCardWidth
                    height: connectivityCardsRow.height
                    radius: 20
                    color: (bluetoothCardMouse.containsMouse || bluetoothPanelOpen) ? StyleTokens.connectivityCardHover : StyleTokens.connectivityCard

                    Behavior on color {
                        ColorAnimation {
                            duration: StyleTokens.durationFast
                        }
                    }

                    MouseArea {
                        id: bluetoothCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        text: bluetoothGlyph
                        color: bluetoothEnabled ? cardAccent : StyleTokens.textDisabled
                        font.pixelSize: 18
                        font.family: iconFontFamily
                    }

                    Rectangle {
                        id: bluetoothSwitchTrack
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        width: 34
                        height: 20
                        radius: 10
                        color: bluetoothEnabled ? StyleTokens.success : StyleTokens.switchOff

                        Behavior on color {
                            ColorAnimation {
                                duration: StyleTokens.durationFast
                            }
                        }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            y: 2
                            x: bluetoothEnabled ? 16 : 2
                            color: StyleTokens.white

                            Behavior on x {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            id: bluetoothToggleArea
                            anchors.fill: parent
                            enabled: bluetoothAvailable && !bluetoothBusy
                            onClicked: controlCenter.toggleBluetoothEnabled()
                        }
                    }

                    Item {
                        id: bluetoothDetailButton
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 8
                        height: 30

                        Text {
                            anchors.left: parent.left
                            anchors.right: bluetoothChevron.left
                            anchors.rightMargin: 8
                            anchors.top: parent.top
                            text: "Bluetooth"
                            color: textPrimary
                            font.pixelSize: 13
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: bluetoothChevron.left
                            anchors.rightMargin: 8
                            anchors.bottom: parent.bottom
                            text: bluetoothStatusText
                            color: StyleTokens.textMuted
                            font.pixelSize: 10
                            font.family: textFontFamily
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            id: bluetoothChevron
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: bluetoothPanelOpen ? "#c7c9cf" : StyleTokens.textSubtle
                            font.pixelSize: 17
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: controlCenter.toggleConnectivityOverlay("bluetooth")
                        }
                    }
                }

                Rectangle {
                    id: tlpCard
                    visible: controlCenter.quickCardInMainRow("tlp")
                    width: controlCenter.quickCardWidth
                    height: connectivityCardsRow.height
                    radius: 20
                    color: tlpCardMouse.containsMouse ? StyleTokens.connectivityCardHover : StyleTokens.connectivityCard

                    Behavior on color {
                        ColorAnimation {
                            duration: StyleTokens.durationFast
                        }
                    }

                    MouseArea {
                        id: tlpCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: false
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.top: parent.top
                        anchors.topMargin: 11
                        text: "TLP"
                        color: textPrimary
                        font.pixelSize: 13
                        font.family: textFontFamily
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        width: Math.max(0, parent.width - 88)
                        text: controlCenter.batteryModeError.length > 0
                            ? controlCenter.batteryModeError
                            : (controlCenter.batteryModeInfoMessage.length > 0
                                ? controlCenter.batteryModeInfoMessage
                                : controlCenter.batteryModeStatusText)
                        color: controlCenter.batteryModeError.length > 0 ? StyleTokens.error : StyleTokens.textMuted
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: 9
                        font.family: textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Item {
                        id: tlpModeCarousel
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        height: 34
                        clip: true

                        Item {
                            id: tlpModeItems
                            width: controlCenter.batteryModeSlotWidth * 3
                            height: parent.height
                            x: tlpModeCarousel.width / 2
                                - controlCenter.batteryModeSlotWidth / 2
                                - controlCenter.batteryModeIndex * controlCenter.batteryModeSlotWidth
                                + controlCenter.batteryModeDragOffset

                            Behavior on x {
                                enabled: !controlCenter.batteryModeSliderDragging

                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Repeater {
                                model: 3

                                delegate: Item {
                                    x: index * controlCenter.batteryModeSlotWidth
                                    width: controlCenter.batteryModeSlotWidth
                                    height: tlpModeCarousel.height
                                    opacity: index === controlCenter.batteryModeIndex ? 1 : 0.42

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: index === controlCenter.batteryModeIndex ? 32 : 28
                                        height: index === controlCenter.batteryModeIndex ? 28 : 24
                                        radius: 12
                                        color: index === controlCenter.batteryModeIndex ? StyleTokens.textPrimary : "#292a2f"

                                        Text {
                                            anchors.centerIn: parent
                                            text: controlCenter.batteryModeGlyphs[index]
                                            color: index === controlCenter.batteryModeIndex ? StyleTokens.module : StyleTokens.textDim
                                            font.pixelSize: index === controlCenter.batteryModeIndex ? 15 : 13
                                            font.family: iconFontFamily
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: 22
                            height: 2
                            radius: 1
                            color: "#5d6068"
                            opacity: 0.75
                        }

                        MouseArea {
                            anchors.fill: parent
                            property real startX: 0
                            property int startIndex: 1
                            property bool moved: false

                            function clampDrag(delta) {
                                return Math.max(-controlCenter.batteryModeSlotWidth, Math.min(controlCenter.batteryModeSlotWidth, delta));
                            }

                            onPressed: function(mouse) {
                                startX = mouse.x;
                                startIndex = controlCenter.batteryModeIndex;
                                moved = false;
                                controlCenter.batteryModeInfoMessage = "";
                                controlCenter.batteryModeError = "";
                                controlCenter.batteryModeSliderDragging = true;
                                controlCenter.batteryModeDragOffset = 0;
                            }

                            onPositionChanged: function(mouse) {
                                if (!pressed)
                                    return;

                                const delta = mouse.x - startX;
                                if (!moved && Math.abs(delta) < 4)
                                    return;

                                moved = true;
                                controlCenter.batteryModeDragOffset = clampDrag(delta);
                            }

                            onReleased: function(mouse) {
                                const delta = mouse.x - startX;
                                let nextIndex = startIndex;

                                if (delta <= -18)
                                    nextIndex = Math.min(2, startIndex + 1);
                                else if (delta >= 18)
                                    nextIndex = Math.max(0, startIndex - 1);
                                else if (mouse.x < width / 2 - controlCenter.batteryModeSlotWidth / 2)
                                    nextIndex = Math.max(0, startIndex - 1);
                                else if (mouse.x > width / 2 + controlCenter.batteryModeSlotWidth / 2)
                                    nextIndex = Math.min(2, startIndex + 1);

                                controlCenter.batteryModeSliderDragging = false;
                                controlCenter.batteryModeDragOffset = 0;
                                controlCenter.selectBatteryMode(nextIndex);
                            }

                            onCanceled: {
                                controlCenter.batteryModeSliderDragging = false;
                                controlCenter.batteryModeDragOffset = 0;
                                controlCenter.setBatteryModeVisualIndex(controlCenter.batteryModeAppliedIndex, true);
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: batteryDrawer
            readonly property real cardWidth: controlCenter.drawerCardWidth
            readonly property real modeSlotWidth: 44
            readonly property real openDistance: controlCenter.connectivityHeight
                + controlCenter.detailsDrawerContentGap

            width: parent.width
            visible: controlCenter.showDetailsDrawer
            height: controlCenter.showDetailsDrawer
                ? controlCenter.detailsDrawerHandleHeight + controlCenter.detailsDrawerProgress * openDistance
                : 0
            clip: true

            Row {
                id: detailsDrawerContentRow
                anchors.left: parent.left
                anchors.right: parent.right
                y: -height + controlCenter.detailsDrawerProgress * height
                height: controlCenter.connectivityHeight
                spacing: 12
                opacity: Math.min(1, controlCenter.detailsDrawerProgress * 1.35)

                Rectangle {
                    id: drawerWifiCard
                    visible: controlCenter.quickCardInDrawer("wifi")
                    width: controlCenter.drawerCardWidth
                    height: parent.height
                    radius: 20
                    color: drawerWifiCardMouse.containsMouse ? StyleTokens.connectivityCardHover : StyleTokens.connectivityCard

                    MouseArea {
                        id: drawerWifiCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        text: wifiGlyph
                        color: wifiEnabled ? cardAccent : StyleTokens.textDisabled
                        font.pixelSize: 18
                        font.family: iconFontFamily
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        width: 34
                        height: 20
                        radius: 10
                        color: wifiEnabled ? StyleTokens.success : StyleTokens.switchOff

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            y: 2
                            x: wifiEnabled ? 16 : 2
                            color: StyleTokens.white
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: wifiSupported && wifiAvailable && !wifiBusy
                            onClicked: controlCenter.toggleWifiEnabled()
                        }
                    }

                    Item {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 8
                        height: 30

                        Text {
                            anchors.left: parent.left
                            anchors.right: drawerWifiChevron.left
                            anchors.rightMargin: 8
                            anchors.top: parent.top
                            text: "Wi-Fi"
                            color: textPrimary
                            font.pixelSize: 13
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: drawerWifiChevron.left
                            anchors.rightMargin: 8
                            anchors.bottom: parent.bottom
                            text: wifiStatusText
                            color: StyleTokens.textMuted
                            font.pixelSize: 10
                            font.family: textFontFamily
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            id: drawerWifiChevron
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: wifiPanelOpen ? "#c7c9cf" : StyleTokens.textSubtle
                            font.pixelSize: 17
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 42
                        onClicked: controlCenter.toggleConnectivityOverlay("wifi")
                    }
                }

                Rectangle {
                    id: drawerBluetoothCard
                    visible: controlCenter.quickCardInDrawer("bluetooth")
                    width: controlCenter.drawerCardWidth
                    height: parent.height
                    radius: 20
                    color: drawerBluetoothCardMouse.containsMouse ? StyleTokens.connectivityCardHover : StyleTokens.connectivityCard

                    MouseArea {
                        id: drawerBluetoothCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        text: bluetoothGlyph
                        color: bluetoothEnabled ? cardAccent : StyleTokens.textDisabled
                        font.pixelSize: 18
                        font.family: iconFontFamily
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        width: 34
                        height: 20
                        radius: 10
                        color: bluetoothEnabled ? StyleTokens.success : StyleTokens.switchOff

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            y: 2
                            x: bluetoothEnabled ? 16 : 2
                            color: StyleTokens.white
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: bluetoothAvailable && !bluetoothBusy
                            onClicked: controlCenter.toggleBluetoothEnabled()
                        }
                    }

                    Item {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 8
                        height: 30

                        Text {
                            anchors.left: parent.left
                            anchors.right: drawerBluetoothChevron.left
                            anchors.rightMargin: 8
                            anchors.top: parent.top
                            text: "Bluetooth"
                            color: textPrimary
                            font.pixelSize: 13
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.right: drawerBluetoothChevron.left
                            anchors.rightMargin: 8
                            anchors.bottom: parent.bottom
                            text: bluetoothStatusText
                            color: StyleTokens.textMuted
                            font.pixelSize: 10
                            font.family: textFontFamily
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            id: drawerBluetoothChevron
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: bluetoothPanelOpen ? "#c7c9cf" : StyleTokens.textSubtle
                            font.pixelSize: 17
                            font.family: textFontFamily
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 42
                        onClicked: controlCenter.toggleConnectivityOverlay("bluetooth")
                    }
                }

            }

            Rectangle {
                id: batteryModeCard
                visible: controlCenter.quickCardInDrawer("tlp")
                anchors.left: parent.left
                y: -height + controlCenter.detailsDrawerProgress * height
                width: batteryDrawer.cardWidth
                height: controlCenter.batteryModeCardHeight
                radius: 20
                color: StyleTokens.connectivityCard
                opacity: Math.min(1, controlCenter.detailsDrawerProgress * 1.35)
                clip: true

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.top: parent.top
                    anchors.topMargin: 11
                    text: "TLP"
                    color: textPrimary
                    font.pixelSize: 13
                    font.family: textFontFamily
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    width: Math.max(0, parent.width - 88)
                    text: controlCenter.batteryModeError.length > 0
                        ? controlCenter.batteryModeError
                        : (controlCenter.batteryModeInfoMessage.length > 0
                            ? controlCenter.batteryModeInfoMessage
                            : controlCenter.batteryModeStatusText)
                    color: controlCenter.batteryModeError.length > 0 ? StyleTokens.error : StyleTokens.textMuted
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: 9
                    font.family: textFontFamily
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Item {
                    id: batteryModeCarousel
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    height: 34
                    clip: true

                    Item {
                        id: batteryModeItems
                        width: batteryDrawer.modeSlotWidth * 3
                        height: parent.height
                        x: batteryModeCarousel.width / 2
                            - batteryDrawer.modeSlotWidth / 2
                            - controlCenter.batteryModeIndex * batteryDrawer.modeSlotWidth
                            + controlCenter.batteryModeDragOffset

                        Behavior on x {
                            enabled: !controlCenter.batteryModeSliderDragging

                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        Repeater {
                            model: 3

                            delegate: Item {
                                x: index * batteryDrawer.modeSlotWidth
                                width: batteryDrawer.modeSlotWidth
                                height: batteryModeCarousel.height
                                opacity: index === controlCenter.batteryModeIndex ? 1 : 0.42

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: index === controlCenter.batteryModeIndex ? 32 : 28
                                    height: index === controlCenter.batteryModeIndex ? 28 : 24
                                    radius: 12
                                    color: index === controlCenter.batteryModeIndex ? StyleTokens.textPrimary : "#292a2f"

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 140
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 140
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 140
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: controlCenter.batteryModeGlyphs[index]
                                        color: index === controlCenter.batteryModeIndex ? StyleTokens.module : StyleTokens.textDim
                                        font.pixelSize: index === controlCenter.batteryModeIndex ? 15 : 13
                                        font.family: iconFontFamily
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 22
                        height: 2
                        radius: 1
                        color: "#5d6068"
                        opacity: 0.75
                    }

                    MouseArea {
                        anchors.fill: parent
                        property real startX: 0
                        property int startIndex: 1
                        property bool moved: false

                        function clampDrag(delta) {
                            return Math.max(-batteryDrawer.modeSlotWidth, Math.min(batteryDrawer.modeSlotWidth, delta));
                        }

                        onPressed: function(mouse) {
                            startX = mouse.x;
                            startIndex = controlCenter.batteryModeIndex;
                            moved = false;
                            controlCenter.batteryModeInfoMessage = "";
                            controlCenter.batteryModeError = "";
                            controlCenter.batteryModeSliderDragging = true;
                            controlCenter.batteryModeDragOffset = 0;
                        }

                        onPositionChanged: function(mouse) {
                            if (!pressed)
                                return;

                            const delta = mouse.x - startX;
                            if (!moved && Math.abs(delta) < 4)
                                return;

                            moved = true;
                            controlCenter.batteryModeDragOffset = clampDrag(delta);
                        }

                        onReleased: function(mouse) {
                            const delta = mouse.x - startX;
                            let nextIndex = startIndex;

                            if (delta <= -18)
                                nextIndex = Math.min(2, startIndex + 1);
                            else if (delta >= 18)
                                nextIndex = Math.max(0, startIndex - 1);
                            else if (mouse.x < width / 2 - batteryDrawer.modeSlotWidth / 2)
                                nextIndex = Math.max(0, startIndex - 1);
                            else if (mouse.x > width / 2 + batteryDrawer.modeSlotWidth / 2)
                                nextIndex = Math.min(2, startIndex + 1);

                            controlCenter.batteryModeSliderDragging = false;
                            controlCenter.batteryModeDragOffset = 0;
                            controlCenter.selectBatteryMode(nextIndex);
                        }

                        onCanceled: {
                            controlCenter.batteryModeSliderDragging = false;
                            controlCenter.batteryModeDragOffset = 0;
                            controlCenter.setBatteryModeVisualIndex(controlCenter.batteryModeAppliedIndex, true);
                        }
                    }
                }
            }

            Rectangle {
                id: batteryDrawerTunnelShade
                anchors.left: parent.left
                anchors.top: parent.top
                width: batteryDrawer.cardWidth
                height: Math.max(1, controlCenter.detailsDrawerContentGap * 0.35)
                z: 6
                opacity: Math.min(0.34, controlCenter.detailsDrawerProgress * 0.45)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#9a000000"
                    }
                    GradientStop {
                        position: 1
                        color: StyleTokens.clearBlack
                    }
                }
            }

            Item {
                id: batteryDrawerHandle
                anchors.left: parent.left
                anchors.right: parent.right
                y: controlCenter.detailsDrawerProgress * batteryDrawer.openDistance
                height: controlCenter.detailsDrawerHandleHeight
                z: 10

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 8
                    width: 48
                    height: 5
                    radius: 3
                    color: controlCenter.detailsDrawerOpen ? "#d4d6dc" : StyleTokens.textSubtle
                    opacity: 0.88
                }

                MouseArea {
                    id: batteryDrawerHandleArea
                    anchors.fill: parent
                    property real pointerGrabOffset: 0
                    property bool moved: false
                    property bool suppressClick: false

                    function pointerY(mouse) {
                        return batteryDrawerHandle.mapToItem(controlCenter, mouse.x, mouse.y).y;
                    }

                    function itemTop(item) {
                        return item.mapToItem(controlCenter, 0, 0).y;
                    }

                    onPressed: function(mouse) {
                        detailsDrawerSettleTimer.stop();
                        controlCenter.detailsDrawerSettling = false;
                        pointerGrabOffset = pointerY(mouse) - itemTop(batteryDrawerHandle);
                        moved = false;
                        suppressClick = false;
                        controlCenter.detailsDrawerDragging = true;
                    }

                    onPositionChanged: function(mouse) {
                        const nextHandleY = pointerY(mouse) - pointerGrabOffset - itemTop(batteryDrawer);
                        if (!moved && Math.abs(nextHandleY - batteryDrawerHandle.y) < 4)
                            return;

                        moved = true;
                        suppressClick = true;
                        controlCenter.detailsDrawerProgress = controlCenter.clamp01(nextHandleY / batteryDrawer.openDistance);
                    }

                    onReleased: {
                        controlCenter.detailsDrawerDragging = false;
                        if (moved)
                            controlCenter.setDetailsDrawerOpen(controlCenter.detailsDrawerProgress >= 0.55);
                    }

                    onCanceled: {
                        controlCenter.detailsDrawerDragging = false;
                        controlCenter.setDetailsDrawerOpen(controlCenter.detailsDrawerOpen);
                    }

                    onClicked: {
                        if (suppressClick) {
                            suppressClick = false;
                            return;
                        }

                        controlCenter.toggleDetailsDrawer();
                    }
                }
            }
        }

        ControlSliderCard {
            id: brightnessCard
            width: parent.width
            height: controlCenter.showBrightness ? controlCenter.sliderCardHeight : 0
            visible: controlCenter.showBrightness
            title: "Display"
            iconText: controlCenter.brightnessIconGlyph
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            value: controlCenter.displayedBrightness
            knobSize: controlCenter.sliderKnobSize
            moduleColor: controlCenter.moduleColor
            moduleHover: controlCenter.moduleHover
            trackColor: controlCenter.trackColor
            textPrimary: controlCenter.textPrimary
            textSecondary: controlCenter.textSecondary

            onInteractionStarted: {
                if (controlCenter.sliderIntroPending) {
                    sliderIntroTimer.stop();
                    controlCenter.sliderIntroPending = false;
                    controlCenter.displayedBrightness = controlCenter.localBrightness;
                    controlCenter.displayedVolume = controlCenter.localVolume;
                }
            }
            onValueMoved: function(value) {
                controlCenter.queueBrightness(value);
            }
            onCommitRequested: {
                brightnessApplyTimer.stop();
                controlCenter.flushBrightness(true);
            }
            onCancelRequested: SystemServices.requestBrightness()
        }

        ControlSliderCard {
            id: volumeCard
            width: parent.width
            height: controlCenter.volumeSectionHeight
            visible: controlCenter.showVolume
            title: "Sound"
            iconText: controlCenter.volumeIconGlyph
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            value: controlCenter.displayedVolume
            knobSize: controlCenter.sliderKnobSize
            moduleColor: controlCenter.moduleColor
            moduleHover: controlCenter.moduleHover
            trackColor: controlCenter.trackColor
            textPrimary: controlCenter.textPrimary
            textSecondary: controlCenter.textSecondary

            onInteractionStarted: {
                if (controlCenter.sliderIntroPending) {
                    sliderIntroTimer.stop();
                    controlCenter.sliderIntroPending = false;
                    controlCenter.displayedBrightness = controlCenter.localBrightness;
                    controlCenter.displayedVolume = controlCenter.localVolume;
                }
            }
            onValueMoved: function(value) {
                controlCenter.queueVolume(value);
            }
            onCommitRequested: {
                volumeApplyTimer.stop();
                controlCenter.flushVolume(true);
            }
            onCancelRequested: SystemServices.requestVolume()
        }
    }

}
