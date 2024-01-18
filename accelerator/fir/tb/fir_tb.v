//`include "rtl/bram11.v"
//`include "rtl/fir.v"
//`include "out_gold.dat"
//`include "samples_triangular_wave.dat"
`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/20/2023 10:38:55 AM
// Design Name: 
// Module Name: fir_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fir_tb
#(  parameter pADDR_WIDTH  = 12,
    parameter pDATA_WIDTH  = 32,
    parameter Tape_Num     = 11,
    parameter Data_Num_fir = 64,
    parameter Data_Num_mm  = 16,
    parameter Data_Num_sort= 10
)();

    reg                         axis_clk;
    reg                         axis_rst_n;

    reg                         ss_tvalid;
    reg signed [(pDATA_WIDTH-1) : 0] ss_tdata;
    reg                         ss_tlast;
    wire                        ss_tready;

    reg [2:0] ap_start;
    wire ap_idle;

    reg                         sm_tready;
    wire                        sm_tvalid;
    wire signed [(pDATA_WIDTH-1) : 0] sm_tdata;
    wire                        sm_tlast;

    wire [2:0] ap_done;

    reg error_coef;    

    accelerator accelerator_DUT(
        .clk(axis_clk),
        .rst(axis_rst_n),

        .ss_tvalid(ss_tvalid),
        .ss_tdata(ss_tdata),
        .ss_tlast(ss_tlast),
        .ss_tready(ss_tready),

        .ap_start(ap_start),
        .ap_idle(ap_idle),

        .sm_tready(sm_tready),
        .sm_tvalid(sm_tvalid),
        .sm_tdata(sm_tdata),
        .sm_tlast(sm_tlast),

        .ap_done(ap_done)
        );
    

    reg signed [(pDATA_WIDTH-1):0] Din_list_fir[0:63];
    reg signed [(pDATA_WIDTH-1):0] golden_list_fir[0:63];

    reg signed [(pDATA_WIDTH-1):0] Din_list_mm[0:31];
    reg signed [(pDATA_WIDTH-1):0] golden_list_mm[0:15];

    reg signed [(pDATA_WIDTH-1):0] Din_list_sort[0:9];
    reg signed [(pDATA_WIDTH-1):0] golden_list_sort[0:9];

    reg round1 , round2 , round3;

    initial begin
        // $fsdbDumpfile("fir.fsdb");
        // $fsdbDumpvars(0,"+mda");
        // $fsdbDumpvars();
        $dumpfile("fir.vcd");
        $dumpvars(0);
    end

    initial begin
        axis_clk = 0;
        forever begin
            #5 axis_clk = (~axis_clk);
        end
    end

    initial begin
        axis_rst_n = 0;
        round1 = 0 ;
        round2 = 0 ;
        round3 = 0 ;
        @(posedge axis_clk); @(posedge axis_clk); //?
        $display("------------System Reset-------------");
        axis_rst_n = 1;
        @(posedge axis_clk);
        axis_rst_n = 0;
        round1 = 1 ;
        sm_tready = 0;

    end

    // reg [31:0]  data_length;
    // integer Din, golden, input_data, golden_data, m;

    reg [31:0]  data_length_fir;
    integer Din_fir, golden_fir, input_data_fir, golden_data_fir;

    reg [31:0]  data_length_mm;
    integer Din_mm, golden_mm, input_data_mm, golden_data_mm;

    reg [31:0]  data_length_sort;
    integer Din_sort, golden_sort, input_data_sort, golden_data_sort;

    integer m;
    // read file
    initial begin
        data_length_fir = 0;
        Din_fir = $fopen("./fir_din.dat","r");
        golden_fir = $fopen("./fir_gold.dat","r");
        for(m=0;m<Data_Num_fir;m=m+1) begin
            input_data_fir = $fscanf(Din_fir,"%d", Din_list_fir[m]);
            //$display("%d.",Din_list[m]);
            golden_data_fir = $fscanf(golden_fir,"%d", golden_list_fir[m]);
            data_length_fir = data_length_fir + 1;
        end

        data_length_mm = 0;
        Din_mm = $fopen("./mm_din.dat","r");
        golden_mm = $fopen("./mm_gold.dat","r");
        for(m=0;m<32;m=m+1) begin
            input_data_mm = $fscanf(Din_mm,"%d", Din_list_mm[m]);
            //$display("%d.",Din_list[m]);
            golden_data_mm = $fscanf(golden_mm,"%d", golden_list_mm[m]);
            data_length_mm = data_length_mm + 1;
        end

        data_length_sort = 0;
        Din_sort = $fopen("./sort_din.dat","r");
        golden_sort = $fopen("./sort_gold.dat","r");
        for(m=0;m<10;m=m+1) begin
            input_data_sort = $fscanf(Din_sort,"%d", Din_list_sort[m]);
            //$display("%d.",Din_list[m]);
            golden_data_sort = $fscanf(golden_sort,"%d", golden_list_sort[m]);
            data_length_sort = data_length_sort + 1;
        end
    end

    integer i;
    initial begin
        @(posedge round1) begin //fir
            $display("------------Start simulation fir-----------");
            ss_tvalid <= 0; ss_tlast <= 0;
            $display("----Start the data input(AXI-Stream)----");
            wait(ap_idle);
            @(posedge axis_clk) ap_start <= 1;
            @(posedge axis_clk) ap_start <= 0;

            $display("----Start the fir tap (AXI-Stream)----");
            wait(ss_tready)
            for(i=0;i<Tape_Num-1;i=i+1) begin
                ss(coef[i]);
            end
            ss_tlast <= 1; ss(coef[(Tape_Num-1)]);
            ss_tvalid <= 0;ss_tlast <= 0;

            $display("----Start the fir data (AXI-Stream)----");
            wait(ss_tready)
            for(i=0;i<(data_length_fir-1);i=i+1) begin
                ss(Din_list_fir[i]);
            end
            //config_read_check(12'h00, 32'h00, 32'h0000_000f); // check idle = 0 (0x00 [bit 0~3]=4'b0000)
            ss_tlast <= 1; ss(Din_list_fir[(Data_Num_fir-1)]);
            ss_tvalid <= 0; ss_tlast <=0;

            $display("------End the data input(AXI-Stream)------");
        end
        
        @(posedge round2) begin
            $display("------------Start simulation matmul-----------");
            ss_tvalid <= 0; ss_tlast <= 0;
            $display("----Start the data input(AXI-Stream)----");
            wait(ap_idle);
            @(posedge axis_clk) ap_start <= 2;
            @(posedge axis_clk) ap_start <= 0;

            wait(ss_tready)
            for(i=0;i<(data_length_mm-1);i=i+1) begin
                ss(Din_list_mm[i]);
            end
            //config_read_check(12'h00, 32'h00, 32'h0000_000f); // check idle = 0 (0x00 [bit 0~3]=4'b0000)
            ss_tlast = 1; ss(Din_list_mm[(data_length_mm-1)]);
            ss_tvalid <= 0;ss_tlast <= 0;

            $display("------End the data input(AXI-Stream)------");
        end
        
        @(posedge round3) begin
            $display("------------Start simulation sorting-----------");
            ss_tvalid <= 0; ss_tlast <= 0;
            $display("----Start the data input(AXI-Stream)----");
            wait(ap_idle);
            @(posedge axis_clk) ap_start <= 4;
            @(posedge axis_clk) ap_start <= 0;

            for(i=0;i<(data_length_sort-1);i=i+1) begin
                ss(Din_list_sort[i]);
            end
            //config_read_check(12'h00, 32'h00, 32'h0000_000f); // check idle = 0 (0x00 [bit 0~3]=4'b0000)
            ss_tlast = 1; ss(Din_list_sort[(data_length_sort-1)]);
            ss_tvalid <= 0;ss_tlast <= 0;
            $display("------End the data input(AXI-Stream)------");
        end
    end

    integer k;
    reg error;
    reg status_error;
    initial begin
        @(posedge round1) begin
            error = 0; status_error = 0;
            // wait (ap_done[0]);
            sm_tready = 1;
            wait (sm_tvalid);
            // sm_tready = 1;
            for(k=0;k < Data_Num_fir;k=k+1) begin
                sm(golden_list_fir[k],k);
            end
            sm_tready <= 0;
            //config_read_check(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
            //config_read_check(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
            if (error == 0) begin
                $display("-----------Congratulations! Pass-------------");
                $display("----------- fir Simulation End -------------\n");
                @(posedge axis_clk) begin
                    round1 = 0 ;
                    round2 = 1 ;
                    $display("round update");
                end
            end
            else begin
                $display("--------fir Simulation Failed---------");
                $display("----------- fir Simulation End -------------");
                $display("----------- fir Stop Simulation -------------");   
                $finish;             
            end
            // origin is $finish

        end
    end
    initial begin
        @(posedge round2) begin
            $display("matmul start");
            error = 0; status_error = 0;
            // wait (ap_done[1]);
            sm_tready = 1;
            wait (sm_tvalid);

            for(k=0;k < Data_Num_mm;k=k+1) begin
                sm(golden_list_mm[k],k);
            end
            sm_tready <= 0;
            //config_read_check(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
            //config_read_check(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
            if (error == 0) begin
                $display("-----------Congratulations! Pass-------------");
                $display("----------- matmul Simulation End -------------\n");
                @(posedge axis_clk) begin
                    round2 = 0 ;
                    round3 = 1 ;
                    $display("round update");
                end
            end
            else begin
                $display("--------matmul Simulation Failed---------");
                $display("----------- matmul Simulation End -------------");
                $display("----------- matmul Stop Simulation -------------");   
                $finish;             
            end
            // origin is $finish
        end
    end
    initial begin
        @(posedge round3) begin
            error = 0; status_error = 0;
            // wait (ap_done[2]);
            sm_tready = 1;
            wait (sm_tvalid);
            // sm_tready = 1;
            // wait (sm_tvalid);
            for(k=0;k < Data_Num_sort;k=k+1) begin
                sm(golden_list_sort[k],k);
            end
            sm_tready <= 0;
            //config_read_check(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
            //config_read_check(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
            if (error == 0) begin
                $display("-----------Congratulations! Pass-------------");
                $display("----------- 3rd Simulation End -------------\n");
                round3 = 0 ;
                $finish; 
            end
            else begin
                $display("--------Simulation Failed---------");
                $display("----------- 3rd Simulation End -------------");
                $display("----------- Stop Simulation -------------");   
                $finish;             
            end
            // origin is $finish
        end        

        $finish; 
    end

    // Prevent hang
    integer timeout = (1000000);
    initial begin
        while(timeout >= 1) begin
            @(posedge axis_clk);
            timeout = timeout - 1;
        end
        $display($time, "Simualtion Hang ....");
        $finish;
    end


    reg signed [31:0] coef[0:10]; // fill in coef 
    initial begin
        coef[0]  =  32'd0;
        coef[1]  = -32'd10;
        coef[2]  = -32'd9;
        coef[3]  =  32'd23;
        coef[4]  =  32'd56;
        coef[5]  =  32'd63;
        coef[6]  =  32'd56;
        coef[7]  =  32'd23;
        coef[8]  = -32'd9;
        coef[9]  = -32'd10;
        coef[10] =  32'd0;
    end

    // reg error_coef;
    // initial begin
    //     @(posedge round1) begin
    //     error_coef = 0;
    //     $display("----Start the coefficient input(AXI-lite)----");
    //     config_write(12'h10, data_length);
    //     $display("write coef time = %t.",$time);
    //     for(k=0; k< Tape_Num; k=k+1) begin
    //         config_write(12'h20+4*k, coef[k]);
    //     end
    //     awvalid <= 0; wvalid <= 0;
    //     // read-back and check
    //     $display(" Check Coefficient ...");
    //     $display(" time = %t.",$time);
    //     for(k=0; k < Tape_Num; k=k+1) begin
    //         config_read_check(12'h20+4*k, coef[k], 32'hffffffff);
    //     end
    //     arvalid <= 0;
    //     $display(" Tape programming done ...");
    //     $display(" Start FIR");
    //     @(posedge axis_clk) config_write(12'h00, 32'h0000_0001);    // ap_start = 1
    //     @(posedge axis_clk) config_write(12'h00, 32'h0000_0000);
    //     $display("----End the coefficient input(AXI-lite)----");
    //     end

    //     @(posedge round2) begin
    //     error_coef = 0;
    //     $display("----Start the coefficient input(AXI-lite)----");
    //     config_write(12'h10, data_length);
    //     $display("write coef time = %t.",$time);
    //     for(k=0; k< Tape_Num; k=k+1) begin
    //         config_write(12'h20+4*k, coef[k]);
    //     end
    //     awvalid <= 0; wvalid <= 0;
    //     // read-back and check
    //     $display(" Check Coefficient ...");
    //     $display(" time = %t.",$time);
    //     for(k=0; k < Tape_Num; k=k+1) begin
    //         config_read_check(12'h20+4*k, coef[k], 32'hffffffff);
    //     end
    //     arvalid <= 0;
    //     $display(" Tape programming done ...");
    //     $display(" Start FIR");
    //     @(posedge axis_clk) config_write(12'h00, 32'h0000_0001);    // ap_start = 1
    //     @(posedge axis_clk) config_write(12'h00, 32'h0000_0000);
    //     $display("----End the coefficient input(AXI-lite)----");
    //     end

    //     @(posedge round3) begin
    //     error_coef = 0;
    //     $display("----Start the coefficient input(AXI-lite)----");
    //     config_write(12'h10, data_length);
    //     $display("write coef time = %t.",$time);
    //     for(k=0; k< Tape_Num; k=k+1) begin
    //         config_write(12'h20+4*k, coef[k]);
    //     end
    //     awvalid <= 0; wvalid <= 0;
    //     // read-back and check
    //     $display(" Check Coefficient ...");
    //     $display(" time = %t.",$time);
    //     for(k=0; k < Tape_Num; k=k+1) begin
    //         config_read_check(12'h20+4*k, coef[k], 32'hffffffff);
    //     end
    //     arvalid <= 0;
    //     $display(" Tape programming done ...");
    //     $display(" Start FIR");
    //     @(posedge axis_clk) config_write(12'h00, 32'h0000_0001);    // ap_start = 1
    //     @(posedge axis_clk) config_write(12'h00, 32'h0000_0000);
    //     $display("----End the coefficient input(AXI-lite)----");
    //     end        
    // end

    // task config_write;
    //     input [11:0]    addr;
    //     input [31:0]    data;
    //     begin
    //         awvalid <= 0; wvalid <= 0;
    //         @(posedge axis_clk);
    //         awvalid <= 1; awaddr <= addr;
    //         wvalid  <= 1; wdata <= data;
    //         @(posedge axis_clk);
    //         while (!wready) @(posedge axis_clk); // wait
    //         awvalid <= 0; wvalid <= 0;
    //     end
    // endtask

    // task config_read_check;
    //     input [11:0]        addr;
    //     input signed [31:0] exp_data;
    //     input [31:0]        mask;
    //     begin
    //         arvalid <= 0;
    //         @(posedge axis_clk);
    //         arvalid <= 1; araddr <= addr;
    //         rready <= 1;
    //         @(posedge axis_clk);
    //         while (!rvalid) @(posedge axis_clk);
    //         if( (rdata & mask) != (exp_data & mask)) begin
    //             $display("ERROR: exp = %d, rdata = %d", exp_data, rdata);
    //             error_coef <= 1;
    //         end else begin
    //             $display("OK: exp = %d, rdata = %d", exp_data, rdata);
    //         end
    //         arvalid <= 0;
    //     end
    // endtask



    task ss;
        input  signed [31:0] in1;
        begin
            // ss_tvalid <= 0;
            // @(posedge axis_clk);
            ss_tvalid <= 1;
            ss_tdata  <= in1;
            @(posedge axis_clk);
            while (!ss_tready) @(posedge axis_clk);
        end
    endtask

    task sm;
        input  signed [31:0] in2; // golden data
        input         [31:0] pcnt; // pattern count
        begin
            sm_tready <= 1;
            wait(sm_tvalid);
            @(posedge axis_clk) 
            while(!sm_tvalid) @(posedge axis_clk);
            if (sm_tdata != in2) begin
                $display("[ERROR] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
                error <= 1;
            end
            else begin
                $display("[PASS] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
            end
            // @(posedge axis_clk);
        end
    endtask
endmodule

