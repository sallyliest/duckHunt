module  cursor(input         Clk,                // 50 MHz clock
                             Reset,              // Active-high reset signal
                             frame_clk,          // The clock indicating a new frame (~60Hz)
                             shot, no_shots_left,
               input [2:0]   state,
               input [9:0]   DrawX, DrawY,       // Current pixel coordinates
               input [9:0]   x, y, duck_x, duck_y,
               output logic  bird_shot,
               output logic  is_cursor           // Whether current pixel belongs to cursor or background
              );

    parameter [9:0] Cursor_X_Center = 10'd320;  // Center position on the X axis
    parameter [9:0] Cursor_Y_Center = 10'd240;  // Center position on the Y axis
    parameter [9:0] Cursor_X_Min = 10'd0;       // Leftmost point on the X axis
    parameter [9:0] Cursor_X_Max = 10'd639;     // Rightmost point on the X axis
    parameter [9:0] Cursor_Y_Min = 10'd0;       // Topmost point on the Y axis
    parameter [9:0] Cursor_Y_Max = 10'd479;     // Bottommost point on the Y axis
    parameter [9:0] Cursor_Size = 10'd6;        // Cursor size

    logic [9:0] Cursor_X_Pos, Cursor_X_Motion, Cursor_Y_Pos, Cursor_Y_Motion;
    logic [9:0] Cursor_X_Pos_in, Cursor_X_Motion_in, Cursor_Y_Pos_in, Cursor_Y_Motion_in;

//    Detect rising edge of the shot to make sure that the player cannot press and hold the trigger to shoot the ducks
    logic shot_edge, shot_sync_f;
    always @(posedge Clk) begin
        if (Reset) begin
            shot_sync_f <= 1'b0;
        end else begin
            shot_sync_f <= shot;
        end
    end

    assign shot_edge = shot & ~shot_sync_f; // Detects rising edge

    // Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end
    // Update registers
    always_ff @ (posedge Clk)
    begin
        if (Reset)
        begin
            Cursor_X_Pos <= Cursor_X_Center;
            Cursor_Y_Pos <= Cursor_Y_Center;
            Cursor_X_Motion <= 10'd0;
            Cursor_Y_Motion <= 10'd0;
        end
        else
        begin
            Cursor_X_Pos <= Cursor_X_Pos_in;
            Cursor_Y_Pos <= Cursor_Y_Pos_in;
            Cursor_X_Motion <= Cursor_X_Motion_in;
            Cursor_Y_Motion <= Cursor_Y_Motion_in;
        end
    end
      int DuckX, DuckY, CursorX, CursorY, RangeX, RangeY;
      always_comb begin
        DuckX = duck_x + 10'd32;
        DuckY = duck_y + 10'd32;
        CursorX = Cursor_X_Pos;
        CursorY = Cursor_Y_Pos;
        RangeX = DuckX - CursorX;
        RangeY = DuckY - CursorY;
      end

    always_comb
    begin
        // By default, keep motion and position unchanged
        Cursor_X_Pos_in = Cursor_X_Pos;
        Cursor_Y_Pos_in = Cursor_Y_Pos;
        bird_shot = 1'b0;
        Cursor_Y_Pos_in = y;
        Cursor_X_Pos_in = x;
        // Update position and motion only at rising edge of frame clock
        if (frame_clk_rising_edge )
        begin
          if(shot && state == 3'b010) begin
            if( ( (RangeX <= 32) && (RangeX >= -32) ) && ( (RangeY <= 32) && (RangeY >= -32) ) )begin
              bird_shot = 1'b1;
            end
          end
        end
    end

    int DistX, DistY, Size;
    assign DistX = DrawX - Cursor_X_Pos;
    assign DistY = DrawY - Cursor_Y_Pos;
    assign Size = Cursor_Size;
    always_comb begin
        if ( ( DistX*DistX + DistY*DistY) <= (Size*Size) )
            is_cursor = 1'b1;
        else
            is_cursor = 1'b0;
    end

endmodule
