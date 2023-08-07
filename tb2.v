`timescale 1ns/1ps
`define CYCLE 10
`define END_CYCLES 50000
`define SEQ_LEN 4
`define ANS_LEN 31
module tb;
    reg clk;
    reg rst_n;
    reg start;
    reg valid;
    reg [7:0] Data_A;
    reg [7:0] Data_B;
    reg one_left;
    reg [2:0] instruction;
    wire [7:0] maximum;
    wire finish;

    // Module instantiation
    find_MAX fm(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .valid(valid),
        .Data_A(Data_A),
        .Data_B(Data_B),
        .one_left(one_left),
        .instruction(instruction),
        .maximum(maximum),
        .finish(finish)
    );

    // genearte clk
    always #(`CYCLE/2) clk = ~clk;

    // load patterns
    reg [7:0] patterns [0:1023];
    reg [7:0] golden [0:511];
    reg [7:0] stu_ans [0:511];
    reg [2:0] instruct [0:511];
    reg [7:0] period [0:511];
    
    initial begin
        $readmemh("./data/pattern", patterns);
        $readmemh("./data/golden2", golden);
        $readmemb("./data/instruction", instruct);
        $readmemh("./data/period", period);
    end
    
    initial begin
        clk = 0;
        rst_n = 1;
        start = 0;
        valid = 0;
        one_left = 0;
        Data_A = 8'dx;
        Data_B = 8'dx;
        instruction = 3'dx;
    end

    reg [9:0] addr;
    integer pair;
    initial begin
        addr = 0;
        pair = 1;
    end
    always@(posedge clk) begin
        if(start) begin
            pair <= 1;
        end
        else if(valid) begin
            addr <= addr + 1;
            pair <= pair + 1;
        end
    end

    task send_Vaild_Numbers(
        output [7:0] data_a, data_b,
        output _valid,
        output [2:0] instr,
        input [9:0] address,
        input [31:0] _pair
    );
        begin
            #(`CYCLE*period[address]);
            $display("\t\t------ Pair-%2d of integers------", _pair);
            _valid = 1;
            data_a = patterns[address<<1];
            $display("\t\tData_A = 8'b%b (8'h%h)", data_a, data_a);
            data_b = patterns[(address<<1)+1];
            $display("\t\tData_B = 8'b%b (8'h%h)", data_b, data_b);
            instr = instruct[address];
            $display("\t\tinstruction = 3'b%b\n", instr);
        end
    endtask

    task invalid;
        begin
            #(`CYCLE);
            valid = 0;
            Data_A = 8'dx;
            Data_B = 8'dx;
            instruction = 3'dx;
        end
    endtask
    integer ii;
    // simulate
    initial begin
        #(`CYCLE*20);

        //reset
        @(negedge clk);
        $display("\n======= Start the simulation =======\n");
        rst_n = 0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1;

        //start
        for(ii = 0; ii < `ANS_LEN; ii = ii + 1) begin
            @(negedge clk);
            $display("\t------ Start a new operation\n");
            start = 1;
            @(negedge clk);
            start = 0;
            send_Vaild_Numbers(Data_A, Data_B, valid, instruction, addr, pair);
            invalid;
            send_Vaild_Numbers(Data_A, Data_B, valid, instruction, addr, pair);
            invalid;
            send_Vaild_Numbers(Data_A, Data_B, valid, instruction, addr, pair);
            invalid;
            one_left = 1;
            #(`CYCLE);
            one_left = 0;
            send_Vaild_Numbers(Data_A, Data_B, valid, instruction, addr, pair);
            $display("\t----- One operation is finished\n");
            invalid;
            #(`CYCLE*10);
        end
    end

    integer ans, i, errors;
    initial begin
        ans = 0;
        while(ans < `ANS_LEN) begin
            wait(finish == 1);
            ans = ans + 1;
            if(pair <= `SEQ_LEN) begin
                $display("[ERROR] The integers are not totally read, so the result must be wrong.\n");
                $finish;
            end
            else begin
                stu_ans[ans-1] = maximum;
            end
            wait(finish==0);
        end
        
        errors = 0;
        $display("\n========Start Checking the Answers========");
        for(i = 0; i < `ANS_LEN; i = i + 1) begin
            if(golden[i]==stu_ans[i]) begin
                //$display("[Success] Your answer%2d = 8'b%b(8'h%h).", i+1, golden[i], golden[i]);
            end
            else begin
                $display("[ERROR]   Your answer%2d = 8'b%b(8'h%h), but the golden = 8'b%b(8'h%h).", i+1, stu_ans[i], stu_ans[i], golden[i], golden[i]);
                errors = errors + 1;
            end
        end

        if(errors==0) begin
            $display("\nCongratulations!! You pass all the patterns.");
            $display("Enjoy Your Summer Vacation!!\n");
            $display("           _______");
            $display("          /       \\");
            $display("          | ^   ^ |");
            $display("          \\___o___/");
            $display("              |");
            $display("          ____|____");
            $display("         /    |    \\");
            $display("  __    /     |     \\    __");
            $display("  |_|  /      |      \\  |_|");
            $display("  | |_/___    |    ___\\_| |");
            $display("  | _____|    |    |____  |");
            $display("  | _____|    |    |____  |");
            $display("  | _____|    |    |____  |");
            $display("  |______|    |    |______|");
            $display("             / \\");
            $display("            /   \\");
            $display("           /     \\");
            $display("          /       \\");
            $display("         /         \\");
            $display("        /           \\\n");
        end
        else begin
            $display("There are some errors.");
            $display("Keep going!!");   
            $display("                 \\@/_____");
            $display("                  | |    |");
            $display("               __/\\_|    |");
            $display("               |         |");
            $display("          _____|         |");
            $display("          |              |");
            $display("     _____|              |");
            $display("     |                   |");
            $display("_____|___________________|\n");
        end
        $finish;
    end

    //store the waveform
    initial begin
        $dumpfile("project.vcd");
        $dumpvars;
    end
    

    initial begin
        #(`CYCLE*`END_CYCLES);
        $display("[ERROR] Time Limit Exceed!");
        $display("It's highly possible that your didn't pull up \"finish\" signal.");
        $display("You can check the waveform for detail information.");
        $display("Stop Simulation.");
        $finish;
    end
endmodule