pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs.Services

Singleton {
    id: root

    property string widgetIcon: "tune"
    property string pluginId: "volumeMixer"

    Component.onCompleted: {
        console.info("VolumeMixerService:", "Volume Mixer Service initiated");
    }

    property real savedNotificationsVolume: PluginService.loadPluginData(root.pluginId, "notifications_volume", -1)
    function saveNotificationsVolume(newVolume) {
        const isSavedSuccessfully = PluginService.savePluginData(root.pluginId, "notifications_volume", newVolume);

        if (!isSavedSuccessfully) {
            console.warn("PluginService failed to save notifications volume.");
            return false;
        }

        root.savedNotificationsVolume = newVolume;
        return true;
    }

    property var savedAppVolumeFactors: PluginService.loadPluginData(root.pluginId, "app_volume_factors", {})
    function saveVolumeFactor(appId, volumeFactor) {
        const newVolumeFactors = Object.assign({}, root.savedAppVolumeFactors, {
            [appId]: volumeFactor
        });

        const isSavedSuccessfully = PluginService.savePluginData(pluginId, "app_volume_factors", newVolumeFactors);

        if (!isSavedSuccessfully) {
            console.warn(`Failed to save volume factor for App ID: ${appId}`);
            return false;
        }

        root.savedAppVolumeFactors = newVolumeFactors;
        return true;
    }
    function getSavedVolumeFactor(sourceNode) {
        const appProcess = sourceNode.properties["application.process.binary"];
        const appId = sourceNode.name;
        const friendlyGroupName = root.getFriendlyGroupName(appProcess, appId);
        return root.savedAppVolumeFactors[friendlyGroupName] ?? 1.0;
    }

    property var savedNodeVolumes: PluginService.loadPluginData(root.pluginId, "node_volumes", {})
    function saveNodeVolumes(nodeId, nodeName, nodeVolume) {
        const nodeVolumeEntry = {
            nodeName: nodeName,
            nodeVolume: nodeVolume
        };

        const newNodeVolumes = Object.assign({}, root.savedNodeVolumes, {
            [nodeId]: nodeVolumeEntry
        });
        const isSavedSuccessfully = PluginService.savePluginData(root.pluginId, "node_volumes", newNodeVolumes);

        if (!isSavedSuccessfully) {
            console.warn(`Failed to save volume for Node ID: ${nodeId} (${nodeName})`);
            return false;
        }

        root.savedNodeVolumes = newNodeVolumes;
        return true;
    }
    function deleteNodeVolumes(nodeId) {
        if (!root.savedNodeVolumes.hasOwnProperty(nodeId)) {
            console.warn(`Attempted to delete non-existent Node ID: ${nodeId}`);
            return true;
        }

        const newNodeVolumes = Object.assign({}, root.savedNodeVolumes);
        delete newNodeVolumes[nodeId];

        const isSavedSuccessfully = PluginService.savePluginData(pluginId, "node_volumes", newNodeVolumes);

        if (!isSavedSuccessfully) {
            console.warn(`Failed to save node volumes after deleting Node ID: ${nodeId}`);
            return false;
        }

        root.savedNodeVolumes = newNodeVolumes;
        return true;
    }

    function getFriendlyGroupName(appProcess, appId) {
        let friendlyGroupName = appProcess;

        if (!friendlyGroupName) {
            return;
        }

        if (friendlyGroupName === "steamwebhelper") {
            return "Steam";
        }

        if (appProcess === null) {
            return appId;
        }
        switch (friendlyGroupName) {
        case "wine64-preloader":
        case "wine-preloader":
            if (appId) {
                friendlyGroupName = appId;
            }
            break;
        default:
            break;
        }

        const dotIndex = friendlyGroupName.indexOf('.');
        if (dotIndex !== -1) {
            friendlyGroupName = friendlyGroupName.substring(0, dotIndex);
        }

        if (friendlyGroupName.length > 0) {
            const firstLetter = friendlyGroupName.charAt(0).toUpperCase();
            const restOfString = friendlyGroupName.slice(1);

            friendlyGroupName = firstLetter + restOfString;
        }

        return friendlyGroupName;
    }

    property var activeNodeDelegates: ({})
    function triggerFactorUpdate(nodeId, volumeFactor) {
        const delegate = activeNodeDelegates[nodeId.toString()];
        if (delegate) {
            delegate.applyFactorToStream(volumeFactor, true);
        } else {
            console.warn(`Attempted to update non-existent delegate for Node ID: ${nodeId}`);
        }
    }

    Timer {
        id: updateTimer
        interval: 100
        repeat: false
        onTriggered: {
            root.sourceNodesByApp = newSourceNodesByAppDelayed;
            root.allNodesEntries = newAllNodesEntriesDelayed;

            newSourceNodesByAppDelayed = undefined;
            newAllNodesEntriesDelayed = undefined;
        }

        property var newSourceNodesByAppDelayed: ({})
        property var newAllNodesEntriesDelayed: ([])
    }

    property var sourceNodesByApp: ({})
    property list<var> allNodesEntries: []

    PwNodeLinkTracker {
        id: nodeLinkTracker
        node: AudioService.sink
        onLinkGroupsChanged: {
            const newSourceNodesByApp = {};
            const newAllNodesEntries = [];
            const allNodesIds = [];

            for (let i = 0; i < linkGroups.length; i++) {
                const sourceNode = linkGroups[i].source;
                const sourceNodeId = sourceNode.id;
                const appId = sourceNode.name;
                const appIconId = sourceNode.properties["pipewire.access.portal.app_id"] || sourceNode.properties["application.process.binary"] || sourceNode.name;

                if (sourceNode.name === "quickshell" || sourceNode.name === "") {
                    continue;
                }

                if (!newSourceNodesByApp[appId]) {
                    newSourceNodesByApp[appId] = {
                        nodesById: {}
                    };
                }

                const nodeEntry = {
                    node: sourceNode,
                    isSliderTriggered: false
                };

                newSourceNodesByApp[appId].nodesById[sourceNodeId] = nodeEntry;
                newAllNodesEntries.push(nodeEntry);
                allNodesIds.push(sourceNodeId.toString());
            }

            updateTimer.newSourceNodesByAppDelayed = newSourceNodesByApp;
            updateTimer.newAllNodesEntriesDelayed = newAllNodesEntries;

            updateTimer.start();

            const savedNodeVolumesIds = Object.keys(root.savedNodeVolumes);
            for (let i = 0; i < savedNodeVolumesIds.length; i++) {
                const savedId = savedNodeVolumesIds[i];

                if (!allNodesIds.includes(savedId)) {
                    deleteNodeVolumes(savedId);
                }
            }
        }
    }

    PwObjectTracker {
        objects: nodeLinkTracker.linkGroups.map(linkGroup => linkGroup.source)
    }

    Instantiator {
        model: root.allNodesEntries

        delegate: Item {
            required property int index
            required property var modelData
            property PwNode sourceNode: modelData.node
            property real streamVolume: sourceNode.audio ? sourceNode.audio.volume : 0.0
            property bool skipFactorMultiplication: true
            property real originalAppVolume: 1.0
            property string nodeId: sourceNode.id.toString()

            onStreamVolumeChanged: {
                if (Number.isNaN(streamVolume)) {
                    setStreamVolume(0, true);
                }

                if (skipFactorMultiplication) {
                    skipFactorMultiplication = false;
                    return;
                }

                const savedFactor = root.getSavedVolumeFactor(sourceNode);

                originalAppVolume = streamVolume;
                root.saveNodeVolumes(nodeId, sourceNode.name, originalAppVolume);

                applyFactorToStream(savedFactor, false);
            }

            function setStreamVolume(newVolume, preventFactorLoop) {
                skipFactorMultiplication = preventFactorLoop;

                sourceNode.audio.volume = newVolume;
            }

            function applyFactorToStream(volumeFactor, preventFactorLoop) {
                const appProcess = sourceNode.properties["application.process.binary"];
                let newVolume;

                if (appProcess === "wine-preloader" || appProcess === "wine64-preloader") {
                    newVolume = volumeFactor;
                    setStreamVolume(newVolume, preventFactorLoop);
                    return;
                }

                newVolume = originalAppVolume * volumeFactor;
                setStreamVolume(newVolume, preventFactorLoop);

                const friendlyGroupName = root.getFriendlyGroupName(appProcess, sourceNode.name);
                root.saveVolumeFactor(friendlyGroupName, volumeFactor);
            }

            function restoreVolumeOnStartup() {
                const savedData = root.savedNodeVolumes[nodeId];
                const savedFactor = root.getSavedVolumeFactor(sourceNode);
                const appProcess = sourceNode.properties["application.process.binary"];

                if (appProcess === "wine-preloader" || appProcess === "wine64-preloader") {
                    newVolume = volumeFactor;
                    setStreamVolume(newVolume, preventFactorLoop);
                    return;
                }

                if (savedData) {
                    originalAppVolume = savedData.nodeVolume;
                    const finalStreamVolume = originalAppVolume * savedFactor;

                    setStreamVolume(finalStreamVolume, true);
                } else {
                    originalAppVolume = streamVolume;
                    root.saveNodeVolumes(nodeId, sourceNode.name, originalAppVolume);

                    if (savedFactor !== 1.0) {
                        applyFactorToStream(savedFactor, true);
                    }
                }
            }

            Component.onCompleted: {
                root.activeNodeDelegates[nodeId] = this;

                restoreVolumeOnStartup();
            }

            Component.onDestruction: {
                delete root.activeNodeDelegates[nodeId];
            }
        }
    }
}
