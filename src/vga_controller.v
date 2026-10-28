`default_nettype none

module vga_controller(
  input wire [9:0] pix_x, pix_y,
  input wire video_active, won, lost,

  input wire [3:0] grid,
  output [1:0] row,col,

  output wire [1:0] R, G, B
);

  // Parameterized sizes
  localparam BOARD_SIZE = 300;  // variable board size; preferable range 256 - 400
  localparam BOARD_X = (640 - BOARD_SIZE) / 2;
  localparam BOARD_Y = (480 - BOARD_SIZE) / 2;
  localparam CELL_SIZE = BOARD_SIZE / 4; 

  wire inside_board = (pix_x >= BOARD_X && pix_x < BOARD_X + BOARD_SIZE) &&
                      (pix_y >= BOARD_Y && pix_y < BOARD_Y + BOARD_SIZE);

  wire [9:0] rel_x = pix_x - BOARD_X;
  wire [9:0] rel_y = pix_y - BOARD_Y;

  assign col = (rel_x >= CELL_SIZE * 3) ? 2'd3 :
                   (rel_x >= CELL_SIZE * 2) ? 2'd2 :
                   (rel_x >= CELL_SIZE * 1) ? 2'd1 : 2'd0;

  assign row = (rel_y >= CELL_SIZE * 3) ? 2'd3 :
                   (rel_y >= CELL_SIZE * 2) ? 2'd2 :
                   (rel_y >= CELL_SIZE * 1) ? 2'd1 : 2'd0;

  wire [9:0] cell_x = rel_x - (col * CELL_SIZE);
  wire [9:0] cell_y = rel_y - (row * CELL_SIZE);

  wire [3:0] current_tile = grid;

  wire center = (cell_x >= (CELL_SIZE/2 - 1)) && (cell_x <= (CELL_SIZE/2)) && 
                (cell_y >= (CELL_SIZE/2 - 1)) && (cell_y <= (CELL_SIZE/2));

  function automatic [5:0] get_colour;
    input [3:0] grid;
    begin
      case (grid)
        4'h0: get_colour = center ? 6'b11_11_11 : 6'b01_01_01; // Empty
        4'h1: get_colour =  6'b11_00_00; // 2
        4'h2: get_colour =  6'b00_10_00; // 4
        4'h3: get_colour =  6'b11_11_01; // 8
        4'h4: get_colour =  6'b00_10_11; // 16
        4'h5: get_colour =  6'b10_01_11; // 32
        4'h6: get_colour =  6'b00_11_11; // 64
        4'h7: get_colour =  6'b11_01_01; // 128
        4'h8: get_colour =  6'b01_11_01; // 256
        4'h9: get_colour =  6'b11_10_00; // 512
        4'hA: get_colour =  6'b01_01_11; // 1024
        4'hB: get_colour =  6'b11_01_11; // 2048
        default: get_colour = center ? 6'b11_11_11 : 6'b01_01_01;
      endcase
    end
  endfunction

  reg [5:0] rgb;
  assign {R, G, B} = rgb;
  
  always @(*) begin
      rgb = 6'b00_00_00;
      if(video_active) begin
        if(inside_board) rgb = get_colour(grid);
      end
  end
 
endmodule
