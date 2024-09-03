{
----------------------------------------------------------------------------------------------------
    Filename:       INA219-Demo.spin
    Description:    Demo of the INA219 driver
        * Power data output
    Author:         Jesse Burt
    Started:        Sep 18, 2019
    Updated:        Sep 3, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}
' Uncomment the below lines to use the bytecode-based I2C engine
'#define INA219_I2C_BC
'#pragma exportdef(INA219_I2C_BC)

CON

    _clkmode        = xtal1+pll16x
    _xinfreq        = 5_000_000


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.power.ina219" | SCL=28, SDA=29, I2C_FREQ=1_000_000, I2C_ADDR=%0000
    time:   "time"


PUB main()

    setup()

    repeat
        ser.pos_xy(0, 3)
        ' scale sensor data down from microvolts/amps/watts and show it on the terminal
        ser.printf2(@"Voltage: %d.%06.6dv\n\r", (sensor.voltage() / VF), ...    ' display whole
                                                (sensor.voltage() // VF))       ' display part

        ser.printf2(@"Current: %d.%06.6dA\n\r", (sensor.current() / CF), ...
                                                ||(sensor.current() // CF))

        ser.printf2(@"Power: %d.%06.6dW\n\r",   (sensor.power() / PF), ...
                                                (sensor.power() // PF))

CON

    { scaling factors for display }
    VF  = 1000000
    CF  = 1000000
    PF  = 1000000


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"INA219 driver started")
    else
        ser.strln(@"INA219 driver failed to start - halting")
        repeat

    sensor.preset_320s_2a_100mohm()

    sensor.current_set_scale(4096)              ' 0..65535
                                                ' (must be >0 for current/power readings)


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

