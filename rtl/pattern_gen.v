`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// pattern_gen.v - Test-pattern generator, 12-bit colour (4 bits per channel)
//
//   mode 0 : eight vertical colour bars (white, yellow, cyan, green,
//            magenta, red, blue, black), 80 pixels each
//   mode 1 : 32x32 checkerboard
//   mode 2 : colour gradient (red rises left to right, green top to bottom)
//   mode 3 : 32-pixel grid with a white border
//
// Purely combinational. Output is black outside the visible area.
// rgb = {red[3:0], green[3:0], blue[3:0]}
// -----------------------------------------------------------------------------
module pattern_gen (
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire        video_on,
    input  wire [1:0]  mode,
    output reg  [11:0] rgb
);
    reg [2:0] bar;
    reg [2:0] bar_rgb;   // {r, g, b} on/off

    always @(*) begin
        // which colour bar this pixel falls in (0..7)
        if      (x <  80) bar = 3'd0;
        else if (x < 160) bar = 3'd1;
        else if (x < 240) bar = 3'd2;
        else if (x < 320) bar = 3'd3;
        else if (x < 400) bar = 3'd4;
        else if (x < 480) bar = 3'd5;
        else if (x < 560) bar = 3'd6;
        else              bar = 3'd7;

        case (bar)
            3'd0: bar_rgb = 3'b111;   // white
            3'd1: bar_rgb = 3'b110;   // yellow
            3'd2: bar_rgb = 3'b011;   // cyan
            3'd3: bar_rgb = 3'b010;   // green
            3'd4: bar_rgb = 3'b101;   // magenta
            3'd5: bar_rgb = 3'b100;   // red
            3'd6: bar_rgb = 3'b001;   // blue
            default: bar_rgb = 3'b000; // black
        endcase

        if (!video_on) begin
            rgb = 12'h000;
        end else begin
            case (mode)
                2'd0: rgb = {{4{bar_rgb[2]}}, {4{bar_rgb[1]}}, {4{bar_rgb[0]}}};

                2'd1: rgb = (x[5] ^ y[5]) ? 12'hFFF : 12'h126;

                2'd2: rgb = {x[9:6], y[8:5], 4'h4};

                default: begin
                    if (x == 0 || x == 639 || y == 0 || y == 479)
                        rgb = 12'hFFF;
                    else if (x[4:0] == 5'd0 || y[4:0] == 5'd0)
                        rgb = 12'h0C0;
                    else
                        rgb = 12'h000;
                end
            endcase
        end
    end
endmodule
