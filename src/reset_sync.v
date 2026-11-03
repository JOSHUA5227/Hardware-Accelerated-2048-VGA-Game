module reset_sync(
    input wire in_rst,
    output wire out_rst,
    input wire clk);

reg reset_sync01,reset_sync02;

always@(posedge clk, negedge in_rst)begin
    if(~in_rst)
    begin
        reset_sync01<=1'b0;
        reset_sync02<=1'b0;
    end
    else begin
        reset_sync01<=1'b1;
        reset_sync02<=reset_sync01;
    end

end
assign out_rst=reset_sync02;
endmodule
