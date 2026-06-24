/*
    SPDX-FileCopyrightText: 2026 nicolindenlauf
    SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.faces as Faces
import org.kde.ksysguard.formatter as Formatter
import org.kde.ksysguard.sensors as Sensors
import org.kde.quickcharts as Charts

Charts.LineChart {
    id: chart

    property var controller
    property var rawHistory: []
    property var liveSensors: []
    property var scaleItems: []
    property real lastSampleTime: 0
    property int desiredScaleTickCount: 5
    property int scaleRevision: 0
    readonly property alias sensorsModel: rawSensorsModel
    readonly property int chartUnit: Formatter.Units.UnitPercent
    readonly property int historyAmount: controller.faceConfiguration.historyAmount
    readonly property int sampleInterval: {
        if (chart.controller.updateRateLimit > 0)
            return chart.controller.updateRateLimit;

        if (rawSensorsModel.ready && rawSensorsModel.sensors.length > 0) {
            const interval = Number(rawSensorsModel.headerData(0, Qt.Horizontal, Sensors.SensorDataModel.UpdateInterval) ?? 0);
            return interval > 0 ? interval : 1000;
        }
        return 1000;
    }
    readonly property int maxHistoryPoints: sampleInterval > 0 ? Math.max(2, Math.round((historyAmount * 1000) / sampleInterval)) : 60

    function clampPercent(value) {
        return Math.max(0, Math.min(100, value));
    }

    function sensorObject(sensorIndex) {
        if (sensorIndex < 0 || sensorIndex >= liveSensors.length)
            return null;

        return liveSensors[sensorIndex] || null;
    }

    function normalizationMode(name, legacyBoolName, defaultValue) {
        const mode = chart.controller.faceConfiguration[name];
        if (mode === "minMax")
            return name === "percentNormalizationMode" ? 2 : 1;

        if (mode === "zeroMax")
            return name === "percentNormalizationMode" ? 1 : 0;

        if (mode !== undefined)
            return Number(mode);

        const legacyValue = chart.controller.faceConfiguration[legacyBoolName];
        if (legacyValue !== undefined)
            return legacyValue ? 1 : 0;

        return defaultValue;
    }

    function percentNormalizationMode() {
        return normalizationMode("percentNormalizationMode", "", 0);
    }

    function twoModeNormalization(name, legacyBoolName, defaultValue) {
        const mode = chart.controller.faceConfiguration[name];
        if (mode === "minMax")
            return 1;

        if (mode === "zeroMax")
            return 0;

        if (mode !== undefined)
            return Number(mode);

        const legacyValue = chart.controller.faceConfiguration[legacyBoolName];
        if (legacyValue !== undefined)
            return legacyValue ? 1 : 0;

        return defaultValue;
    }

    function isUnitFamily(unit, baseUnit) {
        return unit >= baseUnit && unit <= baseUnit + Formatter.Units.MetricPrefixLast;
    }

    function percentScaleMode() {
        const mode = percentNormalizationMode();
        if (mode === 1)
            return "historyMaximum";

        if (mode === 2)
            return "historyRange";

        return "fixedPercent";
    }

    function unitNormalizationMode(sensorIndex) {
        const sensorId = rawSensorsModel.sensors[sensorIndex] ?? "";
        const name = sensorId.split("/").pop();
        const unit = sensorUnit(sensorIndex);
        if (unit === Formatter.Units.UnitPercent)
            return percentNormalizationMode();

        if (isUnitFamily(unit, Formatter.Units.UnitByte))
            return twoModeNormalization("byteNormalizationMode", "", 0);

        if (isUnitFamily(unit, Formatter.Units.UnitByteRate))
            return twoModeNormalization("byteRateNormalizationMode", "", 0);

        if (isUnitFamily(unit, Formatter.Units.UnitHertz) || name === "coreFrequency" || name === "memoryFrequency")
            return twoModeNormalization("frequencyNormalizationMode", "minMaxNormalizeFrequency", 1);

        if (unit === Formatter.Units.UnitBootTimestamp || unit === Formatter.Units.UnitSecond || unit === Formatter.Units.UnitTime || unit === Formatter.Units.UnitTicks || unit === Formatter.Units.UnitDuration)
            return twoModeNormalization("timeNormalizationMode", "", 0);

        if (isUnitFamily(unit, Formatter.Units.UnitBitRate))
            return twoModeNormalization("bitRateNormalizationMode", "", 0);

        if (isUnitFamily(unit, Formatter.Units.UnitVolt))
            return twoModeNormalization("voltageNormalizationMode", "", 0);

        if (isUnitFamily(unit, Formatter.Units.UnitWatt) || name === "power")
            return twoModeNormalization("powerNormalizationMode", "minMaxNormalizePower", 1);

        if (isUnitFamily(unit, Formatter.Units.UnitWattHour))
            return twoModeNormalization("energyNormalizationMode", "", 0);

        if (isUnitFamily(unit, Formatter.Units.UnitAmpere))
            return twoModeNormalization("currentNormalizationMode", "", 0);

        if (unit === Formatter.Units.UnitCelsius || name === "temperature")
            return twoModeNormalization("temperatureNormalizationMode", "minMaxNormalizeTemperature", 1);

        if (unit === Formatter.Units.UnitDecibelMilliWatts)
            return twoModeNormalization("decibelNormalizationMode", "", 1);

        if (unit === Formatter.Units.UnitRate)
            return twoModeNormalization("rateNormalizationMode", "", 0);

        if (unit === Formatter.Units.UnitRpm)
            return twoModeNormalization("rpmNormalizationMode", "", 0);

        return twoModeNormalization("otherNormalizationMode", "", 0);
    }

    function scaleMode(sensorIndex) {
        if (sensorUnit(sensorIndex) === Formatter.Units.UnitPercent)
            return percentScaleMode();

        return unitNormalizationMode(sensorIndex) === 1 ? "historyRange" : "historyMaximum";
    }

    function metadataMaximum(sensorIndex) {
        const liveSensor = sensorObject(sensorIndex);
        const maximum = Number(liveSensor && liveSensor.maximum !== undefined ? liveSensor.maximum : rawSensorsModel.headerData(sensorIndex, Qt.Horizontal, Sensors.SensorDataModel.Maximum) ?? 0);
        return isFinite(maximum) && maximum > 0 ? maximum : 0;
    }

    function rawValue(sensorIndex) {
        const liveSensor = sensorObject(sensorIndex);
        if (liveSensor && liveSensor.value !== undefined && liveSensor.value !== null) {
            const liveValue = Number(liveSensor.value);
            if (!isNaN(liveValue))
                return liveValue;

        }
        if (!rawSensorsModel.ready || sensorIndex < 0 || sensorIndex >= rawSensorsModel.sensors.length)
            return 0;

        const modelIndex = rawSensorsModel.index(0, sensorIndex);
        return Number(rawSensorsModel.data(modelIndex, Sensors.SensorDataModel.Value) ?? 0);
    }

    function fixedMaximum(sensorIndex) {
        const maximum = metadataMaximum(sensorIndex);
        return maximum > 0 ? maximum : historyMaximum(sensorIndex);
    }

    function sensorUnit(sensorIndex) {
        const liveSensor = sensorObject(sensorIndex);
        return Number(liveSensor && liveSensor.unit !== undefined ? liveSensor.unit : rawSensorsModel.headerData(sensorIndex, Qt.Horizontal, Sensors.SensorDataModel.Unit) ?? Formatter.Units.UnitInvalid);
    }

    function sensorLabel(sensorIndex) {
        const sensorId = rawSensorsModel.sensors[sensorIndex] ?? "";
        if (chart.controller.sensorLabels && chart.controller.sensorLabels[sensorId])
            return chart.controller.sensorLabels[sensorId];

        const liveSensor = sensorObject(sensorIndex);
        if (liveSensor && liveSensor.shortName)
            return liveSensor.shortName;

        if (liveSensor && liveSensor.name)
            return liveSensor.name;

        return sensorId.split("/").pop();
    }

    function historyMaximum(sensorIndex) {
        let maximum = 0;
        for (let i = 0; i < rawHistory.length; ++i) {
            maximum = Math.max(maximum, Number(rawHistory[i][sensorIndex]) || 0);
        }
        return maximum > 0 ? maximum : 1;
    }

    function historyRange(sensorIndex) {
        let minimum = Infinity;
        let maximum = -Infinity;
        for (let i = 0; i < rawHistory.length; ++i) {
            const value = Number(rawHistory[i][sensorIndex]);
            if (!isFinite(value))
                continue;

            minimum = Math.min(minimum, value);
            maximum = Math.max(maximum, value);
        }
        if (minimum === Infinity || maximum === -Infinity) {
            const value = rawValue(sensorIndex);
            minimum = value;
            maximum = value;
        }
        if (maximum <= minimum) {
            const padding = Math.max(Math.abs(maximum) * 0.05, 1);
            minimum = Math.max(0, minimum - padding);
            maximum = maximum + padding;
        }
        return {
            "minimum": minimum,
            "maximum": maximum
        };
    }

    function scaleRange(sensorIndex) {
        const mode = scaleMode(sensorIndex);
        if (mode === "fixedPercent")
            return {
            "minimum": 0,
            "maximum": 100
        };

        if (mode === "fixedMaximum")
            return {
            "minimum": 0,
            "maximum": fixedMaximum(sensorIndex)
        };

        if (mode === "historyRange")
            return historyRange(sensorIndex);

        return {
            "minimum": 0,
            "maximum": fixedMaximum(sensorIndex)
        };
    }

    function normalizedValue(value, sensorIndex) {
        const range = scaleRange(sensorIndex);
        const span = range.maximum - range.minimum;
        if (span <= 0)
            return 50;

        return clampPercent(((value - range.minimum) / span) * 100);
    }

    function niceStep(span) {
        if (span <= 0)
            return 1;

        const rawStep = span / Math.max(1, desiredScaleTickCount - 1);
        const magnitude = Math.pow(10, Math.floor(Math.log(rawStep) / Math.LN10));
        const residual = rawStep / magnitude;
        if (residual <= 1)
            return magnitude;

        if (residual <= 2)
            return 2 * magnitude;

        if (residual <= 2.5)
            return 2.5 * magnitude;

        if (residual <= 5)
            return 5 * magnitude;

        return 10 * magnitude;
    }

    function formatScaleValue(value, unit) {
        if (unit === Formatter.Units.UnitCelsius)
            return Math.round(value) + " C";

        return Formatter.Formatter.formatValueShowNull(value, unit);
    }

    function scaleTicks(minimum, maximum, unit) {
        let safeMinimum = isFinite(minimum) ? minimum : 0;
        let safeMaximum = isFinite(maximum) ? maximum : safeMinimum + 1;
        if (safeMaximum <= safeMinimum) {
            const padding = Math.max(Math.abs(safeMaximum) * 0.05, 1);
            safeMinimum = Math.max(0, safeMinimum - padding);
            safeMaximum = safeMaximum + padding;
        }
        const span = safeMaximum - safeMinimum;
        const step = niceStep(span);
        const epsilon = step / 1000;
        const ticks = [{
            "label": formatScaleValue(safeMinimum, unit),
            "percent": 0
        }];
        let first = Math.ceil(safeMinimum / step) * step;
        if (first <= safeMinimum + epsilon)
            first += step;

        for (let value = first; value < safeMaximum - epsilon; value += step) {
            ticks.push({
                "label": formatScaleValue(value, unit),
                "percent": clampPercent(((value - safeMinimum) / span) * 100)
            });
            if (ticks.length > 8)
                break;

        }
        if (ticks[ticks.length - 1].percent < 99.5)
            ticks.push({
            "label": formatScaleValue(safeMaximum, unit),
            "percent": 100
        });

        return ticks;
    }

    function rebuildScaleItems() {
        const items = [];
        for (let sensorIndex = 0; sensorIndex < rawSensorsModel.sensors.length; ++sensorIndex) {
            const sensorId = rawSensorsModel.sensors[sensorIndex];
            const range = scaleRange(sensorIndex);
            const unit = sensorUnit(sensorIndex);
            items.push({
                "sensorId": sensorId,
                "label": sensorLabel(sensorIndex),
                "color": root.colorSource.map[sensorId] ?? Kirigami.Theme.textColor,
                "minimum": range.minimum,
                "maximum": range.maximum,
                "unit": unit,
                "mode": scaleMode(sensorIndex),
                "ticks": scaleTicks(range.minimum, range.maximum, unit)
            });
        }
        scaleItems = items;
        ++scaleRevision;
    }

    function trimHistory() {
        if (rawHistory.length > maxHistoryPoints)
            rawHistory = rawHistory.slice(rawHistory.length - maxHistoryPoints);

    }

    function rebuildHistoryModel() {
        historyModel.clear();
        // Keep samples oldest-first so startup fills left-to-right; once the
        // history is full, trimHistory() drops old samples and the graph scrolls.
        for (let row = 0; row < rawHistory.length; ++row) {
            const item = {
            };
            for (let sensorIndex = 0; sensorIndex < rawSensorsModel.sensors.length; ++sensorIndex) {
                item["series" + sensorIndex] = normalizedValue(Number(rawHistory[row][sensorIndex]) || 0, sensorIndex);
            }
            historyModel.append(item);
        }
        rebuildScaleItems();
    }

    function sample(force) {
        if (!rawSensorsModel.ready || rawSensorsModel.sensors.length === 0)
            return ;

        const now = Date.now();
        if (!force && lastSampleTime > 0 && now - lastSampleTime < Math.max(100, sampleInterval * 0.35))
            return ;

        const row = [];
        for (let sensorIndex = 0; sensorIndex < rawSensorsModel.sensors.length; ++sensorIndex) {
            row.push(rawValue(sensorIndex));
        }
        rawHistory = rawHistory.concat([row]);
        lastSampleTime = now;
        trimHistory();
        rebuildHistoryModel();
    }

    function resetHistory() {
        rawHistory = [];
        lastSampleTime = 0;
        historyModel.clear();
        sample(true);
    }

    direction: Charts.XYChart.ZeroAtStart
    fillOpacity: controller.faceConfiguration.lineChartFillOpacity / 100
    stacked: false
    interpolate: controller.faceConfiguration.lineChartSmooth
    onMaxHistoryPointsChanged: {
        trimHistory();
        rebuildHistoryModel();
    }
    onDesiredScaleTickCountChanged: rebuildScaleItems()
    colorSource: root.colorSource

    yRange {
        from: 0
        to: 100
        automatic: false
    }

    xRange {
        from: 0
        to: Math.max(1, chart.maxHistoryPoints - 1)
        automatic: false
    }

    Sensors.SensorDataModel {
        id: rawSensorsModel

        property int unit: Formatter.Units.UnitPercent

        sensors: chart.controller.highPrioritySensorIds
        updateRateLimit: chart.controller.updateRateLimit
        sensorLabels: chart.controller.sensorLabels
    }

    ListModel {
        id: historyModel

        dynamicRoles: true
    }

    Timer {
        interval: Math.max(250, chart.sampleInterval)
        running: rawSensorsModel.ready
        repeat: true
        triggeredOnStart: true
        onTriggered: chart.sample()
    }

    Connections {
        function onDataChanged() {
            chart.sample();
        }

        function onReadyChanged() {
            chart.resetHistory();
        }

        function onSensorsChanged() {
            chart.resetHistory();
        }

        function onSensorMetaDataChanged() {
            chart.rebuildHistoryModel();
        }

        target: rawSensorsModel
    }

    Instantiator {
        id: liveSensorInstantiator

        model: rawSensorsModel.sensors
        onObjectAdded: (index, object) => {
            const sensors = chart.liveSensors.slice();
            sensors[index] = object;
            chart.liveSensors = sensors;
            chart.rebuildScaleItems();
            chart.sample(true);
        }
        onObjectRemoved: (index, object) => {
            const sensors = chart.liveSensors.slice();
            sensors.splice(index, 1);
            chart.liveSensors = sensors;
            chart.resetHistory();
        }

        delegate: Sensors.Sensor {
            sensorId: modelData
            updateRateLimit: chart.controller.updateRateLimit
            onValueChanged: chart.sample()
            onMetaDataChanged: {
                chart.rebuildScaleItems();
                chart.sample();
            }
        }

    }

    Instantiator {
        model: rawSensorsModel.sensors
        onObjectAdded: (index, object) => {
            chart.insertValueSource(index, object);
        }
        onObjectRemoved: (index, object) => {
            chart.removeValueSource(object);
        }

        delegate: Charts.ModelSource {
            model: historyModel
            roleName: "series" + index
        }

    }

    nameSource: Charts.ModelSource {
        roleName: "Name"
        model: rawSensorsModel
        indexColumns: true
    }

    shortNameSource: Charts.ModelSource {
        roleName: "ShortName"
        model: rawSensorsModel
        indexColumns: true
    }

}
