This core allows you to embed a full-speed (12Mbps) USB 2.0 device core into your FPGA design.

## Clocks

The core requires a a reasonably precise 48MHz clock. You'd better derive them from a crystal oscillator.

## Physical interface

Since USB uses a bit of a weird signaling on its half-duplex (almost-)differential line,
you'll, need to do a little bit of work to connect it to the core. The following five signals
connect to D+ and D- USB signals.

 * input rx_j -- the differential value on D+/D- lines
 * input rx_se0 -- single-ended zero detected: should be set when both D+ and D- lines are zero

 * output tx_se0 -- transmit zeros on both USB lines; has priority over tx_j
 * output tx_j -- transmit tx_j to D+ and ~tx_j to D-
 * output tx_en -- enable the trasmitter

If your FPGA doesn't have a differential receiver, then you can simply use two pins and connect them as follows.
However, without a differential receiver, you will be outside of the USB specs.
Make sure the inputs are synchronized to the USB clock.

    inout usb_dp;
    inout usb_dn;

    // ...

    wire usb_tx_se0, usb_tx_j, usb_tx_en;
    usb usb0(
        .rx_j(usb_dp),
        .rx_se0(!usb_dp && !usb_dn),

        .tx_se0(usb_tx_se0),
        .tx_j(usb_tx_j),
        .tx_en(usb_tx_en));

    assign usb_dp = usb_tx_en? (usb_tx_se0? 1'b0: usb_tx_j): 1'bz;
    assign usb_dn = usb_tx_en? (usb_tx_se0? 1'b0: !usb_tx_j): 1'bz;

However, if you have a differential receiver, you'd better use it. Configuring this is FPGA-specific.
For Xilinx Spartan 6 family, I use four physical pins as follows.

    // These pins are configured as differential inputs. Unfortunately,
    // you can't use single-ended receivers nor transmitters on these pins.
    input usb_sp;
    input usb_sn;

    // These pins are single-ended inouts.
    inout usb_dp;
    inout usb_dn'

    // ...

    IBUFDS usb_j_buf(.I(usb_sp), .IB(usb_sn), .O(usb_rx_j_presync));
    synch usb_j_synch(clk_48, usb_rx_j_presync, usb_rx_j);
    synch usb_se0_synch(clk_48, !usb_dp && !usb_dn, usb_rx_se0);

    wire usb_tx_se0, usb_tx_j, usb_tx_en;
    usb usb0(
        .rx_j(usb_rx_j),
        .rx_se0(usb_rx_se0),

        .tx_se0(usb_tx_se0),
        .tx_j(usb_tx_j),
        .tx_en(usb_tx_en));

    assign usb_dp = usb_tx_en? (usb_tx_se0? 1'b0: usb_tx_j): 1'bz;
    assign usb_dn = usb_tx_en? (usb_tx_se0? 1'b0: !usb_tx_j): 1'bz;

Note the synchronization after the receiver.

Whichever pins you transmit on need to have resistors after them.
The exact values will depend on the internal resistance of the pins;
usually something around 27 ohms will be ok.

You also need to pull the D+ line up to 3.3V via a 1.5k resistor.
You can pull it directly, or via a pin on your FPGA, if you want to
dynamically attach/detach to the bus.
Make sure to never pull the line down, the only valid outputs
of the pullup pin are `1'b1` and `1'bz`.
