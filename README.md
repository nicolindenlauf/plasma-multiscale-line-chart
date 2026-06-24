# Multi-Scale Line Chart

Multi-Scale Line Chart is a KDE Plasma System Monitor sensor face for plotting unrelated sensors in one line chart without forcing them onto one physical unit range.

It keeps each sensor's value and legend unit intact, while the graph can normalize each line by unit family. The scale labels and horizontal guide lines are color-coded per sensor, and legend hover highlights the matching line, scale, and guide lines.

## Features

- Per-sensor colored scale labels and horizontal guide lines
- Configurable normalization by unit family
- Percent sensors can stay fixed at 0-100% or use normalization
- Byte, byte-rate, bit-rate, frequency, temperature, power, energy, voltage, current, dBm, rate, RPM, time, and fallback unit settings
- History-aware 0-max and min-max scaling
- Startup fill from left to right, then scrolling history
- Native System Monitor sensor selection and legend formatting

## Normalization Modes

- `none`: percent sensors only; draw the raw 0-100% value.
- `0-max`: scale from zero to the sensor maximum when available, otherwise the visible history maximum.
- `min-max`: scale from the visible history minimum to the visible history maximum.

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
