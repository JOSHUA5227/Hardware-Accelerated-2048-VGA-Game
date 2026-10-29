`default_nettype none

module vga_controller (
    input  wire [9:0] pix_x, pix_y,
    input  wire       video_active, won, lost,
    input  wire [3:0] value,          // 0 = empty, 1..11 = tile 2^value
    output wire [1:0] row, col,
    output wire [1:0] R, G, B
);

  // ---------------------------------------------------------------------------
  // Board geometry: 256x256 px, 4x4 cells of 64x64 px, centred -> origin (192,112)
  // ---------------------------------------------------------------------------
  wire [3:0] xn = pix_x[9:6] - 4'd3;   // (pix_x - 192) / 64
  wire [5:0] yn = pix_y[9:4] - 6'd7;   // (pix_y - 112) / 16

  wire inside_board = (xn[3:2] == 2'b00) && (yn[5:4] == 2'b00);

  assign col = xn[1:0];
  assign row = yn[3:2];

  wire [5:0] cell_x = pix_x[5:0];             // 0..63 inside a cell
  wire [5:0] cell_y = {yn[1:0], pix_y[3:0]};  // 0..63 inside a cell

  // Small white dot in the middle of an empty cell
  wire center = (cell_x[5:1] == 5'd15) && (cell_y[5:1] == 5'd15);

  // ---------------------------------------------------------------------------
  // Tile background colour (RRGGBB, 2 bits each)
  // ---------------------------------------------------------------------------
  reg [5:0] bg;
  always @(*) begin
    case (value)
      4'h1:    bg = 6'b11_00_00; // 2
      4'h2:    bg = 6'b00_10_00; // 4
      4'h3:    bg = 6'b11_11_01; // 8
      4'h4:    bg = 6'b00_10_11; // 16
      4'h5:    bg = 6'b10_01_11; // 32
      4'h6:    bg = 6'b00_11_11; // 64
      4'h7:    bg = 6'b11_01_01; // 128
      4'h8:    bg = 6'b01_11_01; // 256
      4'h9:    bg = 6'b11_10_00; // 512
      4'hA:    bg = 6'b01_01_11; // 1024
      4'hB:    bg = 6'b11_01_11; // 2048
      default: bg = center ? 6'b11_11_11 : 6'b01_01_01; // empty
    endcase
  end

  // ---------------------------------------------------------------------------
  // Number rendering: 3x5 font, each font pixel = 4x4 screen pixels,
  // digit pitch = 16 px (3 columns + 1 blank column).
  // The tiles only contain the digits 0 1 2 3 4 5 6 8, so the font has 8 glyphs.
  // ---------------------------------------------------------------------------
  // Slot entry = {blank, 3-bit glyph index}.  Glyph index 7 means the digit '8'.
  localparam [3:0] G0 = 4'd0, G1 = 4'd1, G2 = 4'd2, G3 = 4'd3,
                   G4 = 4'd4, G5 = 4'd5, G6 = 4'd6, G8 = 4'd7, BL = 4'd8;

  // str  : digits of the number, left aligned, 4 slots (slot 0 = leftmost)
  // q    : 4 - number_of_digits (shifts the text right by 8 px per missing digit
  //        so that the number is centred)
  reg [15:0] str;
  reg [1:0]  q;
  always @(*) begin
    case (value)
      4'd1:    begin str = {G2, BL, BL, BL}; q = 2'd3; end //    2
      4'd2:    begin str = {G4, BL, BL, BL}; q = 2'd3; end //    4
      4'd3:    begin str = {G8, BL, BL, BL}; q = 2'd3; end //    8
      4'd4:    begin str = {G1, G6, BL, BL}; q = 2'd2; end //   16
      4'd5:    begin str = {G3, G2, BL, BL}; q = 2'd2; end //   32
      4'd6:    begin str = {G6, G4, BL, BL}; q = 2'd2; end //   64
      4'd7:    begin str = {G1, G2, G8, BL}; q = 2'd1; end //  128
      4'd8:    begin str = {G2, G5, G6, BL}; q = 2'd1; end //  256
      4'd9:    begin str = {G5, G1, G2, BL}; q = 2'd1; end //  512
      4'd10:   begin str = {G1, G0, G2, G4}; q = 2'd0; end // 1024
      4'd11:   begin str = {G2, G0, G4, G8}; q = 2'd0; end // 2048
      default: begin str = {BL, BL, BL, BL}; q = 2'd0; end
    endcase
  end

  // Horizontal: shift by 2 px so a 60 px wide "2048" has 2 px margin each side,
  // then split into 8-px groups.  d = group index minus the centring offset.
  wire [5:0] tx   = cell_x - 6'd2;
  wire       x_ok = |cell_x[5:1];                    // cell_x >= 2
  wire [3:0] d    = {1'b0, tx[5:3]} - {2'b00, q};
  wire [1:0] slot = d[2:1];                          // which digit
  wire [1:0] gcol = {d[0], tx[2]};                   // font column 0..2, 3 = gap
  wire [3:0] dig  = str[{~slot, 2'b00} +: 4];

  // Glyph bitmaps: 5 rows x 3 columns, top row first
  reg [14:0] glyph;
  always @(*) begin
    case (dig[2:0])
      3'd0:    glyph = 15'b111_101_101_101_111; // 0
      3'd1:    glyph = 15'b010_110_010_010_111; // 1
      3'd2:    glyph = 15'b111_001_111_100_111; // 2
      3'd3:    glyph = 15'b111_001_111_001_111; // 3
      3'd4:    glyph = 15'b101_101_111_001_001; // 4
      3'd5:    glyph = 15'b111_100_111_001_111; // 5
      3'd6:    glyph = 15'b111_100_111_101_111; // 6
      default: glyph = 15'b111_101_111_101_111; // 8
    endcase
  end

  // Vertical: font rows live in cell_y[5:2] = 6..10 (y = 24..43)
  reg [2:0] bits;
  always @(*) begin
    case (cell_y[5:2])
      4'd6:    bits = glyph[14:12];
      4'd7:    bits = glyph[11:9];
      4'd8:    bits = glyph[8:6];
      4'd9:    bits = glyph[5:3];
      4'd10:   bits = glyph[2:0];
      default: bits = 3'b000;
    endcase
  end

  wire font_px = (gcol == 2'd0) ? bits[2] :
                 (gcol == 2'd1) ? bits[1] :
                 (gcol == 2'd2) ? bits[0] : 1'b0;

  wire text_on = font_px & ~dig[3] & ~d[3] & x_ok;

  // ---------------------------------------------------------------------------
  // Output colour
  // ---------------------------------------------------------------------------
  reg [5:0] rgb;
  always @(*) begin
    if (!video_active)    rgb = 6'b00_00_00;
    else if (inside_board) rgb = text_on ? 6'b00_00_00 : bg;
    else                  rgb = won ? 6'b00_10_01 : (lost ? 6'b11_00_00 : 6'b00_00_00);
  end

  assign {R, G, B} = rgb;

endmodule
