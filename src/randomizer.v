module randomizer(
    input wire clk,
    input wire rst_n,//active now reset
    output [3:0] rand_pos,//[place to insert]
    output rand_val//0 for insertinig a 2 and 1 for inserting a 4
);

/*
 7-bit LFSR, taps=(1,6), poly x^7+x^5+1, seed=0000001, period=93
 slice = (1,2,4,5)  ->  rand_pos   |   AND = (0,3,6)  ->  rand_val
*/
reg [6:0]rand_reg,rand_regr;
reg xoring;
assign rand_pos={rand_reg[5],rand_reg[4],rand_reg[2],rand_reg[1]};
assign rand_val=rand_reg[0]&&rand_reg[3]&&rand_reg[6];//chosen to make 93 iter not full 127 iter
//last 4 bits are the slice
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rand_reg<=7'b0000001;//part of the 93 iter is diff from 33 or 3 iter
    end
    else begin
        rand_reg<=rand_regr;
    end
end
always@(*)
begin
    xoring=rand_reg[1]^rand_reg[6];
    rand_regr={rand_reg[5:0],xoring};
end
endmodule
