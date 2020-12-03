{
    --------------------------------------------
    Filename: sensor.power.ina219.i2c.spin
    Author: Jesse Burt
    Description: Driver of the TI INA219 current/power monitor IC
    Copyright (c) 2020
    Started Sep 18, 2019
    Updated Dec 2, 2020
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
            adcres := lookdownz(adcres: 9, 10, 11, 12) << core#FLD_BADC
        other:
            curr_res := (curr_res >> core#FLD_BADC) & core#BITS_BADC
            return lookupz(curr_res: 9, 10, 11, 12)

    curr_res &= core#MASK_BADC
    curr_res := (curr_res | adcres) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_res)

PUB BusVoltageRange(range): curr_rng
' Set bus voltage range
'   Valid values: 16, *32
'   Any other value polls the chip and returns the current setting
    curr_rng := 0
    readreg(core#CONFIG, 2, @curr_rng)
    case range
        16, 32:
            range := lookdownz(range: 16, 32) << core#FLD_BRNG
        other:
            curr_rng := (curr_rng >> core#FLD_BRNG) & %1
            return lookupz(curr_rng: 16, 32)

    curr_rng &= core#MASK_BRNG
    curr_rng := (curr_rng | range) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_rng)

PUB CurrentBias(val): curr_val
' Set calibration value, used in current calculation
'   Valid values: *0..65535
'   Any other value polls the chip and returns the current setting
'   NOTE: The LSB is read-only and is always 0
'   NOTE: Current readings will always be 0 after POR, until this value is set
    case val
        0..65535:
            curr_val := val & core#CALIBRATION_MASK
            writereg(core#CALIBRATION, 2, @curr_val)
        other:
            curr_val := 0
            readreg(core#CALIBRATION, 2, @curr_val)
            return

PUB Current{}: a
' Read current flowing through shunt resistor
'   Returns: Current in microamps
    readreg(core#CURRENT, 2, @a)
'    result /= 5
    return (~~a * 20)

PUB DeviceID{}: id
' Read device ID
'   Returns: POR value of the configuration register
'   NOTE: This method performs a soft-reset of the chip and reads the value of
'       the configuration register, thus it isn't an ID, per se
    id := 0
    reset{}
    readreg(core#CONFIG, 2, @id)

PUB Power{}: w
' Read power (calculated on-chip)
'   Returns: Power in microwatts
    w := 0
    readreg(core#POWER, 2, @w)
    w *= 400

PUB Reset{} | tmp
' Perform a soft-reset of the chip
    tmp := (1 << core#FLD_RST)
    writereg(core#CONFIG, 2, @tmp)

PUB ShuntADCRes(adc_res): curr_res
' Set shunt ADC resolution, in bits
'   Valid values: 9, 10, 11, *12
'   Any other value polls the chip and returns the current setting
    curr_res := 0
    readreg(core#CONFIG, 2, @curr_res)
    case adc_res
        9, 10, 11, 12:
            adc_res := lookdownz(adc_res: 9, 10, 11, 12) << core#FLD_SADC
        other:
            curr_res := (curr_res >> core#FLD_SADC) & core#BITS_SADC
            return lookupz(curr_res: 9, 10, 11, 12)

    curr_res &= core#MASK_SADC
    curr_res := (curr_res | adc_res) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_res)

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
            samples := (1 << core#FLD_SADC_AVG)
            samples |= lookdownz(samples: 1, 2, 4, 8, 16, 32, 64, 128) << core#FLD_SADC
        other:
            curr_smp := (curr_smp >> core#FLD_SADC) & core#BITS_SADC
            if curr_smp & %1000
                curr_smp &= %0111
                return lookupz(curr_smp: 1, 2, 4, 8, 16, 32, 64, 128)
            else
                return 0

    curr_smp &= core#MASK_SADC
    curr_smp := (curr_smp | samples) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_smp)

PUB ShuntVoltage{}: v
' Read shunt voltage
'   Returns: Voltage in millivolts
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
            range := lookdownz(range: 40, 80, 160, 320) << core#FLD_PG
        other:
            curr_rng := (curr_rng >> core#FLD_PG) & core#BITS_PG
            return lookupz(curr_rng: 40, 80, 160, 320)

    curr_rng &= core#MASK_PG
    curr_rng := (curr_rng | range) & core#CONFIG_MASK
    writereg(core#CONFIG, 2, @curr_rng)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' read nr_bytes from device into ptr_buff
    case reg_nr                                    ' validate register
        $00..$05:
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
        $00, $05:
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
