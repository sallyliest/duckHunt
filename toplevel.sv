g
module toplevel( input               CLOCK_50,
                 input        [3:0]  KEY,          //bit 0 is set up as Reset
                 input [35:0] GPIO,
                 output logic [7:0]  VGA_R,        //VGA Red
                                     VGA_G,        //VGA Green
                                     VGA_B,        //VGA Blue
                 output logic        VGA_CLK,      //VGA Clock
                                     VGA_SYNC_N,   //VGA Sync signal
                                     VGA_BLANK_N,  //VGA Blank signal
                                     VGA_VS,       //VGA virtical sync signal
                                     VGA_HS,       //VGA horizontal sync signal
                 output logic [6:0]  HEX0,
                 output logic [6:0]  HEX1,
                 output logic [6:0]  HEX2,
                 output logic [6:0]  HEX3,
                 output logic [6:0]  HEX4,
                 output logic [6:0]  HEX5,
                 output logic [6:0]  HEX6,
                 output logic [6:0]  HEX7
                    );

   logic Reset_h, Clk, Button1_h, Button2_h, Button3_h;
   logic is_duck, is_dog, is_score, is_cursor, is_grass, is_numshot, is_numbirds, is_gameover;
   logic flew_away, bird_shot;
   logic no_shots_left, no_birds_left;
   logic shot, new_round, duck_ded_done, dog_start, dog_duck;
   logic reset_shots, reset_score, reset_birds;
   logic [2:0] state;
	 logic [31:0] num_shots, score, num_birds;
   logic [9:0] DrawX, DrawY;
   logic [15:0] duck_addr;
   logic [13:0] dog_addr;
   logic [11:0] score_addr, numshot_addr, numbirds_addr;
   logic [16:0] grass_addr, gameover_addr;
   logic [8:0] cursor_x, cursor_y;
   logic [9:0] x, y, duck_x, duck_y;

   assign x = cursor_x << 1;
   assign y = {1'b0, cursor_y};

    assign Clk = CLOCK_50;
    always_ff @ (posedge Clk) begin
        Reset_h <= ~(KEY[0]);        // The push buttons are active low
        Button1_h <= ~(KEY[1]);
        Button2_h <= ~(KEY[2]);
        Button3_h <= ~(KEY[3]);
    end

    // Control unit gamecontroller
    control gamecontroller(.Clk(Clk), .Reset(Reset_h), .start(Button1_h),
    .no_shots_left(no_shots_left), .flew_away(flew_away), .game_over(no_birds_left),
    .bird_shot(bird_shot), .duck_ded_done(duck_ded_done), .dog_start(dog_start), .dog_duck(dog_duck),
    .new_round(new_round), .reset_shots(reset_shots), .reset_score(reset_score), .reset_birds(reset_birds),
    .state(state));

    shotKeeper shotshandler(.Clk(Clk), .Reset(reset_shots), .shot(shot), .state(state),
    .no_shots_left(no_shots_left), .num_shots(num_shots));

    scoreKeeper scorehandler(.Clk(Clk), .Reset(reset_score), .bird_shot(bird_shot),
    .state(state), .score(score));

    birdKeeper birdhandler(.Clk(Clk), .Reset(reset_birds), .flew_away(flew_away),
    .state(state), .no_birds_left(no_birds_left), .num_birds(num_birds));

    duck duck_instance(.Clk(Clk), .Reset(Reset_h), .new_round(new_round), .frame_clk(VGA_VS),
	  .state(state), .DrawX(DrawX), .DrawY(DrawY), .is_duck(is_duck), .duck_ded_done(duck_ded_done),
    .flew_away(flew_away), .duck_x(duck_x), .duck_y(duck_y), .duck_addr(duck_addr));

    dog dog_instance(.Clk(Clk), .Reset(Reset_h), .frame_clk(VGA_VS), .dog_start(dog_start), .dog_duck(dog_duck),
    .DrawX(DrawX), .DrawY(DrawY), .is_dog(is_dog), .dog_addr(dog_addr), .state(state));

    number_display score_instance(.*, .Clk(Clk), .Reset(Reset_h), .frame_clk(VGA_VS), .state(state), .DrawX(DrawX),
     .DrawY(DrawY), .Num_X_Pos(10'd480), .Num_Y_Pos(10'd417), .value(score), .is_num(is_score), .num_addr(score_addr));

    number_display numshots_instance(.*, .Clk(Clk), .Reset(Reset_h), .frame_clk(VGA_VS), .state(state), .DrawX(DrawX),
    .DrawY(DrawY), .Num_X_Pos(10'd262), .Num_Y_Pos(10'd417), .value(num_shots), .is_num(is_numshot), .num_addr(numshot_addr));

    number_display birdsgone_instance(.*, .Clk(Clk), .Reset(Reset_h), .frame_clk(VGA_VS), .state(state), .DrawX(DrawX),
    .DrawY(DrawY), .Num_X_Pos(10'd44), .Num_Y_Pos(10'd417), .value(num_birds), .is_num(is_numbirds), .num_addr(numbirds_addr));

    cursor cursor_instance(.Clk(Clk), .Reset(Reset_h), .frame_clk(VGA_VS), .shot(shot), .no_shots_left(no_shots_left), .state(state),
    .DrawX(DrawX), .DrawY(DrawY), .x(x), .y(y), .duck_x(duck_x), .duck_y(duck_y), .bird_shot(bird_shot), .is_cursor(is_cursor));

    grass grass_instance(.Clk(Clk), .Reset(Reset_h), .frame_clk(VGA_VS),
    .DrawX(DrawX), .DrawY(DrawY), .is_grass(is_grass), .grass_addr(grass_addr));

    gameover gameover_instance(.Clk(Clk), .Reset(Reset_h), .frame_clk(VGA_VS),
    .DrawX(DrawX), .DrawY(DrawY), .is_gameover(is_gameover), .gameover_addr(gameover_addr));

    getCoordinates coords(.Clk(Clk), .GPIO(GPIO), .shot(shot), .cursor_y(cursor_y), .cursor_x(cursor_x));

    // Use PLL to generate the 25MHZ VGA_CLK.
    vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));

    VGA_controller vga_controller_instance(.Clk(Clk), .Reset(Reset_h), .VGA_HS(VGA_HS),
		 .VGA_VS(VGA_VS), .VGA_CLK(VGA_CLK), .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N),
		 .DrawX(DrawX), .DrawY(DrawY));

    color_mapper color_instance(.Clk(Clk), .is_duck(is_duck), .is_dog(is_dog),
    .is_score(is_score), .is_cursor(is_cursor), .is_grass(is_grass), .is_numshot(is_numshot),
    .is_numbirds(is_numbirds), .is_gameover(is_gameover), .shot(shot), .DrawX(DrawX), .DrawY(DrawY),
    .duck_addr(duck_addr), .dog_addr(dog_addr), .score_addr(score_addr), .grass_addr(grass_addr),
    .numbirds_addr(numbirds_addr), .numshot_addr(numshot_addr), .gameover_addr(gameover_addr),
    .state(state), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B));


    hexdriver hexdrv0 (
    .In(cursor_x[3:0]),
    .Out(HEX0)
  );

  hexdriver hexdrv1 (
    .In(cursor_x[7:4]),
    .Out(HEX1)
  );

  hexdriver hexdrv2 (
    .In({3'b000, cursor_x[8]}),
    .Out(HEX2)
  );

  hexdriver hexdrv3 (
  .In(cursor_y[3:0]),
  .Out(HEX3)
);

hexdriver hexdrv4 (
  .In(cursor_y[7:4]),
  .Out(HEX4)
);

hexdriver hexdrv5 (
  .In({3'b000, cursor_y[8]}),
  .Out(HEX5)
);
  hexdriver hexdrv6 (
    .In({3'b000, flew_away}),
    .Out(HEX6)
  );

  hexdriver hexdrv7 (
    .In({1'b0, state}),
    .Out(HEX7)
  );
endmodule
