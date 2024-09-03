{
----------------------------------------------------------------------------------------------------
    Filename:       sensor.power.ina219.spin
    Description:    Driver of the TI INA219 current/power monitor IC
    Author:         Jesse Burt
    Started:        Sep 18, 2019
    Updated:        Sep 3, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}
#include "sensor.power.common.spinh"

CON

    { default I/O settings; these can be overridden in the parent object }
    SCL             = 28
    SDA             = 29
    I2C_FREQ        = 100_000
    I2C_ADDR        = %0000

'   Address pins vs slave addresses
'   A1  A0  SLAVE ADDRESS (MSBits are always %100)
'   GND GND 0000
'   GND VS+ 0001
'   GND SDA 0010
'   GND SCL 0011
'   VS+ GND 0100
'   VS+ VS+ 0101
'   VS+ SDA 0110
'   VS+ SCL 0111
'   SDA GND 1000
'   SDA VS+ 1001
'   SDA SDA 1010
'   SDA SCL 1011
'   SCL GND 1100
'   SCL VS+ 1101
'   SCL SDA 1110
'   SCL SCL 1111

' Operating modes (use with opmode() )
    SLEEP           = 0
    SHUNTV_SNGL     = 1
    BUSV_SNGL       = 2
    BOTH_SNGL       = 3
    STANDBY         = 4
    SHUNTV_CONT     = 5
    BUSV_CONT       = 6
    BOTH_CONT       = 7


    SLAVE_WR        = core.SLAVE_ADDR
    SLAVE_RD        = core.SLAVE_ADDR|1
    I2C_MAX_FREQ    = core.I2C_MAX_FREQ


OBJ

#ifdef INA219_I2C_BC
    i2c:    "com.i2c.nocog"
#else
    i2c:    "com.i2c"
#endif
    core:   "core.con.ina219"
    time:   "time"


VAR

    long _shunt_res
    long _i_max
    long _i_lsb, _p_lsb
    long _vmax_shunt
    long _addr_bits


PUB null()
' This is not a top-level object


PUB start(): status
' Start using default I/O settings
    return startx(SCL, SDA, I2C_FREQ, I2C_ADDR)


PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start the driver with custom I/O settings
'   SCL_PIN:    I2C clock, 0..31
'   SDA_PIN:    I2C data, 0..31
'   I2C_HZ:     I2C clock speed (max official specification is 400_000 but is unenforced)
'   ADDR_BITS:  I2C alternate address bits, %0000..%1111
'   Returns:
'       cog ID+1 of I2C engine on success (= calling cog ID+1, if the bytecode I2C engine is used)
'       0 on failure
    if (    lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and ...
            lookdown(ADDR_BITS: %0000..%1111) ) ' validate I/O pins, address bits
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.msleep(1)
            _addr_bits := ADDR_BITS << 1
            if ( dev_id() == core.DEVID_RESP )  ' check for device presence
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE


PUB stop()
' Stop the driver
    i2c.deinit()


PUB defaults()
' Factory default settings
'   POR settings:
'   bus_voltage_rng(32)
'   shunt_voltage_rng(320)
'   bus_adc_res(12)
'   shunt_adc_res(12)
'   opmode(BOTH_CONT)
    reset()


PUB preset_320s_2a_100mohm()
' Preset:       'XXX for coming up with a value for current_scale()
'   32V bus voltage range
'   320mV shunt voltage range
'   12bit shunt ADC res
'   2A maximum current
'   100mOhm shunt resistor
    shunt_resistance(100)
    _i_max := 2 * 1_000
    _i_lsb := _i_max / 32768
    _p_lsb := _i_lsb * 20
    _vmax_shunt := _i_max * _shunt_res

    bus_voltage_rng(32)
    shunt_voltage_rng(320)
    shunt_adc_res(12)
    shunt_samples(1)
    bus_adc_res(12)


PUB adc2amps(adc_word): a
' Convert current ADC word to amperage
    return (~~adc_word) * 1_00


