module adder(
input wire [3:0] A,
input wire B,
output wire [3:0] alu_res
);

assign alu_res = A + B;
endmodule
