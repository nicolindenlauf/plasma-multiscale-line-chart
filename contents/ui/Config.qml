/*
    SPDX-FileCopyrightText: 2026 nicolindenlauf
    SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.faces as Faces
import org.kde.ksysguard.sensors as Sensors

Kirigami.FormLayout {
    id: root

    property alias cfg_showLegend: showSensorsLegendCheckbox.checked
    property alias cfg_lineChartFillOpacity: fillOpacitySpin.value
    property alias cfg_lineChartSmooth: smoothCheckbox.checked
    property alias cfg_showGridLines: showGridLinesCheckbox.checked
    property alias cfg_showYAxisLabels: showYAxisLabelsCheckbox.checked
    property alias cfg_scaleTickCount: scaleTickCountSpin.value
    property alias cfg_scaleGridOpacity: scaleGridOpacitySpin.value
    property alias cfg_scaleLabelOpacity: scaleLabelOpacitySpin.value
    property alias cfg_percentRangeMode: percentRangeCombo.currentIndex
    property alias cfg_byteRangeMode: byteRangeCombo.currentIndex
    property alias cfg_byteRateRangeMode: byteRateRangeCombo.currentIndex
    property alias cfg_frequencyRangeMode: frequencyRangeCombo.currentIndex
    property alias cfg_timeRangeMode: timeRangeCombo.currentIndex
    property alias cfg_bitRateRangeMode: bitRateRangeCombo.currentIndex
    property alias cfg_voltageRangeMode: voltageRangeCombo.currentIndex
    property alias cfg_temperatureRangeMode: temperatureRangeCombo.currentIndex
    property alias cfg_powerRangeMode: powerRangeCombo.currentIndex
    property alias cfg_energyRangeMode: energyRangeCombo.currentIndex
    property alias cfg_currentRangeMode: currentRangeCombo.currentIndex
    property alias cfg_decibelRangeMode: decibelRangeCombo.currentIndex
    property alias cfg_rateRangeMode: rateRangeCombo.currentIndex
    property alias cfg_rpmRangeMode: rpmRangeCombo.currentIndex
    property alias cfg_otherRangeMode: otherRangeCombo.currentIndex
    property alias cfg_historyAmount: historySpin.value
    property string cfg_sensorRangeOverrides: "{}"
    property var sensorRangeOverrides: ({
    })

    function parseOverrides() {
        try {
            const parsed = JSON.parse(root.cfg_sensorRangeOverrides || "{}");
            root.sensorRangeOverrides = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {
            };
        } catch (error) {
            root.sensorRangeOverrides = {
            };
        }
    }

    function copyObject(object) {
        const copy = {
        };
        if (!object)
            return copy;

        for (const key in object) {
            copy[key] = object[key];
        }
        return copy;
    }

    function sensorLabel(sensorId, sensor) {
        if (controller.sensorLabels && controller.sensorLabels[sensorId])
            return controller.sensorLabels[sensorId];

        if (sensor && sensor.shortName)
            return sensor.shortName;

        if (sensor && sensor.name)
            return sensor.name;

        return sensorId.split("/").pop();
    }

    function sensorOverride(sensorId) {
        const override = root.sensorRangeOverrides ? root.sensorRangeOverrides[sensorId] : undefined;
        return override && typeof override === "object" ? override : {
        };
    }

    function sensorOverrideMode(sensorId) {
        const mode = Number(sensorOverride(sensorId).mode);
        return isFinite(mode) ? mode : -1;
    }

    function sensorOverrideCustomValue(sensorId, key) {
        const value = Number(sensorOverride(sensorId)[key]);
        return isFinite(value) ? String(value) : "";
    }

    function numberFromText(text) {
        const value = Number(String(text).replace(",", "."));
        return isFinite(value) ? value : undefined;
    }

    function setSensorOverride(sensorId, values) {
        const overrides = copyObject(root.sensorRangeOverrides);
        const current = copyObject(overrides[sensorId]);
        for (const key in values) {
            current[key] = values[key];
        }
        const mode = Number(current.mode);
        if (!isFinite(mode) || mode < 0) {
            delete overrides[sensorId];
        } else {
            current.mode = mode;
            overrides[sensorId] = current;
        }
        root.sensorRangeOverrides = overrides;
        root.cfg_sensorRangeOverrides = JSON.stringify(overrides);
    }

    onCfg_sensorRangeOverridesChanged: parseOverrides()
    Component.onCompleted: parseOverrides()

    Item {
        Kirigami.FormData.label: i18nc("@title:group", "Appearance")
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: showSensorsLegendCheckbox

        text: i18nc("@option:check", "Show legend")
    }

    QQC2.CheckBox {
        id: smoothCheckbox

        text: i18nc("@option:check", "Smooth lines")
    }

    QQC2.CheckBox {
        id: showGridLinesCheckbox

        text: i18nc("@option:check", "Show grid lines")
    }

    QQC2.CheckBox {
        id: showYAxisLabelsCheckbox

        text: i18nc("@option:check", "Show scale labels")
    }

    QQC2.SpinBox {
        id: fillOpacitySpin

        Kirigami.FormData.label: i18nc("@label:spinbox", "Opacity of area below line:")
        editable: true
        from: 0
        to: 100
    }

    QQC2.SpinBox {
        id: scaleTickCountSpin

        Kirigami.FormData.label: i18nc("@label:spinbox", "Scale ticks:")
        editable: true
        from: 3
        to: 8
    }

    QQC2.SpinBox {
        id: scaleGridOpacitySpin

        Kirigami.FormData.label: i18nc("@label:spinbox", "Scale grid opacity:")
        editable: true
        from: 0
        to: 100
    }

    QQC2.SpinBox {
        id: scaleLabelOpacitySpin

        Kirigami.FormData.label: i18nc("@label:spinbox", "Scale label opacity:")
        editable: true
        from: 0
        to: 100
    }

    Item {
        Kirigami.FormData.label: i18nc("title:group", "Unit range defaults")
        Kirigami.FormData.isSection: true
    }

    QQC2.ComboBox {
        id: percentRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Percent:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: byteRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Bytes:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: byteRateRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Byte rate:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: frequencyRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Frequency:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: timeRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Time:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: bitRateRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Bit rate:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: voltageRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Voltage:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: temperatureRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Temperature:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: powerRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Power:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: energyRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Energy:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: currentRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Current:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: decibelRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "dBm:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: rateRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Rate:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: rpmRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "RPM:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    QQC2.ComboBox {
        id: otherRangeCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Other:")
        textRole: "text"
        valueRole: "value"
        model: unitRangeModes
    }

    Item {
        Kirigami.FormData.label: i18nc("title:group", "Sensor range overrides")
        Kirigami.FormData.isSection: true
    }

    Repeater {
        model: controller.highPrioritySensorIds

        delegate: ColumnLayout {
            id: overrideRow

            property string sensorId: modelData
            readonly property int selectedMode: rangeCombo.currentValue === undefined ? -1 : Number(rangeCombo.currentValue)

            Kirigami.FormData.label: root.sensorLabel(sensorId, sensor) + ":"
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.ComboBox {
                id: rangeCombo

                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: sensorRangeModes
                currentIndex: Math.max(0, indexOfValue(root.sensorOverrideMode(overrideRow.sensorId)))
                onActivated: root.setSensorOverride(overrideRow.sensorId, {
                    "mode": currentValue
                })
            }

            RowLayout {
                visible: overrideRow.selectedMode === 5
                Layout.fillWidth: true

                QQC2.TextField {
                    id: customMinimumField

                    Layout.fillWidth: true
                    placeholderText: i18nc("@info:placeholder", "Minimum")
                    text: root.sensorOverrideCustomValue(overrideRow.sensorId, "customMinimum")
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    onEditingFinished: {
                        const value = root.numberFromText(text);
                        if (value !== undefined)
                            root.setSensorOverride(overrideRow.sensorId, {
                            "customMinimum": value,
                            "mode": 5
                        });

                    }
                }

                QQC2.TextField {
                    id: customMaximumField

                    Layout.fillWidth: true
                    placeholderText: i18nc("@info:placeholder", "Maximum")
                    text: root.sensorOverrideCustomValue(overrideRow.sensorId, "customMaximum")
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    onEditingFinished: {
                        const value = root.numberFromText(text);
                        if (value !== undefined)
                            root.setSensorOverride(overrideRow.sensorId, {
                            "customMaximum": value,
                            "mode": 5
                        });

                    }
                }

            }

            Sensors.Sensor {
                id: sensor

                sensorId: overrideRow.sensorId
                updateRateLimit: controller.updateRateLimit
            }

        }

    }

    Item {
        Kirigami.FormData.label: i18nc("title:group", "History")
        Kirigami.FormData.isSection: true
    }

    Faces.SuffixSpinBox {
        id: historySpin

        Kirigami.FormData.label: i18nc("@label:spinbox", "History to show:")
        Layout.maximumWidth: Kirigami.Units.gridUnit * 10
        suffix: i18ncp("@item:valuesuffix %1 is seconds of history", "second", "seconds", Number(value).toLocaleString(locale, "f", 0))
    }

    ListModel {
        id: unitRangeModes

        ListElement {
            text: "0-sensor max"
            value: 0
        }

        ListElement {
            text: "0-history max"
            value: 1
        }

        ListElement {
            text: "history min-history max"
            value: 2
        }

        ListElement {
            text: "history min-sensor max"
            value: 3
        }

        ListElement {
            text: "sensor min-sensor max"
            value: 4
        }

    }

    ListModel {
        id: sensorRangeModes

        ListElement {
            text: "unit default"
            value: -1
        }

        ListElement {
            text: "0-sensor max"
            value: 0
        }

        ListElement {
            text: "0-history max"
            value: 1
        }

        ListElement {
            text: "history min-history max"
            value: 2
        }

        ListElement {
            text: "history min-sensor max"
            value: 3
        }

        ListElement {
            text: "sensor min-sensor max"
            value: 4
        }

        ListElement {
            text: "custom min-custom max"
            value: 5
        }

    }

}
