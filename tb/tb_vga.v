`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// tb_vga.v - Self-checking testbench for vga_sync and pattern_gen
//
// Runs vga_sync with a pixel enable on every clock and checks one full frame:
//   - the frame is exactly 800 x 525 clocks and wraps back to (0,0)
//   - hsync is low 96 clocks per line, starting at x = 656
//   - vsync is low for 2 lines, starting at y = 490
//   - video_on is high for exactly 640 x 480 pixels
// Then spot-checks a few pattern_gen colours. Prints PASS or FAIL.
// -----------------------------------------------------------------------------
module tb_vga;
    reg clk = 1'b0;
    reg rst = 1'b1;
    always #20 clk = ~clk;     // 25 MHz

    wire       hsync, vsync, video_on;
    wire [9:0] x, y;

    vga_sync dut (
        .clk(clk), .rst(rst), .pix_en(1'b1),
        .hsync(hsync), .vsync(vsync), .video_on(video_on), .x(x), .y(y)
    );

    // pattern_gen driven directly by the testbench
    reg  [9:0]  px = 0, py = 0;
    reg         pon = 1'b0;
    reg  [1:0]  pmode = 2'd0;
    wire [11:0] prgb;

    pattern_gen u_pat (.x(px), .y(py), .video_on(pon), .mode(pmode), .rgb(prgb));

    integer i;
    integer errors    = 0;
    integer hs_low    = 0;
    integer vs_low    = 0;
    integer visible   = 0;
    integer hs_starts = 0;
    integer vs_starts = 0;
    reg     hs_prev   = 1'b1;
    reg     vs_prev   = 1'b1;

    task check(input [255:0] name, input integer got, input integer expected);
        begin
            if (got !== expected) begin
                $display("FAIL: %0s = %0d, expected %0d", name, got, expected);
                errors = errors + 1;
            end else begin
                $display("  ok: %0s = %0d", name, got);
            end
        end
    endtask

    task check_rgb(input [9:0] tx, input [9:0] ty, input ton, input [1:0] tmode,
                   input [11:0] expected);
        begin
            px = tx; py = ty; pon = ton; pmode = tmode;
            #1;
            if (prgb !== expected) begin
                $display("FAIL: pattern mode %0d at (%0d,%0d) = %03h, expected %03h",
                         tmode, tx, ty, prgb, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_vga.vcd");
        $dumpvars(0, tb_vga);

        repeat (3) @(negedge clk);
        rst = 1'b0;

        // ---- one full frame, sampled on the falling edge ----
        for (i = 0; i < 800 * 525; i = i + 1) begin
            if (i == 0 && !(x == 0 && y == 0)) begin
                $display("FAIL: frame did not start at (0,0)");
                errors = errors + 1;
            end
            if (!hsync) hs_low = hs_low + 1;
            if (!vsync) vs_low = vs_low + 1;
            if (video_on) visible = visible + 1;

            if (hs_prev && !hsync) begin
                hs_starts = hs_starts + 1;
                if (x != 656) begin
                    $display("FAIL: hsync fell at x=%0d (expected 656)", x);
                    errors = errors + 1;
                end
            end
            if (vs_prev && !vsync) begin
                vs_starts = vs_starts + 1;
                if (y != 490 || x != 0) begin
                    $display("FAIL: vsync fell at (%0d,%0d) (expected (0,490))", x, y);
                    errors = errors + 1;
                end
            end
            hs_prev = hsync;
            vs_prev = vsync;
            @(negedge clk);
        end

        if (!(x == 0 && y == 0)) begin
            $display("FAIL: counters at (%0d,%0d) after one frame, expected (0,0)", x, y);
            errors = errors + 1;
        end

        check("hsync low clocks",  hs_low,    96 * 525);
        check("hsync pulses",      hs_starts, 525);
        check("vsync low clocks",  vs_low,    2 * 800);
        check("vsync pulses",      vs_starts, 1);
        check("visible pixels",    visible,   640 * 480);

        // ---- pattern spot checks ----
        check_rgb(10'd0,   10'd0,   1'b1, 2'd0, 12'hFFF);  // white bar
        check_rgb(10'd100, 10'd50,  1'b1, 2'd0, 12'hFF0);  // yellow bar
        check_rgb(10'd450, 10'd50,  1'b1, 2'd0, 12'hF00);  // red bar
        check_rgb(10'd500, 10'd50,  1'b1, 2'd0, 12'h00F);  // blue bar
        check_rgb(10'd639, 10'd479, 1'b1, 2'd0, 12'h000);  // black bar
        check_rgb(10'd100, 10'd50,  1'b0, 2'd0, 12'h000);  // blanking
        check_rgb(10'd0,   10'd0,   1'b1, 2'd1, 12'h126);  // checker square
        check_rgb(10'd32,  10'd0,   1'b1, 2'd1, 12'hFFF);  // checker square
        check_rgb(10'd0,   10'd100, 1'b1, 2'd3, 12'hFFF);  // grid border
        check_rgb(10'd64,  10'd100, 1'b1, 2'd3, 12'h0C0);  // grid line
        check_rgb(10'd65,  10'd101, 1'b1, 2'd3, 12'h000);  // grid background

        if (errors == 0)
            $display("PASS: VGA timing and test patterns correct");
        else
            $display("FAIL: %0d error(s)", errors);
        $finish;
    end
endmodule
