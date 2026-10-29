`default_nettype none

// Frame-synchronous input handler.
// Buttons are sampled once per VGA frame (~60 Hz = 16.7 ms), which is much longer than
// contact bounce, so no free-running debounce counter is needed.
//  - s1/s2 : free-running 2-FF synchroniser per button
//  - a     : previous frame's sample, lvl : debounced level (needs 2 equal samples to change)
//  - output: ONE clk-wide pulse per accepted press, direction priority applied
module debounce_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       vsync,    // any ~60 Hz signal with one edge per frame
    input  wire [4:0] btns,     // [4] = soft reset, [3:0] = direction buttons
    output wire       s_rst,
    output wire [3:0] y         // pulses, same bit order as the old module
);
    reg       vs_q;
    reg [4:0] s1, s2, a, lvl;
    wire      tick = vs_q & ~vsync;            // one clk-wide pulse per frame

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vs_q <= 1'b0; s1 <= 5'd0; s2 <= 5'd0; a <= 5'd0; lvl <= 5'd0;
        end else begin
            vs_q <= vsync;
            s1   <= btns;
            s2   <= s1;
            if (tick) begin
                a   <= s2;
                lvl <= (s2 & a) | (lvl & (s2 | a));   // set on 2 highs, clear on 2 lows
            end
        end
    end

    wire [4:0] pulse = {5{tick}} & s2 & a & ~lvl;      // rising edge of debounced level

    // priority: reset > ui_in[3] > ui_in[2] > ui_in[1] > ui_in[0]  (as in the old encoder)
    assign s_rst = pulse[4];
    wire   go    = ~pulse[4];
    assign y[0]  = go & pulse[3];
    assign y[1]  = go & ~pulse[3] & pulse[2];
    assign y[2]  = go & ~pulse[3] & ~pulse[2] & pulse[1];
    assign y[3]  = go & ~pulse[3] & ~pulse[2] & ~pulse[1] & pulse[0];
endmodule
