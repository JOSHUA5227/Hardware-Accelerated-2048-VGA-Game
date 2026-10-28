module update(
        input wire clk,
        input wire rst_n, // ACTIVE low Hard Reset
        input wire s_rst, // ACTIVE high soft game reset needed to start a game
        input wire R,D,U,L,
        // output reg valid[0:15], //valid array for random
        // random is fully pushed to user output reg rand_start, //start enable signal for LFSR once all updates and shifting is done is active high
        input wire [3:0] rand_pos,// random posistion from LFSR
        input wire tworfr,//its two or 4 0 is 2 4 is 1
        
        input wire [1:0] vga_row,vga_col,
        output wire [3:0] grid_value,
        output reg gamewon,
        output wire game_over_vga
);
reg [3:0] grid[0:3][0:3]; // main playing grid

assign grid_value=grid[vga_row][vga_col];

localparam [2:0] LATCH_ST = 0,//default state
           FINDZ = 1,//0 in notes
           FINDCOMPANION =2,//1 in notes
           UPDATENOW = 3,//2 in notes
           UPDATETRAV = 4,//3 in notes
           GATECHECK = 5,//4 in notes
           RANDINS = 6,//5 in notes
           WAITFORDOWN = 7;//6 in notes
localparam [1:0] F1_ROW= 2'b11;//will be 30 so F2 is inverted of it 
localparam [1:0] F1_COL= 2'b00;//will be 30 so F2 is inverted of it 

localparam [3:0] ENDMOVE = 4'd11;//2048

wire [1:0] F2_ROW,F2_COL;
assign F2_ROW=F1_COL;
assign F2_COL=F1_ROW;

//frist version ==> not going with por start random logic
// Ports to Adder/Comparator
reg [3:0] A_comp1,A_comp2,A_add,B_comp1,B_comp2,B_add;
wire [3:0] res; // Addition result
wire comp1_out,comp2_out;
reg AorS;//1 is add and 0 is sub
EQ e1(
        .A(A_comp1),
        .B(B_comp1),
        .OP(comp1_out)
);

EQ e2(
        .A(A_comp2),
        .B(B_comp2),
        .OP(comp2_out)
);

Adder A1(
        .A(A_add),
        .B(B_add),///seems always one so gonna remove it
        .AorS(AorS),
        .OP(res)
);

//registers grid state next_ptr trav_ptr first_time?  and thier update 
reg [2:0] state;
reg [2:0] stater;

//GAME UPDATE LOGIC
reg [1:0] now_rows,now_cols;// grid travesal 
reg [1:0] now_rowr,now_colsr;

reg [1:0] trav_rows,trav_cols;// grid travesal 
reg [1:0] trav_rowsr,trav_colsr;

//if above is 0 and state is not 
reg [3:0] game_over; // 3: D 2:U 1:R 0:L, Update specific flag when input was pressed and no change in grid,Clear all when grid changed
reg [3:0] game_overr;

reg gamewonr;//bit for game won will fill every grid with 11 one by one
assign game_over_vga=&game_over;
///grid the update to it is via update  signal 
reg update_to_grid;// Set to 1 Whenever there is any change in the grid combo used to clear all the game_over and update the 
reg [3:0] value_to_update; ///value to update to the grid when update is given
reg place_to_update;//0 is now 1 is trav
integer reset_i,reset_j;//reset integers
reg srst_latched,cleared_bit;//cleared_bit and srst=1 will clear everything and 
//cleared_bit and srst=1 and srst_latched=0 will set a random point in grid as 2.

