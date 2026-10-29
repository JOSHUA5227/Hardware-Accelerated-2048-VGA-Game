`default_nettype none

module debouncer (
    input wire clk,
    input wire rst_n,
    input wire btn,
    input wire vsync,
    input wire [2:0] enc_sel, // Select lines coming from 8:3 encoder so that if higher priority button is pressed then we restart the counter
    output reg y,
    output reg [2:0] sel_lines
);

    reg [1:0] ps, ns;
    reg vsync_reg;
    reg count, count_next;
    wire tick = vsync_reg & ~vsync;
    localparam S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ps <= S0;
            count <= 1'b0;
            vsync_reg <= 1'b0;
            sel_lines <= 3'd0;
        end
        else begin
            ps <= ns;
            vsync_reg <= vsync;
            if(ps == S0) begin
                sel_lines <= enc_sel;
            end
            count <= count_next;
        end
    end
    
    always @(*) begin
        ns = ps;
        y = 1'b0;
        // count keeps its value between ticks, it only changes on a tick or a bounce
        count_next = count;
        case(ps)
            S0: begin
                if(btn) ns = S1;
            end
            
            S1: begin
                if(btn == 1) begin
                    if(tick) begin
                        if(count) begin
                            ns = S2;
                            count_next = 1'b0;
                        end
                        else begin
                            count_next = 1'b1;
                        end
                    end
                end
                else begin
                    ns = S0;
                    count_next = 1'b0;
                end
            end
            
            S2: begin
                y = 1'b1;
                if(btn == 0) ns = S3;
            end
            
            S3: begin
                y = 1'b1;
                if(btn == 0 || (sel_lines != enc_sel)) begin
                    if(tick) begin
                        if(count) begin
                            ns = S0;
                            count_next = 1'b0;
                        end
                        else begin
                            count_next = 1'b1;
                        end
                    end
                end
                else begin
                    ns = S2;
                    count_next = 1'b0;
                end
            end
        endcase
        if(ps == S1) begin
            if (sel_lines != enc_sel) begin
                ns = S0;
                count_next = 1'b0;
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
            y = 3'd1;
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
            q <= 5'd0;
            q_sync <= 5'd0;
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
    input wire vsync,
    output reg s_rst,
    output reg [3:0] y
);
    wire [4:0] sync_out;
    wire [2:0] pr_enc_out;
    wire mux_out;
    wire debounced_out;
    wire [2:0] sel_lines;

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
        .vsync(vsync),
        .enc_sel(pr_enc_out),
        .y(debounced_out),
        .sel_lines(sel_lines)
    );

    // Demux
    always @(*) begin
        s_rst = 1'b0;
        y = 4'd0;
        if(debounced_out) begin
            case(sel_lines)
                3'd0: s_rst = 1'b1;
                3'd4: y = 4'b0001; // up
                3'd5: y = 4'b0010; // left
                3'd6: y = 4'b0100; // down
                3'd7: y = 4'b1000; // right
                default: begin
                    s_rst = 1'b0;
                    y = 4'd0;
                end
            endcase
        end
    end
endmodule