PUB adc2shunt_volts(adc_word): v
' Convert shunt voltage ADC word to voltage
    return (~~adc_word * 10)


PUB adc2volts(adc_word): v
' Convert bus voltage ADC word to voltage
    { discard 3 LSBs (not part of the measurement), but preserve the sign }
    return ((adc_word ~> 3) * 4_000)


PUB adc2watts(adc_word): w
' Convert power ADC word to wattage
    return (adc_word * 20_00)


PUB bus_adc_res(adcres=-2): curr_res
' Set bus ADC resolution, in bits
'   Valid values: 9, 10, 11, *12
'   Any other value polls the chip and returns the current setting
    curr_res := readreg(core.CONFIG)
    case adcres
        9..12:
            adcres := (adcres-9) << core.BADC
            adcres := ((curr_res & core.BADC_MASK) | adcres)
            writereg(core.CONFIG, adcres)
        other:
            curr_res := (curr_res >> core.BADC) & core.BADC_BITS
            return (curr_res + 9)


PUB bus_voltage_rng(range=-2): curr_rng
' Set bus voltage range
'   Valid values: 16, *32
'   Any other value polls the chip and returns the current setting
    curr_rng := readreg(core.CONFIG)
    case range
        16, 32:
            range := ((range / 16)-1) << core.BRNG
            range := ((curr_rng & core.BRNG_MASK) | range)
            writereg(core.CONFIG, range)
        other:
            curr_rng := (curr_rng >> core.BRNG) & 1
            return lookupz(curr_rng: 16, 32)


PUB current_data(): a
' Read current
'   Returns: Current in milliamps
    return readreg(core.CURRENT)


PUB current_scale(): scale
' Get current scale
'   Returns: current scale, in LSBs
    return readreg(core.CALIBRATION)


PUB current_set_scale(scale)
' Set current scale, in LSBs
'   Valid values: *0..65534 (even numbers only)
'   Any other value polls the chip and returns the current setting
'   NOTE: Current and power readings will always be 0,
'       unless this value is set non-zero
    writereg(core.CALIBRATION, (0 #> (scale & core.CALIBRATION_MASK) <# 65534) )


PUB dev_id(): id
' Read device ID
'   Returns: POR value of the configuration register
'   NOTE: This method performs a soft-reset of the chip and reads the value of
'       the configuration register, thus it isn't an ID, per se
    reset()
    return readreg(core.CONFIG)


PUB opmode(mode=-2): curr_mode
' Set device operating mode
'   Valid values:
'       SLEEP (0): Power-down
'       SHUNTV_SNGL (1): Shunt voltage measurement, single
'       BUSV_SNGL (2): Bus voltage measurement, single
'       BOTH_SNGL (3): Shunt and vus voltage measurement, single
'       STANDBY (4): Disable ADC
'       SHUNTV_CONT (5): Shunt voltage measurements, continuous
'       BUSV_CONT (6): Bus voltage measurements, continuous
'       BOTH_CONT (7): Shunt and bus voltage measurements, continuous
'   Any other value polls the chip and returns the current setting
    curr_mode := readreg(core.CONFIG)
    case mode
        SLEEP, SHUNTV_SNGL, BUSV_SNGL, BOTH_SNGL, STANDBY, SHUNTV_CONT, BUSV_CONT, BOTH_CONT:
            mode := ((curr_mode & core.MODE_MASK) | mode)
            writereg(core.CONFIG, mode)
        other:
            return (curr_mode & core.MODE_BITS)


PUB power_data(): pwr_adc
' Read power ADC data
'   Returns: s16
    return readreg(core.POWER)


PUB reset() | tmp
' Perform a soft-reset of the chip
    writereg(core.CONFIG, core.SOFT_RESET)


PUB shunt_adc_res(adc_res=-2): curr_res
' Set shunt ADC resolution, in bits
'   Valid values: 9, 10, 11, *12
'   Any other value polls the chip and returns the current setting
'   NOTE: This setting and shunt_samples() are mutually exclusive. If both
'       methods are called, the most recent will be the setting used.
    curr_res := readreg(core.CONFIG)
    case adc_res
        9..12:
            adc_res := (adc_res - 9) << core.SADC
            adc_res := ((curr_res & core.SADC_MASK) | adc_res)
            writereg(core.CONFIG, adc_res)
        other:
            curr_res := (curr_res >> core.SADC) & core.SADC_BITS
            return (curr_res + 9)


PUB shunt_resistance(r_shunt=-2): curr_res
' Set value of shunt resistor, in milliohms
    case r_shunt
        1..1_000:
            _shunt_res := r_shunt
        other:
            return _shunt_res


PUB shunt_samples(samples=-2): curr_smp
' Set number of shunt ADC samples to take when averaging
'   Valid values: 1, 2, 4, 8, 16, 32, 64, 128
'   Any other value polls the chip and returns the current setting
'   NOTE: All averaging modes are performed at 12-bit resolution
'   NOTE: Conversion time is approx 532uSec * number of samples
'   NOTE: 1 effectively disables averaging
'   NOTE: This setting and shunt_adc_res() are mutually exclusive. If both
'       methods are called, the most recent will be the setting used.
    curr_smp := readreg(core.CONFIG)
    case samples
        1..128:
            samples := ((>| samples) - 1) << core.SADC
            samples |= (1 << core.SADC_AVG)
            samples := ((curr_smp & core.SADC_MASK) | samples)
            writereg(core.CONFIG, samples)
        other:
            curr_smp := (curr_smp >> core.SADC) & core.SADC_BITS
            if (curr_smp & %1000)               ' bit 3 = averaging mode
                curr_smp &= %0111               ' capture only the # of samples
                return (|<(curr_smp))
            else
                return 0


PUB shunt_voltage_data(): adc_word
' Read shunt voltage ADC word
    return readreg(core.SHUNT_VOLTAGE)


PUB shunt_voltage(): v
' Read shunt voltage
'   Returns: Voltage in microvolts
    return adc2shunt_volts(shunt_voltage_data())


PUB shunt_voltage_rng(range=-2): curr_rng
' Set shunt voltage range, in millivolts
'   Valid values: 40, 80, 160, *320
'   Any other value polls the chip and returns the current setting
'   Example: Setting of 40 means +/- 40mV
    curr_rng := readreg(core.CONFIG)
    case range
        40, 80, 160, 320:
            range := lookdownz(range: 40, 80, 160, 320) << core.PG
            range := ((curr_rng & core.PG_MASK) | range)
            writereg(core.CONFIG, range)
        other:
            curr_rng := (curr_rng >> core.PG) & core.PG_BITS
            return lookupz(curr_rng: 40, 80, 160, 320)


PUB voltage_data(): v
' Read bus voltage
    v := readreg(core.BUS_VOLTAGE)


PRI readreg(reg_nr): v | cmd_pkt
' read nr_bytes from device into ptr_buff
    case reg_nr                                 ' validate register
        core.CONFIG..core.CALIBRATION:
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := reg_nr
            i2c.start()
            'i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrword_lsbf(cmd_pkt)
            i2c.start()
            i2c.write(SLAVE_RD | _addr_bits)
            v := i2c.rdword_msbf(i2c.NAK)'i2c.rdblock_msbf(ptr_buff, 2, i2c.NAK)
            i2c.stop()
            return v                            ' return data read from reg
        other:
            return -1                           ' invalid reg


PRI writereg(reg_nr, val): s | cmd_pkt
' write nr_bytes to device from ptr_buff
    case reg_nr
        core.CONFIG, core.CALIBRATION:
            cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
            cmd_pkt.byte[1] := reg_nr
            cmd_pkt.byte[2] := val.byte[1]
            cmd_pkt.byte[3] := val.byte[0]

            i2c.start()
            'i2c.wrblock_lsbf(@cmd_pkt, 4)
            s := i2c.wrlong_lsbf(cmd_pkt)
            i2c.stop()
            return s                            ' return ACK/NAK from sensor
        other:
            return -1                           ' invalid reg


DAT
{
Copyright (c) 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

