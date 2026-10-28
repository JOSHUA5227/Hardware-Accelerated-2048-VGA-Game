module adder(
input wire [3:0] A,
input wire B,
output wire [3:0] alu_res
);

wire [4:0] res;
assign res = A + B;

assign alu_res = res[3:0];
endmodule
