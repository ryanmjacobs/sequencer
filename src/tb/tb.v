`timescale 1ns / 1ps
// multiply proper output: 0040, 0003, 00C0, 0100
module tb;
`include "seq_definitions.v"

   reg [7:0] sw;
   reg       clk;
   reg       btnS;
   reg       btnR;
   reg [7:0] mem [1023:0], r;

   integer   i;
   integer lines;
   reg [1:0] op;
   reg [1:0] ra, rb, rc;
   reg [3:0] num;

   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 RsRx;                   // From model_uart0_ of model_uart.v
   wire                 RsTx;                   // From uut_ of nexys3.v
   wire [7:0]           led;                    // From uut_ of nexys3.v
   // End of automatics

   initial
     begin
        //$shm_open  ("dump", , ,1);
        //$shm_probe (tb, "ASTF");

        clk = 0;
        btnR = 1;
        btnS = 0;
        #1000 btnR = 0;
        #1500000;
        
        $readmemb("seq.code", mem);
        
        lines = mem[0];
        
        for (i = 1; i <= lines; i = i + 1) begin
          r = mem[i];
          op = r[7:6];
          ra = r[5:4];
          rb = r[3:2];
          rc = r[1:0];
          num = r[3:0];

          if (op == seq_op_push)
            tskRunPUSH(ra, num);
          else if (op == seq_op_add)
            tskRunADD(ra, rb, rc);
          else if (op == seq_op_mult)
            tskRunMULT(ra, rb, rc);
          else if (op == seq_op_send)
            tskRunSEND(ra);
        end

        #1000;        
        $finish;
     end

   always #5 clk = ~clk;
   
   model_uart model_uart0_ (// Outputs
                            .TX                  (RsRx),
                            // Inputs
                            .RX                  (RsTx)
                            /*AUTOINST*/);

   defparam model_uart0_.name = "UART0";
   defparam model_uart0_.baud = 1000000;
   
   
   nexys3 uut_ (/*AUTOINST*/
                // Outputs
                .RsTx                   (RsTx),
                .led                    (led[7:0]),
                // Inputs
                .RsRx                   (RsRx),
                .sw                     (sw[7:0]),
                .btnS                   (btnS),
                .btnR                   (btnR),
                .clk                    (clk));

   task tskRunInst;
      input [7:0] inst;
      begin
         $display ("%d ... Running instruction %08b", $stime, inst);
         sw = inst;
         #1500000 btnS = 1;
         #3000000 btnS = 0;
      end
   endtask //

   task tskRunPUSH;
      input [1:0] ra;
      input [3:0] immd;
      reg [7:0]   inst;
      begin
         inst = {2'b00, ra[1:0], immd[3:0]};
         tskRunInst(inst);
      end
   endtask //

   task tskRunSEND;
      input [1:0] ra;
      reg [7:0]   inst;
      begin
         inst = {2'b11, ra[1:0], 4'h0};
         tskRunInst(inst);
      end
   endtask //

   task tskRunADD;
      input [1:0] ra;
      input [1:0] rb;
      input [1:0] rc;
      reg [7:0]   inst;
      begin
         inst = {2'b01, ra[1:0], rb[1:0], rc[1:0]};
         tskRunInst(inst);
      end
   endtask //

   task tskRunMULT;
      input [1:0] ra;
      input [1:0] rb;
      input [1:0] rc;
      reg [7:0]   inst;
      begin
         inst = {2'b10, ra[1:0], rb[1:0], rc[1:0]};
         tskRunInst(inst);
      end
   endtask //

   always @ (posedge clk)
     if (uut_.inst_vld)
       $display("%d ... instruction %08b executed", $stime, uut_.inst_wd);

   always @ (led)
     $display("%d ... led output changed to %08b", $stime, led);
   
endmodule // tb
// Local Variables:
// verilog-library-flags:("-y ../src/")
// End:
