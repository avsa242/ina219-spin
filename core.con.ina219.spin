{
    --------------------------------------------
    Filename: core.con.ina219.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started Sep 18, 2019
    Updated Sep 18, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ        = 2_560_000
    SLAVE_ADDR          = $40 << 1

'' Register definitions

    CONFIG              = $00   'RW
    CONFIG_MASK         = $BFFF
    CONFIG_POR          = $399F 'POR value, used to ID the chip
        FLD_RST         = 15
        FLD_BRNG        = 13
        FLD_PG          = 11
        FLD_BADC        = 7
        FLD_SADC        = 3
        FLD_MODE        = 0

    SHUNT_VOLTAGE       = $01   'RO

    BUS_VOLTAGE         = $02   '|
    BUS_VOLTAGE_MASK    = $FFFB
    FLD_BD              = 3
    FLD_CNVR            = 1
    FLD_OVF             = 0

    POWER               = $03   '|
    CURRENT             = $04   '|
    CALIBRATION         = $05   'RW

PUB Null
'' This is not a top-level object
