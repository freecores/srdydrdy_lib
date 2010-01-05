
// Address size for number of ports.  Default value 4,
// which will allow design to scale up to 16 ports
`define PORT_ASZ    4

// We will have only 4 ports in our sample design
`define NUM_PORTS   4

// Data structure from parser to FIB.  Contains MAC DA,
// MAC SA, and source port
`define PAR_DATA_SZ (48+48+4)
`define PAR_MACDA    47:0
`define PAR_MACSA    95:48
`define PAR_SRCPORT  99:96

// number of entries in FIB table
`define FIB_ENTRIES   256
`define FIB_ASZ       $clog2(`FIB_ENTRIES)

// FIB entry definition
`define FIB_ENTRY_SZ  60
`define FIB_MACADDR   47:0     // MAC address
`define FIB_AGE       55:48    // 8 bit age counter
`define FIB_PORT      59:56    // associated port

`define FIB_MAX_AGE   255      // maximum value of age timer

`define MULTICAST     48'h0100000000  // multicast bit