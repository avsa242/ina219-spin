{
    --------------------------------------------
    Filename: INA219-Demo.spin
    Author: Jesse Burt
    Description: Demo of the INA219 driver
    Copyright (c) 2020
    Started Sep 18, 2019
    Updated Dec 2, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode        = cfg#_clkmode
    _xinfreq        = cfg#_xinfreq

' -- User-modifiable constants
    LED             = cfg#LED1
    SER_BAUD        = 115_200

    SCL_PIN         = 28
    SDA_PIN         = 29
    I2C_HZ          = 400_000
' --

    MEASUREMENT_COL = 0
    CURR_MEAS_COL   = 20
    MIN_MEAS_COL    = CURR_MEAS_COL + 20
    MAX_MEAS_COL    = MIN_MEAS_COL + 20

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    ina219  : "sensor.power.ina219.i2c"
    int     : "string.integer"

VAR

    byte _row

PUB Main{} | vbus, vbus_min, vbus_max, vshunt, vshunt_min, vshunt_max, i, i_min, i_max, p, p_min, p_max, cnf, cnf_init

    setup{}
    ina219.calibration(20480)
    ina219.busvoltagerange(32)
    ina219.shuntvoltagerange(320)
    ina219.shuntadcres(12)
'    ina219.shuntsamples(128)
    ina219.busadcres(12)

    cnf_init := ina219.configword{}
    _row := 5
    ser.position(MEASUREMENT_COL, _row)
    ser.str(string("Measurement:"))
    ser.position(CURR_MEAS_COL, _row)
    ser.str(string("Current val:"))
    ser.position(MIN_MEAS_COL, _row)
    ser.str(string("Min:"))
    ser.position(MAX_MEAS_COL, _row)
    ser.str(string("Max:"))

    _row += 2
    vbus_min := ina219.busvoltage{}
    vshunt_min := ina219.shuntvoltage{}
    i_min := ina219.current{}
    p_min := ina219.power{}

    repeat
        _row := 7
        vbus := ina219.busvoltage{}
        vshunt := ina219.shuntvoltage{}
        i := ina219.current{}
        p := ina219.power{}
        cnf := ina219.configword{}

        vbus_min := vbus <# vbus_min
        vbus_max := vbus #> vbus_max
        vshunt_min := vshunt_min <# vshunt
        vshunt_max := vshunt #> vshunt_max
        i_min := i_min <# i
        i_max := i #> i_max
        p_min := p_min <# p
        p_max := p #> p_max

        ser.position(MEASUREMENT_COL, _row)
        ser.str(string("Bus voltage"))
        ser.position(CURR_MEAS_COL+3, _row)
        ser.str(int.decpadded(vbus, 7))
        ser.str(string("mV"))
        ser.position(MIN_MEAS_COL-3, _row)
        ser.str(int.decpadded(vbus_min, 7))
        ser.position(MAX_MEAS_COL-3, _row)
        ser.str(int.decpadded(vbus_max, 7))

        _row++
        ser.position(MEASUREMENT_COL, _row)
        ser.str(string("Shunt voltage"))
        ser.position(CURR_MEAS_COL+3, _row)
        ser.str(int.decpadded(vshunt, 7))
        ser.str(string("uV"))
        ser.position(MIN_MEAS_COL-3, _row)
        ser.str(int.decpadded(vshunt_min, 7))
        ser.position(MAX_MEAS_COL-3, _row)
        ser.str(int.decpadded(vshunt_max, 7))

        _row++
        ser.position(MEASUREMENT_COL, _row)
        ser.str(string("Current"))
        ser.position(CURR_MEAS_COL+3, _row)
        ser.str(int.decpadded(i, 7))
        ser.str(string("uA"))
        ser.position(MIN_MEAS_COL-3, _row)
        ser.str(int.decpadded(i_min, 7))
        ser.position(MAX_MEAS_COL-3, _row)
        ser.str(int.decpadded(i_max, 7))

        _row++
        ser.position(MEASUREMENT_COL, _row)
        ser.str(string("Power"))
        ser.position(CURR_MEAS_COL+3, _row)
        ser.str(int.decpadded(p, 7))
        ser.str(string("uW"))
        ser.position(MIN_MEAS_COL-3, _row)
        ser.str(int.decpadded(p_min, 7))
        ser.position(MAX_MEAS_COL-3, _row)
        ser.str(int.decpadded(p_max, 7))

        time.msleep(10)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if ina219.startx(SCL_PIN, SDA_PIN, I2C_HZ)
        ser.strln(string("INA219 driver started"))
    else
        ser.strln(string("INA219 driver failed to start - halting"))
        ina219.stop{}
        time.msleep(500)
        ser.stop{}
        repeat

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
