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
    readonly property string rangeConfigurationKey: [controller.faceConfiguration.percentRangeMode, controller.faceConfiguration.byteRangeMode, controller.faceConfiguration.byteRateRangeMode, controller.faceConfiguration.frequencyRangeMode, controller.faceConfiguration.timeRangeMode, controller.faceConfiguration.bitRateRangeMode, controller.faceConfiguration.voltageRangeMode, controller.faceConfiguration.temperatureRangeMode, controller.faceConfiguration.powerRangeMode, controller.faceConfiguration.energyRangeMode, controller.faceConfiguration.currentRangeMode, controller.faceConfiguration.decibelRangeMode, controller.faceConfiguration.rateRangeMode, controller.faceConfiguration.rpmRangeMode, controller.faceConfiguration.otherRangeMode, controller.faceConfiguration.sensorRangeOverrides].join("|")
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

    function rangeModeConfig(name, legacyNormalizationName, legacyBoolName, defaultValue) {
        const mode = chart.controller.faceConfiguration[name];
        if (mode !== undefined)
            return Number(mode);

        const legacyNormalization = chart.controller.faceConfiguration[legacyNormalizationName];
        if (legacyNormalization !== undefined) {
            const legacyMode = Number(legacyNormalization);
            if (legacyMode === 1)
                return 1;

            if (legacyMode === 2)
                return 2;

            if (legacyNormalization === "minMax")
                return 2;

            if (legacyNormalization === "zeroMax")
                return 0;

            return 0;
        }
        if (legacyBoolName.length > 0) {
            const legacyValue = chart.controller.faceConfiguration[legacyBoolName];
            if (legacyValue !== undefined)
                return legacyValue ? 2 : 0;

        }
        return defaultValue;
    }

    function rangeOverrides() {
        try {
            const parsed = JSON.parse(chart.controller.faceConfiguration.sensorRangeOverrides || "{}");
            return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {
            };
        } catch (error) {
            return {
            };
        }
    }

    function sensorOverride(sensorIndex) {
        const sensorId = rawSensorsModel.sensors[sensorIndex] ?? "";
        const override = rangeOverrides()[sensorId];
        if (!override || typeof override !== "object")
            return null;

        const mode = Number(override.mode);
        return isFinite(mode) && mode >= 0 ? override : null;
    }

    function customOverrideValue(override, key) {
        const value = Number(override ? override[key] : undefined);
        return isFinite(value) ? value : undefined;
    }

    function rangeModeName(mode, hasOverride) {
        if (mode === 0)
            return "zeroSensorMaximum";

        if (mode === 1)
            return "zeroHistoryMaximum";

        if (mode === 2)
            return "historyRange";

        if (mode === 3)
            return "historyMinimumSensorMaximum";

        if (mode === 4)
            return "sensorRange";

        if (mode === 5 && hasOverride)
            return "customRange";

        if (mode === 5 || mode === 6)
            return "sensorMinimumHistoryMaximum";

        return "unitDefault";
    }

    function isUnitFamily(unit, baseUnit) {
        return unit >= baseUnit && unit <= baseUnit + Formatter.Units.MetricPrefixLast;
    }

    function unitRangeMode(sensorIndex) {
        const sensorId = rawSensorsModel.sensors[sensorIndex] ?? "";
        const name = sensorId.split("/").pop();
        const unit = sensorUnit(sensorIndex);
        if (unit === Formatter.Units.UnitPercent)
            return rangeModeConfig("percentRangeMode", "percentNormalizationMode", "", 4);

        if (isUnitFamily(unit, Formatter.Units.UnitByte))
            return rangeModeConfig("byteRangeMode", "byteNormalizationMode", "", 4);

        if (isUnitFamily(unit, Formatter.Units.UnitByteRate))
            return rangeModeConfig("byteRateRangeMode", "byteRateNormalizationMode", "", 4);

        if (isUnitFamily(unit, Formatter.Units.UnitHertz) || name === "coreFrequency" || name === "memoryFrequency")
            return rangeModeConfig("frequencyRangeMode", "frequencyNormalizationMode", "minMaxNormalizeFrequency", 4);

        if (unit === Formatter.Units.UnitBootTimestamp || unit === Formatter.Units.UnitSecond || unit === Formatter.Units.UnitTime || unit === Formatter.Units.UnitTicks || unit === Formatter.Units.UnitDuration)
            return rangeModeConfig("timeRangeMode", "timeNormalizationMode", "", 4);

        if (isUnitFamily(unit, Formatter.Units.UnitBitRate))
            return rangeModeConfig("bitRateRangeMode", "bitRateNormalizationMode", "", 4);

        if (isUnitFamily(unit, Formatter.Units.UnitVolt))
            return rangeModeConfig("voltageRangeMode", "voltageNormalizationMode", "", 4);

        if (isUnitFamily(unit, Formatter.Units.UnitWatt) || name === "power")
            return rangeModeConfig("powerRangeMode", "powerNormalizationMode", "minMaxNormalizePower", 4);

        if (isUnitFamily(unit, Formatter.Units.UnitWattHour))
            return rangeModeConfig("energyRangeMode", "energyNormalizationMode", "", 4);

        if (isUnitFamily(unit, Formatter.Units.UnitAmpere))
            return rangeModeConfig("currentRangeMode", "currentNormalizationMode", "", 4);

        if (unit === Formatter.Units.UnitCelsius || name === "temperature")
            return rangeModeConfig("temperatureRangeMode", "temperatureNormalizationMode", "minMaxNormalizeTemperature", 4);

        if (unit === Formatter.Units.UnitDecibelMilliWatts)
            return rangeModeConfig("decibelRangeMode", "decibelNormalizationMode", "", 4);

        if (unit === Formatter.Units.UnitRate)
            return rangeModeConfig("rateRangeMode", "rateNormalizationMode", "", 4);

        if (unit === Formatter.Units.UnitRpm)
            return rangeModeConfig("rpmRangeMode", "rpmNormalizationMode", "", 4);

        return rangeModeConfig("otherRangeMode", "otherNormalizationMode", "", 4);
    }

    function rangeMode(sensorIndex) {
        const override = sensorOverride(sensorIndex);
        if (override)
            return Number(override.mode);

        return unitRangeMode(sensorIndex);
    }

    function metadataMaximum(sensorIndex) {
        const liveSensor = sensorObject(sensorIndex);
        const maximum = Number(liveSensor && liveSensor.maximum !== undefined ? liveSensor.maximum : rawSensorsModel.headerData(sensorIndex, Qt.Horizontal, Sensors.SensorDataModel.Maximum) ?? 0);
        return isFinite(maximum) && maximum > 0 ? maximum : 0;
    }

    function metadataMinimum(sensorIndex) {
        const liveSensor = sensorObject(sensorIndex);
        const minimum = Number(liveSensor && liveSensor.minimum !== undefined ? liveSensor.minimum : rawSensorsModel.headerData(sensorIndex, Qt.Horizontal, Sensors.SensorDataModel.Minimum) ?? 0);
        return isFinite(minimum) ? minimum : 0;
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

    function historyBounds(sensorIndex) {
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
        return {
            "minimum": minimum,
            "maximum": maximum
        };
    }

    function historyMaximum(sensorIndex) {
        const maximum = historyBounds(sensorIndex).maximum;
        return isFinite(maximum) ? maximum : 1;
    }

    function preferredMaximumFallback(sensorIndex) {
        if (sensorUnit(sensorIndex) === Formatter.Units.UnitPercent)
            return 100;

        return historyMaximum(sensorIndex);
    }

    function sensorMaximum(sensorIndex, minimum) {
        const maximum = metadataMaximum(sensorIndex);
        if (maximum > minimum)
            return maximum;

        const fallback = preferredMaximumFallback(sensorIndex);
        return fallback > minimum ? fallback : minimum + 1;
    }

    function saneRange(minimum, maximum, sensorIndex) {
        let safeMinimum = isFinite(minimum) ? minimum : 0;
        let safeMaximum = isFinite(maximum) ? maximum : preferredMaximumFallback(sensorIndex);
        if (safeMaximum <= safeMinimum) {
            const history = historyBounds(sensorIndex);
            if (history.maximum > safeMinimum)
                safeMaximum = history.maximum;

        }
        if (safeMaximum <= safeMinimum) {
            const padding = Math.max(Math.abs(safeMaximum) * 0.05, 1);
            safeMinimum = Math.max(0, safeMinimum - padding);
            safeMaximum = safeMaximum + padding;
        }
        return {
            "minimum": safeMinimum,
            "maximum": safeMaximum
        };
    }

    function scaleRange(sensorIndex) {
        const override = sensorOverride(sensorIndex);
        const mode = rangeMode(sensorIndex);
        const history = historyBounds(sensorIndex);
        if (mode === 0)
            return saneRange(0, sensorMaximum(sensorIndex, 0), sensorIndex);

        if (mode === 1)
            return saneRange(0, history.maximum, sensorIndex);

        if (mode === 2)
            return saneRange(history.minimum, history.maximum, sensorIndex);

        if (mode === 3)
            return saneRange(history.minimum, sensorMaximum(sensorIndex, history.minimum), sensorIndex);

        if (mode === 4) {
            const minimum = metadataMinimum(sensorIndex);
            return saneRange(minimum, sensorMaximum(sensorIndex, minimum), sensorIndex);
        }
        if (mode === 5 && override) {
            const minimum = customOverrideValue(override, "customMinimum");
            const maximum = customOverrideValue(override, "customMaximum");
            return saneRange(minimum, maximum, sensorIndex);
        }
        if (mode === 5 || mode === 6)
            return saneRange(metadataMinimum(sensorIndex), history.maximum, sensorIndex);

        return saneRange(0, sensorMaximum(sensorIndex, 0), sensorIndex);
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
                "mode": rangeModeName(rangeMode(sensorIndex), sensorOverride(sensorIndex) !== null),
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
    onRangeConfigurationKeyChanged: rebuildHistoryModel()
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
