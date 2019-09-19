# ina219-spin 
-------------

This is a P8X32A/Propeller driver object for the TI INA219 current/power monitor IC.

## Salient Features

* I2C connection at up to 2.56MHz (tested up to 400kHz)

## Requirements

* 1 extra core/cog for the PASM I2C driver

## Limitations

* Very early in development - may malfunction, or outright fail to build

## TODO

- [x] Implement method to perform soft-reset
- [x] Implement method to ID the device
- [ ] Implement method to read shunt voltage
- [ ] Implement method to read bus voltage
- [ ] Implement method to read measured power
- [ ] Implement method to read measured current
- [ ] Implement method to set/read calibration
