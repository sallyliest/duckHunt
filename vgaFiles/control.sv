/************************************************************************
Core Game control logic
Tulika Gupta and Shayna Kapadia, Spring 2019
Duck Hunt
************************************************************************/

module control (
    input  logic Clk,
    input  logic Reset,
    input  logic start,
    input  logic no_shots_left,
    input  logic flew_away,
    input  logic game_over,
    input  logic bird_shot,
    output  logic new_duck,
    output logic reset_shots,
    output logic reset_score,
    output logic reset_birds,
    output logic [1:0] state
);
enum logic [3:0] { Start, P1, P2, P2_1, P2_2, P2_3, P3, Done } State, Next_State;

always_ff @ (posedge Clk)
  begin
    if(Reset)
      State <= Start;
    else
      State <= Next_State;
  end

always_comb
begin
    // Default: Next state is the same as the current state
    Next_State = State;

    //Default values for outputs
    state = 2'b00;
    new_duck = 1'b0;
    reset_shots = 1'b0;
    reset_score = 1'b0;
    reset_birds = 1'b0;
    //The state definitions begin here
    unique case(State)
      Start:
        begin
          if(start)
            Next_State = P1;
          else
            Next_State = Start;
        end
      P1: Next_State = P2;
      P2:
        begin
          if(no_shots_left)
            Next_State = P2_1;
          else if(flew_away)
            Next_State = P3;
          else if(bird_shot)
            Next_State = P3;
          else
            Next_State = P2;
        end
      P2_1:
      begin
        if(flew_away)
          Next_State = P3;
        else
          Next_State = P2_1;
      end
      P3:
      begin
        if(game_over)
          Next_State = Done;
        else
          Next_State = P1;
      end
      Done:
        begin
          if(start)
            Next_State = Start;
          else
            Next_State = Done;
        end
      default:
        Next_State = Start;
    endcase
    //Now, we assign outputs and set variables for these states

    case(State)
      Start:
        begin
          state = 2'b00;
          reset_shots = 1'b1;
          reset_score = 1'b1;
          reset_birds = 1'b1;
        end
      P1:
        begin
          state = 2'b01;
          new_duck = 1'b1;
        end
      P2:
        begin
          state = 2'b10;
        end
      P2_1:
        begin
          state = 2'b10;
        end
      P3:
        begin
          state = 2'b10;
          reset_shots = 1'b1;
        end
      Done:
        begin
          state = 2'b11;
          reset_score = 1'b1;
          reset_birds = 1'b1;
        end
      default:
        begin
          state = 2'b00;
        end
    endcase

end
endmodule