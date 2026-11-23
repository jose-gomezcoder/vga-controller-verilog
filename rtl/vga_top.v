`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// vga_top.v - Board top level (Digilent Basys 3, 12-bit VGA port)
//
// Divides the 100 MHz board clock into a 25 MHz pixel enable, generates
// 640x480 @ 60 Hz timing and shows a test pattern chosen with sw[1:0].
// btnC is the reset.
// -----------------------------------------------------------------------------
module vga_top (
    input  wire       clk,         // 100 MHz
    input  wire       btnC,
    input  wire [1:0] sw,
    output reg  [3:0] vgaRed,
    output reg  [3:0] vgaGreen,
    output reg  [3:0] vgaBlue,
    output reg        Hsync,
    output reg        Vsync
);
    wire rst = btnC;

    // 100 MHz / 4 = 25 MHz pixel enable
    reg [1:0] div;
    always @(posedge clk) begin
        if (rst) div <= 2'd0;
        else     div <= div + 1'b1;
    end
    wire pix_en = (div == 2'd3);

    // Switches are asynchronous to clk: bring them in through two flops
    reg [1:0] sw_meta, sw_sync;
    always @(posedge clk) begin
        sw_meta <= sw;
        sw_sync <= sw_meta;
    end

    wire        hs, vs, video_on;
    wire [9:0]  x, y;
    wire [11:0] rgb;

    vga_sync u_sync (
        .clk(clk), .rst(rst), .pix_en(pix_en),
        .hsync(hs), .vsync(vs), .video_on(video_on), .x(x), .y(y)
    );

    pattern_gen u_pattern (
        .x(x), .y(y), .video_on(video_on), .mode(sw_sync), .rgb(rgb)
    );

    // Register colour and sync together so they reach the DAC aligned
    always @(posedge clk) begin
        if (rst) begin
            {vgaRed, vgaGreen, vgaBlue} <= 12'h000;
            Hsync <= 1'b1;
            Vsync <= 1'b1;
        end else if (pix_en) begin
            {vgaRed, vgaGreen, vgaBlue} <= rgb;
            Hsync <= hs;
            Vsync <= vs;
        end
    end
endmodule
