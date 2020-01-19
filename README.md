# ina219-spin 
-------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the TI INA219 current/power monitor IC.

## Salient Features

* I2C connection at up to 2.56MHz (P1), _TBD_ (P2)
* Read shunt voltage
* Read bus voltage
* Read power measured by the chip
* Read current measured by the chip
* Set a calibration value

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM I2C driver
* P2/SPIN2: N/A

## Compiler Compatibility

* SPIN1: OpenSpin (tested with 1.00.81)
* SPIN2: FastSpin (tested with 4.1.0-beta)

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
