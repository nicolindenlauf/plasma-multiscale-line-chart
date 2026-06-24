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
    property alias cfg_percentNormalizationMode: percentNormalizationCombo.currentIndex
    property alias cfg_byteNormalizationMode: byteNormalizationCombo.currentIndex
    property alias cfg_byteRateNormalizationMode: byteRateNormalizationCombo.currentIndex
    property alias cfg_frequencyNormalizationMode: frequencyNormalizationCombo.currentIndex
    property alias cfg_timeNormalizationMode: timeNormalizationCombo.currentIndex
    property alias cfg_bitRateNormalizationMode: bitRateNormalizationCombo.currentIndex
    property alias cfg_voltageNormalizationMode: voltageNormalizationCombo.currentIndex
    property alias cfg_temperatureNormalizationMode: temperatureNormalizationCombo.currentIndex
    property alias cfg_powerNormalizationMode: powerNormalizationCombo.currentIndex
    property alias cfg_energyNormalizationMode: energyNormalizationCombo.currentIndex
    property alias cfg_currentNormalizationMode: currentNormalizationCombo.currentIndex
    property alias cfg_decibelNormalizationMode: decibelNormalizationCombo.currentIndex
    property alias cfg_rateNormalizationMode: rateNormalizationCombo.currentIndex
    property alias cfg_rpmNormalizationMode: rpmNormalizationCombo.currentIndex
    property alias cfg_otherNormalizationMode: otherNormalizationCombo.currentIndex
    property alias cfg_historyAmount: historySpin.value

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
        Kirigami.FormData.label: i18nc("title:group", "Unit normalization")
        Kirigami.FormData.isSection: true
    }

    QQC2.ComboBox {
        id: percentNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Percent:")
        textRole: "text"
        valueRole: "value"
        model: percentNormalizationModes
    }

    QQC2.ComboBox {
        id: byteNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Bytes:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: byteRateNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Byte rate:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: frequencyNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Frequency:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: timeNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Time:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: bitRateNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Bit rate:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: voltageNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Voltage:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: temperatureNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Temperature:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: powerNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Power:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: energyNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Energy:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: currentNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Current:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: decibelNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "dBm:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: rateNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Rate:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: rpmNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "RPM:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
    }

    QQC2.ComboBox {
        id: otherNormalizationCombo

        Kirigami.FormData.label: i18nc("@label:combobox", "Other:")
        textRole: "text"
        valueRole: "value"
        model: normalizationModes
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
        id: percentNormalizationModes

        ListElement {
            text: "none"
            value: 0
        }

        ListElement {
            text: "0-max"
            value: 1
        }

        ListElement {
            text: "min-max"
            value: 2
        }

    }

    ListModel {
        id: normalizationModes

        ListElement {
            text: "0-max"
            value: 0
        }

        ListElement {
            text: "min-max"
            value: 1
        }

    }

}
