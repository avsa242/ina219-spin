# ina219-spin 
-------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the TI INA219 current/power monitor IC.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 2.56MHz (P1), _TBD_ (P2)
* Read shunt voltage
* Read bus voltage
* Read power measured by the chip
* Read current measured by the chip
* Set current reading calibration

## Requirements

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM I2C driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 5.0.0)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Calibration values (factors used to compute calibrated figures from the raw ADC values; not the value set in the calibration register) are currently hardcoded

## TODO

- [x] Implement method to perform soft-reset
- [x] Implement method to ID the device
- [x] Implement method to read shunt voltage
- [x] Implement method to read bus voltage
- [x] Implement method to read measured power
- [x] Implement method to read measured current
- [x] Implement method to set/read calibration
- [ ] Make calibration a more dynamic process
- [ ] Add support for alternate slave addresses
