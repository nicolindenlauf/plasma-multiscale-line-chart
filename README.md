# Multi-Scale Line Chart

Multi-Scale Line Chart is a KDE Plasma System Monitor sensor face for plotting unrelated sensors in one line chart without forcing them onto one physical unit range.

It keeps each sensor's value and legend unit intact, while the graph scales each line with configurable per-unit defaults and optional per-sensor overrides. The scale labels and horizontal guide lines are color-coded per sensor, and legend hover highlights the matching line, scale, and guide lines.

## Features

- Per-sensor colored scale labels and horizontal guide lines
- Configurable range defaults by unit family
- Per-sensor range overrides
- Optional custom absolute min/max values per sensor
- Byte, byte-rate, bit-rate, frequency, temperature, power, energy, voltage, current, dBm, rate, RPM, time, and fallback unit settings
- Sensor-metadata and history-aware scaling
- Startup fill from left to right, then scrolling history
- Native System Monitor sensor selection and legend formatting

## Range Modes

- `0-sensor max`: scale from zero to the sensor's reported maximum. If the sensor does not report a useful maximum, the chart falls back to a safe value such as 100% or the visible history maximum.
- `0-history max`: scale from zero to the visible history maximum.
- `history min-history max`: scale from the visible history minimum to the visible history maximum.
- `history min-sensor max`: scale from the visible history minimum to the sensor's reported maximum.
- `sensor min-sensor max`: scale from the sensor's reported minimum to the sensor's reported maximum.
- `custom min-custom max`: per-sensor override only; scale to the custom absolute range entered in the settings.

Unit defaults apply first. Any selected sensor can override the unit default from the Sensor range overrides section.

## Install From Git

```sh
mkdir -p ~/.local/share/ksysguard/sensorfaces
git clone https://github.com/nicolindenlauf/plasma-multiscale-line-chart.git ~/.local/share/ksysguard/sensorfaces/io.github.nicolindenlauf.multiscalelinechart
```

Then reopen System Monitor or restart Plasma so the new face is discovered.

## Install From Release Archive

Download `io.github.nicolindenlauf.multiscalelinechart-1.0.0.tar.gz` from the GitHub release page, then extract it into the System Monitor sensor face directory:

```sh
mkdir -p ~/.local/share/ksysguard/sensorfaces
tar -xzf io.github.nicolindenlauf.multiscalelinechart-1.0.0.tar.gz -C ~/.local/share/ksysguard/sensorfaces
```

Then reopen System Monitor or restart Plasma.

## Development Install

If you already cloned this repo somewhere else, symlink it into the sensor face directory:

```sh
ln -s /path/to/plasma-multiscale-line-chart ~/.local/share/ksysguard/sensorfaces/io.github.nicolindenlauf.multiscalelinechart
```

## Scope

This repository contains only the sensor face style. It does not include any custom sensor provider. It works with standard KDE System Monitor sensors and any compatible third-party sensors installed separately.

## License

This project is licensed under `LGPL-2.0-or-later`.

It is derived from KDE's stock System Monitor line chart face and keeps the original copyright notices in the source files.
