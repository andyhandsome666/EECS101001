`timescale 1ns/1ps
module find_MAX(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire valid,
    input wire [7:0] Data_A,
    input wire [7:0] Data_B,
    input wire one_left,
    input wire [2:0] instruction,
    output reg [7:0] maximum,
    output reg finish
);
    wire [7:0] result;

    // Functional_Unit instantiation
    Functional_Unit fu(
        .instruction(instruction), 
        .A(Data_A),
        .B(Data_B),
        .F(result)
    );

    //TODO: write your design below
    //You cannot modify anything above
    
    wire finish_temp;
    wire [7:0] o_maximum;
    wire [7:0] max_temp;
    wire o_finish;
    wire [1:0] state;

    //Decide max
    decide_max dcdmx(
        .state(state),
        .valid(valid),
        .result(result),
        .maximum(max_temp),
        .o_maximum(o_maximum)
    );

    //Finite state machine
    FSM fsm(
        .valid(valid),
        .start(start),
        .one_left(one_left),
        .clk(clk),
        .rst_n(rst_n),
        .state(state),
        .o_finish(o_finish)
    );

    //Output Flip-Flop
    Output_FFs ff(
        .o_maximum(o_maximum),
        .o_finish(o_finish),
        .clk(clk),
        .rst_n(rst_n),
        .maximum(max_temp),
        .finish(finish_temp)
    );

    always @(*) begin
        maximum = max_temp;
        finish = finish_temp;
    end

endmodule

module Functional_Unit(instruction, A, B, F);
    input wire [2:0] instruction;
    input wire [7:0] A;
    input wire [7:0] B;
    output [7:0] F;
    reg [7:0]F;
    always @(instruction or A or B) begin
        case (instruction)
        3'b000: F = A + B;
        3'b001: F = A +~B;
        3'b010: F = A & B;
        3'b011: F = A | B;
        3'b100: F = A ^ B;
        3'b101: F = (A >> 1) + B;
        3'b110: F = ({A[0], A[7:1]}) + B;
        3'b111: F = ({A[6:0], A[7]}) + B;
        endcase
    end
endmodule

module FSM(
    input wire valid,
    input wire start,
    input wire one_left,
    input wire clk,
    input wire rst_n,
    output reg o_finish,
    output reg [1:0] state
);
parameter STATE_0 = 2'b00;
parameter STATE_1 = 2'b01;
parameter STATE_2 = 2'b10;
reg [1:0] next_state;

always @(posedge clk) begin
    if (~rst_n) 
        state <= STATE_0;
    else 
        state <= next_state;
end

always @(*) begin
    o_finish = 1'b0;
    next_state = STATE_0;
    case(state)
        STATE_0: begin
            if (start == 1) 
                next_state = STATE_1;
            else 
                next_state = STATE_0;
        end

        STATE_1: begin
            if (one_left == 1)
                next_state = STATE_2;
            else 
                next_state = STATE_1;
        end

        STATE_2: begin
            if (valid == 1) begin
                next_state = STATE_0;
                o_finish = 1'b1;
            end
            else 
                next_state = STATE_2;
        end
        default : next_state = STATE_0;     
    endcase
end

endmodule

module decide_max(
    input [1:0] state,
    input [7:0] maximum,
    input valid,
    input [7:0] result,
    output reg [7:0] o_maximum
);
parameter STATE_0 = 2'b00;
parameter STATE_1 = 2'b01;
parameter STATE_2 = 2'b10;

always @(*) begin
    if (valid) begin
        if (state == STATE_1 || state == STATE_2) begin
            if (result > maximum) o_maximum = result;
            else o_maximum = maximum;
        end
        else o_maximum = 8'b0;
    end
    if (state == STATE_0) o_maximum = 8'b0;
end

endmodule

module Output_FFs(
    input wire [7:0] o_maximum,
    input wire o_finish,
    input wire clk,
    input wire rst_n,
    output reg [7:0] maximum,
    output reg finish
);

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        finish <= 1'b0;
        maximum <= 8'b0;
    end
    else begin
        finish <= o_finish;
        maximum <= o_maximum;
    end
end
endmodule