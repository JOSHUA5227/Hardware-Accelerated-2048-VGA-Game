/*
 * Copyright (c) 2026 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_2048 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

  wire s_rst;
  wire up,down,left,right;
  wire rand_start; //start enable signal for LFSR once all updates and shifting is done
  wire [63:0] grid; // main playing grid 
  wire [7:0] rand_pos; // random posistion from LFSR

  wire game_win;
  wire game_loss;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  vga_controller vga_contr (
    .grid_flat(grid),
    .pix_x(pix_x),
    .pix_y(pix_y),
    .video_active(video_active),
    .won(game_win),
    .lost(game_loss),
    .R(R),
    .G(G), 
    .B(B)
  );

  grid_core u_grid_core(
    .clk(clk),
    .rst_n(rst_n), // ACTIVE low Hard Reset
    .s_rst(s_rst), // ACTIVE high soft game reset

    .up(up),
    .down(down),
    .left(left),
    .right(right),

    .grid_flat(grid),// main playing grid 

    .rand_start(rand_start), //start enable signal for LFSR once all updates and shifting is done
    .rand_pos(rand_pos),// random posistion from LFSR

    .game_win(game_win),
    .game_loss(game_loss)
  );

endmodule