wire [1:0] shiftedtwo;//this is made intentionally
assign shiftedtwo=2'b01<<tworfr;
reg plusone,colorrow;//if plusone is 1 it is +1 else -1 and colorrow is 1 it is row else col to be updated
wire [3:0] grid_now,grid_trav;
assign grid_now=grid[now_rows][now_cols];
assign grid_trav=grid[trav_rows][trav_cols];
//assign grid_rand=grid[rand_pos[3:2]][rand_pos[1:0]];
wire anybodyon;
assign anybodyon=plusone||R||colorrow;
always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
  begin//right now it wont do insert
        state<=LATCH_ST;
        now_rows<=2'd0;
        now_cols<=2'd0;
        trav_rows<=2'd0;
        trav_cols<=2'd0;
        game_over<=4'd0;
        gamewon<=1'b0;
        cleared_bit<=1'b0;//nees srst to start
        srst_latched<=1'b0;
        for(reset_i=0;reset_i<4;reset_i=reset_i+1)begin
                for(reset_j=0;reset_j<4;reset_j=reset_j+1)begin
                        grid[reset_i][reset_j]<=4'd0;
                end
        end
  end
  else if(s_rst)//more than 2 cycles
        begin
        state<=LATCH_ST;
        now_rows<=2'd0;
        now_cols<=2'd0;
        trav_rows<=2'd0;
        trav_cols<=2'd0;
        game_over<=4'd0;
        gamewon<=1'b0;//not won stage
        if(~cleared_bit)//clearing state
        begin
                for(reset_i=0;reset_i<4;reset_i=reset_i+1)begin
                        for(reset_j=0;reset_j<4;reset_j=reset_j+1)begin
                                grid[reset_i][reset_j]<=4'd0;
                        end
                end
                cleared_bit<=1'b1;
                srst_latched<=1'b0;//on next cycle it will insert a random
        end
        else if(cleared_bit && ~srst_latched)begin
                grid[rand_pos[3:2]][rand_pos[1:0]]<={2'b0,shiftedtwo};//has to be changed all random insertion has to be chagned
                srst_latched<=1'b1;
        end
        end
  else begin//normal excution
        cleared_bit<=1'b0;
        srst_latched<=1'b0;//returning to normal
//other assignments pending
        game_over<=game_overr;
        gamewon<=gamewonr;
        state<=stater;
        now_cols<=now_colsr;
        now_rows<=now_rowr;
        trav_cols<=trav_colsr;
        trav_rows<=trav_rowsr;
        if(update_to_grid)begin
                if(place_to_update)//1 is trav
                grid[trav_rows][trav_cols]<=value_to_update;
                else //0 is now
                grid[now_rows][now_cols]<=value_to_update;
        end
end
end

always@(*) begin//updater logic
        gamewonr=gamewon;
        update_to_grid=1'b0;
        value_to_update=4'b0;
        place_to_update=1'b0;//deault now
        game_overr=game_over;
        plusone=L||U;//if L or U +1
        colorrow=U||D;//if U or D select row for updating
        //defaults for comp and add
        AorS=1'b0;
        A_add=4'b0;
        B_add=4'b0;
        A_comp1=4'b0;
        A_comp2=4'b0;
        B_comp1=4'b0;
        B_comp2=4'b0;
        case(state)
        LATCH_ST:begin///idle + latcher
                A_comp1=game_overr;
                B_comp1=4'HF;
                //move if comparison is ffailure gameover is not all 1 and gamewon is not 1 and 
                if(anybodyon&&(~comp1_out)&&(~gamewon))begin//move logic
                        stater=FINDZ;
                        game_overr=game_over|{D,U,R,L};
                end
                else begin//dont move
                        stater=LATCH_ST;
                        game_overr=game_over;
                end
                now_rowr=plusone^colorrow?F1_ROW:F2_ROW;
                now_colsr=plusone^colorrow?F1_COL:F2_COL;
                trav_colsr=now_colsr;
                trav_rowsr=now_rowr;
        end
        FINDZ:begin
                //for grid[trav]==0
                A_comp1=grid_trav;
                B_comp1=4'd0;
                //trav==end
                A_comp2=colorrow?{2'b0,trav_rows}:{2'b0,trav_cols};
                B_comp2=plusone?F1_ROW:F1_COL;//if L or U its 3 else 0
                case({comp1_out,comp2_out})
                2'b00:begin//no movement here gatecheck takes care
                        stater=GATECHECK;
                        trav_colsr=trav_cols;
                        trav_rowsr=trav_rows;
                        now_colsr=now_cols;
                        now_rowr=now_rows;
                        //overwrites to same place no worries cos the gameover logic doesnt go off until checked in gatecheck
                        update_to_grid=1'b1;
                        value_to_update=grid_trav;
                        place_to_update=1'b0;
                end
                2'b11:begin//its zeroees everywhere
                        stater=UPDATETRAV;
                        trav_colsr=trav_cols;
                        trav_rowsr=trav_rows;
                        now_colsr=now_cols;
                        now_rowr=now_rows;
                end
                2'b01:begin//found it but at end too
                        stater=GATECHECK;
                        trav_colsr=trav_cols;
                        trav_rowsr=trav_rows;
                        now_colsr=now_cols;
                        now_rowr=now_rows;
                        //overwrites to same place no worries cos the gameover logic doesnt go off until checked in gatecheck
                        update_to_grid=1'b1;
                        value_to_update=grid_trav;
                        place_to_update=1'b0;
                end
                2'b10:begin//not found it(zero) and not at end
                        stater=FINDZ;
                        A_add=colorrow?{2'b0,trav_rows}:{2'b0,trav_cols};
                        B_add=4'b0001;
                        AorS=plusone;
                        trav_colsr=colorrow?trav_cols:res[1:0];
                        trav_rowsr=colorrow?res[1:0]:trav_rows;
                        now_colsr=now_cols;
                        now_rowr=now_rows;
                end
                default:begin
                        stater=FINDZ;
                        trav_colsr=trav_cols;
                        trav_rowsr=trav_rows;
                        now_colsr=now_cols;
                        now_rowr=now_rows;
                end
                endcase
        end
        FINDCOMPANION:begin
                //for grid[trav]==0
                A_comp1=grid_trav;
                B_comp1=4'd0;
                //trav==now place values
                A_comp2=grid_trav;
                B_comp2=grid_now;
                case({comp1_out,comp2_out})
                2'b11:begin//same value and its zero so fill out that zero
                        stater=FINDZ;
                        trav_colsr=trav_cols;
                        trav_rowsr=trav_rows;
                        now_colsr=now_cols;
                        now_rowr=now_rows;
                end
                2'b10:begin//its zero at trav not at now
                        stater=UPDATETRAV;
                        trav_colsr=trav_cols;
                        trav_rowsr=trav_rows;
                        now_colsr=now_cols;
                        now_rowr=now_rows;
                end
                2'b01:begin//companion found
                        stater=UPDATENOW;
                        A_add=grid_now;
                        B_add=4'b0001;
                        AorS=1;//its always +1 for grid additions
                        update_to_grid=1'b1;
                        place_to_update=1'b0;//now
                        //game_overr=0;//update to all zero this is correct im doing this cos instead of this i can mux the update_to_grid in seq block
                        value_to_update=res;
                        trav_colsr=trav_cols;
                        trav_rowsr=trav_rows;
                        now_colsr=now_cols;
                        now_rowr=now_rows;
                end
                2'b00:begin//end this iter cos non empty found but not equal retraverse on trav part to make that non zero be placed correctly
                        stater=FINDZ;
                        A_add=colorrow?{2'b0,now_rows}:{2'b0,now_cols};
                        B_add=4'b0001;
                        AorS=plusone;
                        trav_colsr=colorrow?now_cols:res[1:0];
                        trav_rowsr=colorrow?res[1:0]:now_rows;
                        now_colsr=colorrow?now_cols:res[1:0];
                        now_rowr=colorrow?res[1:0]:now_rows;
                end
                default:begin//glitch
                        stater=FINDCOMPANION;
                        trav_colsr=trav_cols;
                        trav_rowsr=trav_rows;
                        now_colsr=now_cols;
                        now_rowr=now_rows;
                end
                endcase
        end
        UPDATENOW:begin//its entry is always companion found
                stater=FINDZ;
                //is it 11 check
                A_comp1=grid_now;
                B_comp1=ENDMOVE;
                gamewonr=comp1_out;//if yes lets go;

                A_add=colorrow?{2'b0,now_rows}:{2'b0,now_cols};
                B_add=4'b0001;
                AorS=plusone;
                //at trav will be cleared here
                game_overr=4'd0;//now cleared
                update_to_grid=1'b1;//its entry 
                place_to_update=1'b1;//trav
                value_to_update=4'd0;//clear it
                now_colsr=comp1_out?F1_COL:(colorrow?now_cols:res[1:0]);
                now_rowr=comp1_out?F1_ROW:(colorrow?res[1:0]:now_rows);
                trav_colsr=now_colsr;
                trav_rowsr=now_rowr;
        end
        UPDATETRAV:begin
                //trav==end
                A_comp1=colorrow?{2'b0,trav_rows}:{2'b0,trav_cols};
                B_comp1=plusone?F1_ROW:F1_COL;
                //trav==dest
                A_comp2={trav_rows,trav_cols};
                B_comp2=(plusone^colorrow)?{F2_ROW,F2_COL}:{F1_ROW,F1_COL};//if L or D or not

                if(comp2_out)begin//B is true in notes
                        stater=RANDINS;
                        trav_colsr=rand_pos[1:0];
                        now_colsr=now_cols;
                        trav_rowsr=rand_pos[3:2];//updating rand to trav so no new mux
                        now_rowr=now_rows;
                end
                else begin//using trav cos its the usually checked ptr
                        if(comp1_out)begin//T F in notes genupdatet
                                A_add=colorrow?{2'b0,trav_cols}:{2'b0,trav_rows};//as this is the genupdate it has to be oppposite
                                B_add=4'b0001;
                                AorS=~plusone;//?1'b0:1'b1;//this time L or U means -1 and R D means +1
                                now_colsr=colorrow?res[1:0]:(plusone?F1_COL:F2_COL);
                                now_rowr=colorrow?(plusone?F2_ROW:F1_ROW):res[1:0];
                                trav_colsr=now_colsr;
                                trav_rowsr=now_rowr;
                                stater=FINDZ;
                        end
                        else begin//+1  //its not even at end or at dest so moving trav is better choice as from state 1 expects moving trav +1 and state 0 cant give a entry here
                                stater=FINDCOMPANION;//state 1
                                A_add=colorrow?{2'b0,trav_rows}:{2'b0,trav_cols};
                                B_add=4'b0001;
                                AorS=plusone;
                                trav_colsr=colorrow?trav_cols:res[1:0];
                                trav_rowsr=colorrow?res[1:0]:trav_rows;
                                //remain same
                                now_colsr=now_cols;
                                now_rowr=now_rows;
                        end
                end


        end
        GATECHECK:begin//entry from state 0 only to check if the addr is diff and can be cleared
                //trav==end  ==> T state is 3 or state 1(and do +1 to trav)
                A_comp1=colorrow?{2'b0,trav_rows}:{2'b0,trav_cols};
                B_comp1=plusone?F1_ROW:F1_COL;
                //trav==now  ==> T dont clear else clear 
                A_comp2={trav_rows,trav_cols};
                B_comp2={now_rows,now_cols};
                //+1 for state 4 +1 to give it to FINDCOMPANION
                A_add=colorrow?{2'b0,trav_rows}:{2'b0,trav_cols};
                B_add=4'b0001;
                AorS=plusone;
                stater=comp1_out?UPDATETRAV:FINDCOMPANION;//FINDCOMPANION needs that now!=trav ever
                update_to_grid=~comp2_out;
                game_overr=comp2_out?game_over:4'd0;
                value_to_update=4'b0000;
                place_to_update=1'b1;//trav
                trav_colsr=comp1_out?trav_cols:(colorrow?trav_cols:res[1:0]);//if colorrow then update row else update col
                trav_rowsr=comp1_out?trav_rows:(colorrow?res[1:0]:trav_rows);
                now_colsr=now_cols;
                now_rowr=now_rows;
        end
        RANDINS:begin//shouldnt do insert whn game over or won
                //check if ever cleared ==> something moveed==> random can be done
                A_comp1=game_over;
                B_comp1=4'd0;

                //if current random can be used? whihc is the place is free
                A_comp2=grid_trav;
                B_comp2=4'b0000;
                
                if(comp1_out && (~game_over))begin//can insert when gameown and gameover is cleared
                        if(comp2_out)begin//free
                                place_to_update=1'b1;//trav
                                value_to_update={2'b0,shiftedtwo};//insert a 2
                                update_to_grid=1'b1;
                                //game_overr= alreaady would be 0
                                stater=WAITFORDOWN;
                                trav_colsr=trav_cols;
                                trav_rowsr=trav_rows;
                                //retain ubt useless now
                                now_rowr=now_rows;
                                now_colsr=now_cols;
                        end
                        else begin//now free find new
                                stater=RANDINS;
                                trav_colsr=rand_pos[1:0];
                                trav_rowsr=rand_pos[3:2];
                                now_colsr=now_cols;
                                now_rowr=now_rows;
                        end

                end
                else begin//cant insert cos no movement was done
                        stater=WAITFORDOWN;
                        trav_colsr=trav_cols;
                        trav_rowsr=trav_rows;
                        now_colsr=now_cols;
                        now_rowr=now_rows;                        
                end
        end
        WAITFORDOWN:begin
                now_colsr=F1_COL;
                now_rowr=F1_ROW;
                trav_colsr=F1_COL;
                trav_rowsr=F1_ROW;
                if(anybodyon)begin
                        stater=WAITFORDOWN;
                end
                else begin
                        stater=LATCH_ST;
                end
        end
        default:begin
                stater=LATCH_ST;
                now_colsr=F1_COL;
                now_rowr=F1_ROW;
                trav_colsr=F1_COL;
                trav_rowsr=F1_ROW;
        end        
        endcase

        end

endmodule

module Adder(
    input [3:0]A,
    input [3:0]B,
    input AorS,//1 is add 0 is substract
    output reg [3:0] OP
);

always@(*) begin
    if(AorS)begin
        OP=(A+B);
    end
    else begin
        OP=(A-B);
    end
end

endmodule

module EQ(
        input wire [3:0] A,
        input wire [3:0] B,
        output wire OP
);

assign OP=(A==B);

endmodule
