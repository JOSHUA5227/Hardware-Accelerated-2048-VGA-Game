// If we go for 24ms
// Since clock running at 25.175 MHz, so count value till (24*10^-3)*(25.175*10^6) = 604,200
// So we require 20-bit counter
// 604_200d = 1001 0011 1000 0010 1000
// 579_025d = 1000 1101 0101 1101 0001
// Thus we can only check when upper 4-bits become 1001, that means we are checking somewhere between 23 to 24 ms
// In this way we don't need 20-bit compartor, just 4-bit would work

`default_nettype none

module debouncer #(
    parameter debounce_limit = 20'b1001_0011_1000_0010_1000
)(
    input wire clk,
    input wire rst_n,
    input wire btn,
    input wire [2:0] enc_sel, // Select lines coming from 8:3 encoder so that if higher priority button is pressed then we restart the counter
    output reg y
);

    reg [1:0] ps, ns;
    reg [19:0] t_curr, t_next;
    reg [2:0] sel_lines;
    localparam S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ps <= S0;
            t_curr <= 20'd0;
            sel_lines <= 3'd0;
        end
        else begin
            ps <= ns;
            t_curr <= t_next;
            if(ps == S0) begin
                sel_lines <= enc_sel;
            end
        end
    end
    
    always @(*) begin
        ns = ps;
        t_next = t_curr;
        y = 0;
        case(ps)
            S0: begin
                if(btn) ns = S1;
            end
            
            S1: begin
                if(btn == 1) begin
                    if(t_curr[19:16] == debounce_limit[19:16]) begin
                        ns = S2;
                        t_next = 20'd0;
                    end
                    else t_next = t_curr + 20'd1;
                end
                else begin
                    t_next = 20'd0;
                    ns = S0;
                end
            end
            
            S2: begin
                y = 1;
                if(btn == 0) ns = S3;
            end
            
            S3: begin
                y = 1;
                if(btn == 0) begin
                    if(t_curr[19:16] == debounce_limit[19:16]) begin
                        ns = S0;
                        t_next = 20'd0;
                    end
                    else t_next = t_curr + 20'd1;
                end
                else begin
                    t_next = 20'd0;
                    ns = S2;
                end
            end
        endcase
        if(ps == S1) begin
            if (sel_lines != enc_sel) begin
                ns = S0;
                t_next = 20'd0;
            end
        end
    end
endmodule

module priority_encoder(
    // s_rst > up > down > left > right
    input wire [7:0]i,
    output reg [2:0]y
);

    always @(*) begin
        // s_rst for i[7], in any of the rest cases trigger s_rst too
        if (i[7]) begin
            y = 3'd0;
        end
        else if(i[6]) begin
            y = 3'd1;
        end
        else if(i[5]) begin
            y = 3'd2;
        end
        else if(i[4]) begin
            y = 3'd3;
        end
        // up
        else if (i[3]) begin
            y = 3'd4;
        end 
        // left
        else if (i[2]) begin
            y = 3'd5;
        end
        // down
        else if (i[1]) begin
            y = 3'd6;
        end
        // right
        else if (i[0]) begin
            y = 3'd7;
        end
        else begin
            y = 3'd0;
        end
    end
    
endmodule

module mux(
    input wire [3:0]btns,
    input wire s_rst,
    input wire [2:0]sel,
    output wire y
);
    reg button_selected;
    // 4x1 Mux to choose between the buttons
    always @(*) begin
        case(sel[1:0])
            2'b00: button_selected = btns[3];
            2'b01: button_selected = btns[2];
            2'b10: button_selected = btns[1];
            2'b11: button_selected = btns[0];
            default: button_selected = btns[3];
        endcase
    end
    
    // 2x1 Mux to choose between s_rst and the selected button
    assign y = sel[2] ? button_selected : s_rst;
endmodule

module d_ff(
    input wire [4:0]d,
    input wire clk, rst_n,
    output reg [4:0]q
);
    reg [4:0]q_sync;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            q <= 0;
            q_sync <= 0;
        end
        else begin
            q_sync <= d;
            q <= q_sync;
        end
    end
endmodule

module debounce_top(
    input wire [4:0] btns,
    input wire clk,
    input wire rst_n,
    output reg s_rst,
    output reg [3:0] y
);
    wire [4:0] sync_out;
    wire [2:0] pr_enc_out;
    wire mux_out;
    wire debounced_out;
    
    d_ff ffs(
        .d(btns),
        .clk(clk),
        .rst_n(rst_n),
        .q(sync_out)
    );
    
    priority_encoder pr_enc(
        .i({sync_out[4],3'd0,sync_out[3:0]}),
        .y(pr_enc_out)
    );
    
    mux muxes(
        .btns(sync_out[3:0]),
        .s_rst(sync_out[4]),
        .sel(pr_enc_out),
        .y(mux_out)
    );
    
    debouncer deb(
        .clk(clk),
        .rst_n(rst_n),
        .btn(mux_out),
        .enc_sel(pr_enc_out),
        .y(debounced_out)
    );

    always @(*) begin
        s_rst = 0;
        y = 4'd0;
        if(debounced_out) begin
            case(pr_enc_out)
                3'd0,3'd1,3'd2,3'd3: s_rst = 1;
                3'd4: y = 4'b0001; // up
                3'd5: y = 4'b0010; // left
                3'd6: y = 4'b0100; // down
                3'd7: y = 4'b1000; // right
                default: begin
                    s_rst = 0;
                    y = 4'd0;
                end
            endcase
        end
    end
endmodule
