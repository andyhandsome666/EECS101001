`timescale 1ns/1ps
`define DELAY 10
`define NUM_OF_PAT 248

module tb;
    reg [7:0] A;
    reg [7:0] B;
    reg [2:0] instruction;
    wire [7:0] F;

    // Module instantiation
    Functional_Unit fu(
        .instruction(instruction), 
        .A(A),
        .B(B),
        .F(F)
    );

    // load patterns
    reg [7:0] patterns [0:1023];
    reg [7:0] golden [0:511];
    reg [7:0] stu_ans [0:511];
    reg [2:0] instruct [0:511];
    
    initial begin
        $readmemh("./data/pattern", patterns);
        $readmemh("./data/golden1", golden);
        $readmemb("./data/instruction", instruct);
    end
    
    initial begin
        A = 8'dx;
        B = 8'dx;
        instruction = 3'dx;
    end
    integer i;
    initial begin
        for(i = 0; i < `NUM_OF_PAT/2; i = i + 1) begin
            #(`DELAY);
            A = patterns[i<<1];
            B = patterns[(i<<1)+1];
            instruction = instruct[i];
        end
    end
    integer j, error;
    initial begin
        error = 0;
        #(`DELAY/2);
        for(j = 0; j < `NUM_OF_PAT/2; j = j + 1) begin
            #(`DELAY);
            if(golden[j]!=F) begin
                error = error + 1;
                $display("\n-------------------------------------------------------");
                $display("[ERROR]");
                $display("A = 8'b%b (8'h%h)", A, A);
                $display("B = 8'b%b (8'h%h)", B, B);
                $display("instruction = 3'b%b\n", instruct[j]);
                $display("Your answer = 8'b%b (8'h%h), but the golden = 8'b%b (8'h%h)", F, F, golden[j], golden[j]);
                $display("-------------------------------------------------------\n");
            end
        end
        if(error==0) begin
            $display("\n[success] You can start doing problem 2.\n");
        end else begin
            $display("\n[FAIL] There are %3d errors.\n", error);
        end
        $finish;
    end
endmodule