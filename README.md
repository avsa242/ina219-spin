# ina219-spin 
-------------

This is a P8X32A/Propeller driver object for the TI INA219 current/power monitor IC.

## Salient Features

* I2C connection at up to 2.56MHz (tested up to 400kHz)
* Read shunt voltage
* Read bus voltage
* Read power measured by the chip
* Read current measured by the chip
* Set a calibration value

## Requirements

* 1 extra core/cog for the PASM I2C driver

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
