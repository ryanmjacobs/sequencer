module uart_top (/*AUTOARG*/
   // Outputs
   o_tx, o_tx_busy, o_rx_data, o_rx_valid,
   // Inputs
   i_rx, i_reg, i_tx_data, i_tx_stb, clk, rst
   );

`include "seq_definitions.v"
   
   output                   o_tx;  // asynchronous UART TX
   input                    i_rx;  // asynchronous UART RX
   input [1:0]              i_reg; // register referenced by switches
   
   output                   o_tx_busy;
   output [7:0]             o_rx_data;
   output                   o_rx_valid;
   
   input [seq_dp_width-1:0] i_tx_data;
   input                    i_tx_stb;
   
   input                    clk;
   input                    rst;

   parameter stIdle = 0;

   parameter stR0   = 1; // print 'R'
   parameter stR1   = 2; // print <reg>
   parameter stR2   = 3; // print ':'

   parameter stNib1 = 4;
   parameter stNL   = stNib1+uart_num_nib;   // 8
   parameter stCR   = stNib1+uart_num_nib+1; // 9
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 tfifo_empty;            // From tfifo_ of uart_fifo.v
   wire                 tfifo_full;             // From tfifo_ of uart_fifo.v
   wire [7:0]           tfifo_out;              // From tfifo_ of uart_fifo.v
   // End of automatics

   reg [7:0]            tfifo_in;
   wire                 tx_active;
   wire                 tfifo_rd;
   reg                  tfifo_rd_z;
   reg [seq_dp_width-1:0]  tx_data;
   reg [3:0]               state;

   assign o_tx_busy = (state!=stIdle);
   
   always @ (posedge clk)
     if (rst)
       state <= stIdle;
     else
       case (state)
         stIdle:
           if (i_tx_stb)
             begin
                state   <= stR0;
                tx_data <= i_tx_data;
             end
         stCR:
           if (~tfifo_full) state <= stIdle;
         default:
           if (~tfifo_full)
             begin
                // only shift fifo if we are actually outputting nibbles
                if (state >= stNib1)
                    tx_data <= {tx_data,4'b0000};

                state <= state + 1;
             end
       endcase // case (state)

   function [7:0] fnNib2ASCII;
      input [3:0] din;
      begin
         case (din)
           8'h0: fnNib2ASCII = "0";
           8'h1: fnNib2ASCII = "1";
           8'h2: fnNib2ASCII = "2";
           8'h3: fnNib2ASCII = "3";
           8'h4: fnNib2ASCII = "4";
           8'h5: fnNib2ASCII = "5";
           8'h6: fnNib2ASCII = "6";
           8'h7: fnNib2ASCII = "7";
           8'h8: fnNib2ASCII = "8";
           8'h9: fnNib2ASCII = "9";
           8'hA: fnNib2ASCII = "A";
           8'hB: fnNib2ASCII = "B";
           8'hC: fnNib2ASCII = "C";
           8'hD: fnNib2ASCII = "D";
           8'hE: fnNib2ASCII = "E";
           8'hF: fnNib2ASCII = "F";
         endcase // case (char)
      end
   endfunction // fnNib2ASCII

   always @*
     case (state)
       stNL:    tfifo_in = "\n";
       stCR:    tfifo_in = "\r";

       stR0:    tfifo_in = "R";
       stR1:    tfifo_in = fnNib2ASCII(i_reg);
       stR2:    tfifo_in = ":";

       default: tfifo_in = fnNib2ASCII(tx_data[seq_dp_width-1:seq_dp_width-4]);
     endcase // case (state)
   
   assign tfifo_rd = ~tfifo_empty & ~tx_active & ~tfifo_rd_z;

   assign tfifo_wr = ~tfifo_full & (state!=stIdle);
   
   uart_fifo tfifo_ (// Outputs
                     .fifo_cnt          (),
                     .fifo_out          (tfifo_out[7:0]),
                     .fifo_full         (tfifo_full),
                     .fifo_empty        (tfifo_empty),
                     // Inputs
                     .fifo_in           (tfifo_in[7:0]),
                     .fifo_rd           (tfifo_rd),
                     .fifo_wr           (tfifo_wr),
                     /*AUTOINST*/
                     // Inputs
                     .clk               (clk),
                     .rst               (rst));

   always @ (posedge clk)
     if (rst)
       tfifo_rd_z <= 1'b0;
     else
       tfifo_rd_z <= tfifo_rd;

   uart uart_ (// Outputs
               .received                (o_rx_valid),
               .rx_byte                 (o_rx_data[7:0]),
               .is_receiving            (),
               .is_transmitting         (tx_active),
               .recv_error              (),
               .tx                      (o_tx),
               // Inputs
               .rx                      (i_rx),
               .transmit                (tfifo_rd_z),
               .tx_byte                 (tfifo_out[7:0]),
               /*AUTOINST*/
               // Inputs
               .clk                     (clk),
               .rst                     (rst));
   
endmodule // uart_top
// Local Variables:
// verilog-library-flags:("-y ../../osdvu/")
// End:
