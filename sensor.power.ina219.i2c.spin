{
    --------------------------------------------
    Filename: sensor.power.ina219.i2c.spin
    Author: Jesse Burt
    Description: Driver of the TI INA219 current/power monitor IC
    Copyright (c) 2020
    Started Sep 18, 2019
    Updated Dec 5, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

OBJ

    i2c : "com.i2c"
    core: "core.con.ina219.spin"
    time: "time"

VAR

    long _shunt_res
    long _i_max
    long _i_lsb, _p_lsb
    long _vmax_shunt

PUB Null{}
' This is not a top-level object

PUB Start{}: okay
' Start using "standard" Propeller I2C pins and 100kHz

    okay := startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)
                time.msleep(1)
                if i2c.present (SLAVE_WR)       ' check device bus presence
                    if deviceid{} == core#CONFIG_POR
                        return okay

    return FALSE                                ' something above failed

PUB Stop{}

    i2c.terminate{}

PUB Preset320S_2A_100mohm{}
' Preset:       'XXX for coming up with a value for CurrentBias()
'   32V bus voltage range
'   320mV shunt voltage range
'   12bit shunt ADC res
'   2A maximum current
'   100mOhm shunt resistor
    shuntresistance(100)
    _i_max := 2 * 1_000
    _i_lsb := _i_max / 32768
    _p_lsb := _i_lsb * 20
    _vmax_shunt := _i_max * _shunt_res

    busvoltagerange(32)
    shuntvoltagerange(320)
    shuntadcres(12)
    shuntsamples(1)
    busadcres(12)

PUB BusVoltage{}: v
' Read bus voltage
'   Returns: Voltage in millivolts
    v := 0
    readreg(core#BUS_VOLTAGE, 2, @v)
    v ~>= 3                                     ' chop off the 3 LSBs (not part
    v *= 4                                      ' of the measurement), but
                                                ' preserve the sign

PUB BusADCRes(adcres): curr_res
' Set bus ADC resolution, in bits
'   Valid values: 9, 10, 11, *12
'   Any other value polls the chip and returns the current setting
    curr_res := 0
    readreg(core#CONFIG, 2, @curr_res)
    case adcres
        9, 10, 11, 12:
            adcres := lookdownz(adcres: 9, 10, 11, 12) << core#BADC
        other:
            curr_res := (curr_res >> core#BADC) & core#BADC_BITS
            return lookupz(curr_res: 9, 10, 11, 12)

    adcres := ((curr_res & core#BADC_MASK) | adcres) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @adcres)

PUB BusVoltageRange(range): curr_rng
' Set bus voltage range
'   Valid values: 16, *32
'   Any other value polls the chip and returns the current setting
    curr_rng := 0
    readreg(core#CONFIG, 2, @curr_rng)
    case range
        16, 32:
            range := lookdownz(range: 16, 32) << core#BRNG
        other:
            curr_rng := (curr_rng >> core#BRNG) & %1
            return lookupz(curr_rng: 16, 32)

    range := ((curr_rng & core#BRNG_MASK) | range) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @range)

PUB CurrentBias(val): curr_val
' Set calibration value, used in current calculation
'   Valid values: *0..65534 (even numbers only)
'   Any other value polls the chip and returns the current setting
'   NOTE: Current and power readings will always be 0,
'       unless this value is set non-zero
    case val
        0..65534:
            curr_val := val & core#CALIBRATION_MASK
            writereg(core#CALIBRATION, 2, @curr_val)
        other:
            curr_val := 0
            readreg(core#CALIBRATION, 2, @curr_val)
            return

PUB Current{}: a
' Read current
'   Returns: Current in milliamps
    readreg(core#CURRENT, 2, @a)
    return ~~curr_adc

PUB DeviceID{}: id
' Read device ID
'   Returns: POR value of the configuration register
'   NOTE: This method performs a soft-reset of the chip and reads the value of
'       the configuration register, thus it isn't an ID, per se
    id := 0
    reset{}
    readreg(core#CONFIG, 2, @id)

PUB PowerData{}: pwr_adc
' Read power ADC data
'   Returns: s16
    pwr_adc := 0
    readreg(core#POWER, 2, @pwr_adc)

PUB Power{}: w
' Read power
'   Returns: Power in milliwatts
    return powerdata{} * 2

PUB Reset{} | tmp
' Perform a soft-reset of the chip
    tmp := (1 << core#RST)
    writereg(core#CONFIG, 2, @tmp)

PUB ShuntADCRes(adc_res): curr_res
' Set shunt ADC resolution, in bits
'   Valid values: 9, 10, 11, *12
'   Any other value polls the chip and returns the current setting
    curr_res := 0
    readreg(core#CONFIG, 2, @curr_res)
    case adc_res
        9, 10, 11, 12:
            adc_res := lookdownz(adc_res: 9, 10, 11, 12) << core#SADC
        other:
            curr_res := (curr_res >> core#SADC) & core#SADC_BITS
            return lookupz(curr_res: 9, 10, 11, 12)

    adc_res := ((curr_res & core#SADC_MASK) | adc_res) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @adc_res)

PUB ShuntResistance(r_shunt): curr_res
' Set value of shunt resistor, in milliohms
    case r_shunt
        1..1_000:
            _shunt_res := r_shunt
        other:
            return _shunt_res

PUB ShuntSamples(samples): curr_smp
' Set number of shunt ADC samples to take when averaging
'   Valid values: 1, 2, 4, 8, 16, 32, 64, 128
'   Any other value polls the chip and returns the current setting
'   NOTE: All averaging modes are performed at 12-bit resolution
'   NOTE: Conversion time is approx 532uSec * number of samples
'   NOTE: 1 effectively disables averaging
    curr_smp := 0
    readreg(core#CONFIG, 2, @curr_smp)
    case samples
        1, 2, 4, 8, 16, 32, 64, 128:
            samples := lookdownz(samples: 1, 2, 4, 8, 16, 32, 64, 128) << core#SADC
            samples |= (1 << core#SADC_AVG)
        other:
            curr_smp := (curr_smp >> core#SADC) & core#SADC_BITS
            if curr_smp & %1000
                curr_smp &= %0111
                return lookupz(curr_smp: 1, 2, 4, 8, 16, 32, 64, 128)
            else
                return 0

    samples := ((curr_smp & core#SADC_MASK) | samples) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @samples)

PUB ShuntVoltage{}: v
' Read shunt voltage
'   Returns: Voltage in microvolts
    readreg(core#SHUNT_VOLTAGE, 2, @v)
    return ~~v * 10

PUB ShuntVoltageRange(range): curr_rng
' Set shunt voltage range, in millivolts
'   Valid values: 40, 80, 160, *320
'   Any other value polls the chip and returns the current setting
'   Example: Setting of 40 means +/- 40mV
    curr_rng := 0
    readreg(core#CONFIG, 2, @curr_rng)
    case range
        40, 80, 160, 320:
            range := lookdownz(range: 40, 80, 160, 320) << core#PG
        other:
            curr_rng := (curr_rng >> core#PG) & core#PG_BITS
            return lookupz(curr_rng: 40, 80, 160, 320)

    range := ((curr_rng & core#PG_MASK) | range) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @range)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' read nr_bytes from device into ptr_buff
    case reg_nr                                    ' validate register
        core#CONFIG..core#CALIBRATION:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 2)
            i2c.start{}
            i2c.write(SLAVE_RD)
            byte[ptr_buff][1] := i2c.read(i2c#ACK)
            byte[ptr_buff][0] := i2c.read(i2c#NAK)
            i2c.stop{}
        other:
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' write nr_bytes to device from ptr_buff
    case reg_nr
        core#CONFIG, core#CALIBRATION:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            cmd_pkt.byte[2] := byte[ptr_buff][1]
            cmd_pkt.byte[3] := byte[ptr_buff][0]

            i2c.start{}
            i2c.wr_block(@cmd_pkt, 4)
            i2c.stop{}
        other:
            return


DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
