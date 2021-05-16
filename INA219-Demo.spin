{
    --------------------------------------------
    Filename: INA219-Demo.spin
    Author: Jesse Burt
    Description: Demo of the INA219 driver
    Copyright (c) 2020
    Started Sep 18, 2019
    Updated Dec 3, 2020
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

    VBUS_COL        = 0
    VSHUNT_COL      = VBUS_COL+15
    I_COL           = VSHUNT_COL+15
    P_COL           = I_COL+15

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    ina219  : "sensor.power.ina219.i2c"
    int     : "string.integer"

PUB Main{} | vbus, vshunt, i, p

    setup{}

    ina219.preset320s_2a_100mohm{}

    ina219.currentbias(4096)                    ' 0..65535
                                                ' (>0 for current readings)

    ser.position(VBUS_COL, 3)
    ser.str(string("Bus voltage"))
    ser.position(VSHUNT_COL, 3)
    ser.str(string("Shunt voltage"))
    ser.position(I_COL, 3)
    ser.str(string("Current"))
    ser.position(P_COL, 3)
    ser.str(string("Power"))

    repeat
        vbus := ina219.busvoltage{}
        vshunt := ina219.shuntvoltage{}
        i := ina219.current{}
        p := ina219.power{}

        ser.position(VBUS_COL, 5)
        decimal(vbus, 1000)
        ser.str(string("V  "))

        ser.position(VSHUNT_COL, 5)
        decimal(vshunt, 1_000_000)
        ser.str(string("V  "))

        ser.position(I_COL, 5)
        decimal(i, 10)
        ser.str(string("mA  "))

        ser.position(P_COL, 5)
        decimal(p, 1000)
        ser.str(string("W  "))

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp, sign
' Display a scaled up number as a decimal
'   Scale it back down by divisor (e.g., 10, 100, 1000, etc)
    whole := scaled / divisor
    tmp := divisor
    places := 0
    part := 0
    sign := 0
    if scaled < 0
        sign := "-"
    else
        sign := " "

    repeat
        tmp /= 10
        places++
    until tmp == 1
    scaled //= divisor
    part := int.deczeroed(||(scaled), places)

    ser.char(sign)
    ser.dec(||(whole))
    ser.char(".")
    ser.str(part)

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
