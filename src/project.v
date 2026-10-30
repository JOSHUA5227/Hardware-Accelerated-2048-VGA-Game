/*
 * Copyright (c) 2026 Tamil Selvan, Neti Udaya Karthikeya, Ayush Verma, Joshua Quinthino Albuque
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
  wire [1:0] vga_row,vga_col;//location request by vga_controller

  // TinyVGA PMOD connect these to the vga sink RGB vector given is mapped to the MSB
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  // Unused outputs assigned to 0.
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in, ui_in[7:5], 1'b0};//doesnt drive anything

  wire rand_val; //random 2(1'b0) or 4(1'b1) value from LFSR to be inserted in grid
  wire [3:0] rand_pos; // random posistion from LFSR

  wire [3:0] grid_value;//used by vga fully combinationally provided by game logic at (vga_row,vga_col)
  wire game_win;
  wire game_loss;

  wire s_rst;
  wire [3:0] y;

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
    .pix_x(pix_x),
    .pix_y(pix_y),
    .video_active(video_active),
    .row(vga_row),
    .col(vga_col),
    .value(grid_value),
    .won(game_win),
    .lost(game_loss),
    .R(R),
    .G(G),
    .B(B)
  );

  debounce_top db(
      .clk(clk),
      .rst_n(rst_n),
      //using vsync for checking temporal stability of input given
      .vsync(vsync),
      .btns(ui_in[4:0]),
      .s_rst(s_rst),
      .y(y)
  );

  update u_grid_core(
    .clk(clk),
    .rst_n(rst_n), // ACTIVE low Hard Reset
    .s_rst(s_rst), // ACTIVE high soft game reset
    //directions
    .U(y[3]),
    .D(y[2]),
    .L(y[1]),
    .R(y[0]),
    //VGA grid value output
    .vga_col(vga_col),
    .vga_row(vga_row),
    .grid_value(grid_value),// main playing grid
    //fetch from randomizer
    .tworfr(rand_val), //start enable signal for LFSR once all updates and shifting is done
    .rand_pos(rand_pos),// random posistion from LFSR
    //game over condition to VGA
    .gamewon_vga(game_win),
    .gamelost_vga(game_loss)
  );

  randomizer random(
    .clk(clk),
    .rst_n(rst_n),
    .rand_pos(rand_pos),
    .rand_val(rand_val)
  );
endmodule
