/*
    SPDX-FileCopyrightText: 2026 nicolindenlauf
    SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
    SPDX-FileCopyrightText: 2020 David Redondo <kde@david-redondo.de>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.faces as Faces
import org.kde.ksysguard.formatter as Formatter
import org.kde.ksysguard.sensors as Sensors
import org.kde.quickcharts as Charts
import org.kde.quickcharts.controls as ChartsControls

Faces.SensorFace {
    id: root

    readonly property bool showLegend: controller.faceConfiguration.showLegend
    readonly property bool showGridLines: root.controller.faceConfiguration.showGridLines
    readonly property bool showYAxisLabels: root.controller.faceConfiguration.showYAxisLabels

    function formattedSensorValue(sensor) {
        if (sensor.unit === Formatter.Units.UnitCelsius && sensor.value !== undefined && sensor.value !== null) {
            const value = Number(sensor.value);
            if (!isNaN(value))
                return Math.round(value) + " C";

        }
        return sensor.formattedValue || "";
    }

    // Arbitrary minimumWidth to make easier to align plasmoids in a predictable way
    Layout.minimumWidth: Kirigami.Units.gridUnit * 8
    Layout.preferredWidth: Math.max(titleMetrics.width, legend.preferredWidth)

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        TextMetrics {
            id: axisMetrics

            font: Kirigami.Theme.smallFont
            text: "100%"
        }

        Kirigami.Heading {
            id: heading

            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.controller.title
            visible: root.controller.showTitle && text.length > 0
            level: 2

            TextMetrics {
                id: titleMetrics

                font: heading.font
                text: heading.text
            }

        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillHeight: true
            Layout.topMargin: showYAxisLabels ? axisMetrics.height / 2 : 0
            Layout.bottomMargin: Layout.topMargin
            Layout.minimumHeight: 3 * Kirigami.Units.gridUnit
            Layout.preferredHeight: 5 * Kirigami.Units.gridUnit

            Item {
                id: chartArea

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: false

                LineChart {
                    id: compactRepresentation

                    anchors.fill: parent
                    z: 1
                    controller: root.controller
                    desiredScaleTickCount: Math.max(3, Math.min(8, Number(root.controller.faceConfiguration.scaleTickCount) || 5))
                    highlight: legend.highlightedIndex
                }

                Canvas {
                    id: coloredGrid

                    property int revision: compactRepresentation.scaleRevision
                    property int highlightedIndex: legend.highlightedIndex

                    function requestGridPaint() {
                        if (visible)
                            requestPaint();

                    }

                    anchors.fill: compactRepresentation
                    visible: showGridLines
                    z: 2
                    onRevisionChanged: requestGridPaint()
                    onHighlightedIndexChanged: requestGridPaint()
                    onWidthChanged: requestGridPaint()
                    onHeightChanged: requestGridPaint()
                    onVisibleChanged: requestGridPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        const scales = compactRepresentation.scaleItems || [];
                        const baseOpacity = Math.max(0, Math.min(1, Number(root.controller.faceConfiguration.scaleGridOpacity ?? 18) / 100));
                        const hasHighlight = highlightedIndex >= 0;
                        for (let scaleIndex = 0; scaleIndex < scales.length; ++scaleIndex) {
                            const scale = scales[scaleIndex];
                            const ticks = scale.ticks || [];
                            const highlighted = !hasHighlight || scaleIndex === highlightedIndex;
                            ctx.strokeStyle = scale.color;
                            ctx.globalAlpha = highlighted ? Math.min(1, baseOpacity * (hasHighlight ? 2.8 : 1)) : baseOpacity * 0.18;
                            ctx.lineWidth = highlighted && hasHighlight ? 2 : 1;
                            for (let tickIndex = 0; tickIndex < ticks.length; ++tickIndex) {
                                const tick = ticks[tickIndex];
                                if (tick.percent <= 0 || tick.percent >= 100)
                                    continue;

                                const y = Math.round(height - (height * tick.percent / 100)) + 0.5;
                                ctx.beginPath();
                                ctx.moveTo(0, y);
                                ctx.lineTo(width, y);
                                ctx.stroke();
                            }
                        }
                        ctx.globalAlpha = 1;
                    }
                }

                Item {
                    id: scaleOverlay

                    anchors.fill: compactRepresentation
                    visible: showYAxisLabels
                    z: 3
                    clip: false

                    Repeater {
                        model: compactRepresentation.scaleItems

                        delegate: Item {
                            id: scaleColumn

                            property var scale: modelData
                            property int scaleIndex: index
                            readonly property int columnCount: Math.max(1, compactRepresentation.scaleItems.length)
                            readonly property real scaleAnchorX: columnCount <= 1 ? scaleOverlay.width / 2 : scaleIndex * scaleOverlay.width / (columnCount - 1)
                            readonly property real labelMaxWidth: columnCount <= 1 ? scaleOverlay.width : scaleOverlay.width / columnCount
                            readonly property bool hasHighlight: legend.highlightedIndex >= 0
                            readonly property bool highlighted: !hasHighlight || legend.highlightedIndex === scaleIndex

                            x: 0
                            width: scaleOverlay.width
                            height: scaleOverlay.height

                            Repeater {
                                model: scaleColumn.scale.ticks || []

                                delegate: QQC2.Label {
                                    readonly property real tickPercent: Math.max(0, Math.min(100, Number(modelData.percent) || 0))

                                    text: modelData.label
                                    color: scaleColumn.scale.color
                                    opacity: Math.max(0, Math.min(1, Number(root.controller.faceConfiguration.scaleLabelOpacity ?? 82) / 100)) * (scaleColumn.highlighted ? 1 : 0.22)
                                    font.family: Kirigami.Theme.smallFont.family
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    font.bold: scaleColumn.hasHighlight && scaleColumn.highlighted
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    width: Math.min(implicitWidth + Kirigami.Units.smallSpacing, scaleColumn.labelMaxWidth)
                                    x: Math.max(0, Math.min(scaleColumn.width - width, scaleColumn.scaleAnchorX - width / 2))
                                    y: Math.max(-height / 2, Math.min(scaleColumn.height - height / 2, scaleColumn.height - (scaleColumn.height * tickPercent / 100) - height / 2))
                                }

                            }

                        }

                    }

                }

            }

        }

        ChartsControls.Legend {
            id: legend

            Layout.fillWidth: true
            Layout.minimumHeight: implicitHeight
            visible: root.showLegend
            model: root.showLegend ? root.controller.highPrioritySensorIds : []
            highlightEnabled: model.length > 1

            delegate: ChartsControls.LegendDelegate {
                id: legendDelegate

                property string sensorId: modelData

                name: root.controller.sensorLabels[sensorId] || sensor.name || sensorId
                shortName: root.controller.sensorLabels[sensorId] || sensor.shortName || sensorId.split("/").pop()
                color: root.colorSource.map[sensorId] ?? "white"
                value: root.formattedSensorValue(sensor)
                highlighted: legend.highlightEnabled && hovered
                maximumValueWidth: Formatter.Formatter.maximumLength(sensor.unit, legend.font)
                ChartsControls.LegendLayout.minimumWidth: minimumWidth
                ChartsControls.LegendLayout.preferredWidth: preferredWidth
                ChartsControls.LegendLayout.maximumWidth: Math.max(legend.maximumDelegateWidth, preferredWidth)
                onHoveredChanged: {
                    if (legend.highlightEnabled) {
                        if (hovered)
                            legend.highlightedIndex = index;
                        else if (legend.highlightedIndex === index)
                            legend.highlightedIndex = -1;
                    }
                }

                Sensors.Sensor {
                    id: sensor

                    sensorId: legendDelegate.sensorId
                    updateRateLimit: root.controller.updateRateLimit
                }

            }

        }

    }

}
