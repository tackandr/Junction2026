# ADR-0001: Arduino Project Hardware

- **Status:** Accepted
- **Date:** 2026-11-14
- **Decision makers:** Project Team
- **Technical area:** Hardware
- **Related issues:** N/A
- **Supersedes:** N/A
- **Superseded by:** N/A

## Context and Problem Statement

Record the hardware used to develop, deploy, and run the project examples.

## Decision Outcome

The project uses this hardware:

- [**Arduino UNO Q**](https://docs.arduino.cc/hardware/uno-q) — main device; its built-in LED is used by the blink example.
- [**Arduino Modulino Thermo**](https://docs.arduino.cc/hardware/modulino-thermo) and **Qwiic cable** — temperature and relative-humidity measurements for the climate and VisioSense apps.
- [**USB camera**](https://docs.arduino.cc/hardware/usb-camera/), **powered USB-C hub**, and **external hub power** — camera input for video detection and VisioSense.
- **USB-C cable** — board power and USB/ADB connection during setup or deployment.
- **Ubuntu computer** — development and app deployment host.
- **Private Wi-Fi hotspot or router** — connects the board and host for SSH deployment and web UI access.

## References

- [Project README](../../README.md)
- [Home Climate Monitoring hardware requirements](../../example_climate_monitor/README.md)
- [VisioSense setup](../../visiosense/README.md)
