module comparator(
input wire [3:0] A,B,
output wire Z
);
assign Z = A == B;
endmodule
