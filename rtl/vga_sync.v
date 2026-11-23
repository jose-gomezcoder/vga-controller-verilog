`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// vga_sync.v - VGA timing generator (default: 640x480 @ 60 Hz)
//
// Counts pixels (x) and lines (y) on every pix_en pulse. The default timing
// needs a 25.175 MHz pixel rate; 25 MHz (100 MHz / 4) is within what
// monitors accept.
//
//            visible   front   sync   back   total
//   horiz      640       16     96     48     800  pixels
//   vert       480       10      2     33     525  lines
//
// hsync / vsync are active low. All outputs are combinational from the
// counters so that they stay aligned with x / y; register them together with
// the pixel colour in the top level.
// -----------------------------------------------------------------------------
module vga_sync #(
    parameter integer H_VISIBLE = 640,
    parameter integer H_FRONT   = 16,
    parameter integer H_SYNC    = 96,
    parameter integer H_BACK    = 48,
    parameter integer V_VISIBLE = 480,
    parameter integer V_FRONT   = 10,
    parameter integer V_SYNC    = 2,
    parameter integer V_BACK    = 33
)(
    input  wire       clk,
    input  wire       rst,        // synchronous, active high
    input  wire       pix_en,     // one-cycle pulse at the pixel rate
    output wire       hsync,
    output wire       vsync,
    output wire       video_on,
    output reg  [9:0] x,
    output reg  [9:0] y
);
    localparam integer H_TOTAL = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;   // 800
    localparam integer V_TOTAL = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;   // 525

    always @(posedge clk) begin
        if (rst) begin
            x <= 10'd0;
            y <= 10'd0;
        end else if (pix_en) begin
            if (x == H_TOTAL - 1) begin
                x <= 10'd0;
                if (y == V_TOTAL - 1)
                    y <= 10'd0;
                else
                    y <= y + 1'b1;
            end else begin
                x <= x + 1'b1;
            end
        end
    end

    assign hsync = ~((x >= H_VISIBLE + H_FRONT) && (x < H_VISIBLE + H_FRONT + H_SYNC));
    assign vsync = ~((y >= V_VISIBLE + V_FRONT) && (y < V_VISIBLE + V_FRONT + V_SYNC));
    assign video_on = (x < H_VISIBLE) && (y < V_VISIBLE);
endmodule
