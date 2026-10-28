module grid_core(
input wire clk,
input wire rst_n, // ACTIVE low Hard Reset
input wire s_rst, // ACTIVE high soft game reset

input wire up,down,left,right,

output wire [63:0] grid_flat, // main playing grid 

output reg rand_start, //start enable signal for LFSR once all updates and shifting is done
input wire [3:0] rand_pos,// random posistion from LFSR
input wire rand_val,

output reg game_win,
output wire game_loss
);
// Ports to Adder/Comparator
wire [3:0] A;
reg [3:0] cmp_B;
wire [3:0] alu_res; // Addition result 
wire Z; // 1 when result is 0

reg [3:0] grid[0:3][0:3];// main playing grid 
adder u_adder(
.A(A),
.B(1'b1),
.alu_res(alu_res)
);

comparator u_comparator(
.A(A),
.B(cmp_B),
.Z(Z)
);

generate
  genvar r, c;
  for (r = 0; r < 4; r = r + 1) begin : row_loop
    for (c = 0; c < 4; c = c + 1) begin : col_loop
        assign grid_flat[63 - (r * 16 + c * 4) -: 4] = grid[r][c];
    end
  end
endgenerate

reg [3:0] grid[0:3][0:3]; // main playing grid

//GAME UPDATE LOGIC
reg [1:0] rows,cols;// grid travesal 
reg is_updated; // Set to 1 Whenever there is any change in the grid
reg [15:0] valid;//valid array for when deciding if the location should not be used for updating

reg values_calculated; // flag to speificy when calculating the new values are done
reg update_done; //complete cycle is done and allow next input, and clear when all inputs are 0
reg [3:0] game_over; // 3: Up 2:Down 1:Left 0:Right, Update specific flag when input was pressed and no change in grid,Clear all when grid changed


wire [2:0] next_row;
assign next_row = rows + 1;

wire [2:0] next_col;
assign next_col = cols + 1;

wire [1:0] shift_row;
assign shift_row = down ? (3-rows): rows; 

wire [1:0] shift_col;
assign shift_col = right ? (3-cols): cols; 


wire [1:0] new_val;
assign new_val = rand_val ? 2: 1;

integer i,j;
always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    rows <= 0;
    cols <= 0;     
  end
  else if(s_rst)
  begin
    rows <= 0;
    cols <= 0;
  end
  else
  begin
    if((up || down) && !update_done) // same traversal for up and down
    begin
       if(rows < 3)
          rows <= next_row;
       else
          rows <= 0;

       if(rows == 3)
       begin
          if(cols < 3)
            cols <= next_col;
          else
            cols <= 0;
       end
    end

    else if ((left || right) && !update_done) // same traversal for left and right
    begin
       if(cols < 3)
          cols <= next_col;
       else
          cols <= 0;

       if(cols == 3)
       begin  
          if(rows < 3)
              rows <= next_row;
          else
              rows <= 0;
       end
    end
    else
    begin
      rows <= 0;
      cols <= 0;
    end
  end
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    rand_start <= 0;
    values_calculated <= 0;
    update_done <= 0;
  end
  else if(s_rst)
  begin
    rand_start <= 0;
    values_calculated <= 0;
    update_done <= 0;
  end
  else if(rand_start && !update_done)
  begin
        if(grid[rand_pos[3:2]][rand_pos[1:0]] == 0) // see if can reuse the comparator
        begin
          rand_start <= 0;
          update_done <= 1;
        end
  end
  else if((up || down) && !update_done) // first iteration of the grid is to calculate the updated values
  begin
    if(cols == 3 && rows == 3)
      values_calculated <= 1;

    if(cols == 3 && rows == 3 && values_calculated) // second iteration of the grid is to shift all the updated values to the correct posistions
        rand_start <= 1; // allow accepting the randomized values
  end
  else if((left || right) && !update_done)
  begin
    if(rows == 3 && cols == 3) // first iteration of the grid is to calculate the updated values
      values_calculated <= 1;

    if(rows == 3 && cols == 3 && values_calculated) // second iteration of the grid is to shift all the updated values to the correct posistions
        rand_start <= 1; // allow accepting the randomized values
  end
  else
  begin
    values_calculated <= 0;
    rand_start <= 0;
    update_done <= 0;
  end
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
      game_over <= 0; // sticky flags,game over when no possible inputs change the grid
  else if(s_rst)
      game_over <= 0;
  else if(update_done)
  begin
    if(!is_updated)
    begin
      if(up)
          game_over[3] <= 1; 
      else if(down)
          game_over[2] <= 1; 
      else if(left)
          game_over[1] <= 1; 
      else if(right)
          game_over[0] <= 1; 
    end
    else
      game_over <= 0;
  end
end
assign game_loss = game_over == 4'b1111;

assign A = grid[rows][cols];

//fix gate the rows and cols
always@(*)
begin
  cmp_B = 0;
  if( (up || down) && next_row < 4)
    cmp_B = grid[next_row][cols];
  else if( (left || right) && next_col < 4)
    cmp_B = grid[rows][next_col];
end

always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin
    is_updated <= 0;
    game_win <= 0;
    valid <= 0;
    for(i = 0;i < 4; i = i + 1)
      for(j = 0; j < 4; j = j + 1)
          grid[i][j] <= 0;
  end
  else if(s_rst)
  begin
    is_updated <= 0;
    game_win <= 0;
    valid <= 0;
    for(i = 0;i < 4; i = i + 1)
      for(j = 0; j < 4; j = j + 1)
          if(i[1:0] == rand_pos[3:2] && j[1:0] == rand_pos[1:0])
            grid[i][j] <= rand_pos[7:4];
          else
            grid[i][j] <= 0; 
  end
  else if (!game_win && rand_start && ( grid[rand_pos[3:2]][rand_pos[1:0]] == 0))
            grid[rand_pos[3:2]][rand_pos[1:0]] <= rand_pos[7:4];

  else if( (up || down))
  begin
      if(!values_calculated && !update_done)
      begin
        if( (next_row < 4) && (grid[rows][cols] !=0 ) && !valid[{rows,cols}] && !valid[{next_row[1:0],cols}]) // meaning they havent been updated yet
        begin
          if(Z) // A == B and B they are non zero
          begin
              grid[rows][cols] <= alu_res; // A is grid[rows][cols] and B is 1
              grid[next_row[1:0]][cols] <= 0;
              valid[{rows,cols}] <= 1;
              valid[{next_row[1:0],cols}] <= 1;
              is_updated <= 1;
          end
          else if(grid[next_row[1:0]][cols] == 0)
          begin
                grid[next_row[1:0]][cols] <= grid[rows][cols];
                grid[rows][cols] <= 0;
                is_updated <= 1;
          end
        end
      end
      else if( up && (values_calculated && !rand_start ))
      begin

        if(grid[shift_row][cols] == 4'd11)
            game_win <= 1;

        if(grid[shift_row][cols] == 0)
        begin
           if((shift_row + 1 < 4) && (grid[shift_row + 1][cols] != 0))
           begin
              grid[shift_row][cols] <= grid[shift_row + 1][cols];
              grid[shift_row + 1][cols] <= 0;
           end
           else if((shift_row + 2 < 4) && (grid[shift_row + 2][cols] != 0))
           begin
              grid[shift_row][cols] <= grid[shift_row + 2][cols];
              grid[shift_row + 2][cols] <= 0;
           end
           else if((shift_row + 3 < 4) && (grid[shift_row + 3][cols] != 0))
           begin
              grid[shift_row][cols] <= grid[shift_row + 3][cols];
              grid[shift_row + 3][cols] <= 0;
           end
        end 
      end
      else if(down && (values_calculated && !rand_start ))
      begin

          if(grid[rows][cols] == 4'd11)
              game_win <= 1;

          if(grid[shift_row][cols] == 0)
          begin
             if((shift_row >= 1) && (grid[shift_row - 1][cols] != 0))
             begin
                grid[shift_row][cols] <= grid[shift_row - 1][cols];
                grid[shift_row - 1][cols] <= 0;
             end
             else if((shift_row >= 2) && (grid[shift_row - 2][cols] != 0))
             begin
                grid[shift_row][cols] <= grid[shift_row - 2][cols];
                grid[shift_row - 2][cols] <= 0;
             end
             else if((shift_row >= 3) && (grid[shift_row - 3][cols] != 0))
             begin
                grid[shift_row][cols] <= grid[shift_row - 3][cols];
                grid[shift_row - 3][cols] <= 0;
             end
          end
      end
  end

  else if((left || right))
  begin
      if(!values_calculated && !update_done)
      begin
        if((next_col  < 4) && (grid[rows][cols] != 0 ) && !valid[{rows,cols}] && !valid[{rows,next_col[1:0]}]) // meaning A == B and they havent been updated yet
        begin
          if(Z)
          begin
              grid[rows][cols] <= alu_res; // A is grid[rows][cols] and B is 1
              grid[rows][next_col[1:0]] <= 0;
              valid[{rows,cols}] <= 1;
              valid[{rows,next_col[1:0]}] <= 1;
              is_updated <= 1;
          end
          else if (grid[rows][next_col[1:0]] == 0)
          begin
              grid[rows][next_col[1:0]] <= grid[rows][cols];
              grid[rows][cols] <= 0;
              is_updated <= 1;
          end
        end
      end
      else if( left && (values_calculated && !rand_start && cols < 3))
      begin
        if(grid[rows][cols] == 4'd11)
            game_win <= 1;
        if(grid[rows][shift_col[1:0]] == 0)
        begin
           if((shift_col  + 1 < 4) && (grid[rows][shift_col + 1] != 0))
           begin
              grid[rows][shift_col] <= grid[rows][shift_col + 1];
              grid[rows][shift_col + 1] <= 0;
           end
           else if((shift_col + 2 < 4) && (grid[rows][shift_col + 2] != 0))
           begin
              grid[rows][shift_col] <= grid[rows][shift_col + 2];
              grid[rows][shift_col + 2] <= 0;
           end
           else if((shift_col + 3 < 4) && (grid[rows][shift_col + 3] != 0))
           begin
              grid[rows][shift_col] <= grid[rows][shift_col + 3];
              grid[rows][shift_col + 3] <= 0;
           end
        end 
      end
      else if(right && (values_calculated && !rand_start && cols < 3))
      begin

          if(grid[rows][cols] == 4'd11)
              game_win <= 1;

          if(grid[rows][shift_col] == 0)
          begin
             if((shift_col >= 1) && (grid[rows][shift_col - 1] != 0))
             begin
                grid[rows][shift_col] <= grid[rows][shift_col - 1];
                grid[rows][shift_col - 1] <= 0;
             end
             else if((shift_col >= 2) && (grid[rows][shift_col - 2] != 0))
             begin
                grid[rows][shift_col] <= grid[rows][shift_col - 2];
                grid[rows][shift_col - 2] <= 0;
             end
             else if((shift_col >= 3) && (grid[rows][shift_col - 3] != 0))
             begin
                grid[rows][shift_col] <= grid[rows][shift_col - 3];
                grid[rows][shift_col - 3] <= 0;
             end
          end 
      end
  end
  else
  begin
      valid <= 0;
      is_updated <= 0;
  end
end

genvar r, c;
generate
    for (r = 0; r < 4; r = r + 1) begin : ROW
        for (c = 0; c < 4; c = c + 1) begin : COL
            assign grid_flat[((r*4+c)*4) +: 4] = grid[r][c];
        end
    end
endgenerate

endmodule
