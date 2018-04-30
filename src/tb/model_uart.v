`timescale 1ns / 1ps

module model_uart(/*AUTOARG*/
   // Outputs
   TX,
   // Inputs
   RX
   );

   output TX;
   input  RX;

   parameter baud    = 115200;
   parameter bittime = 1000000000/baud;
   parameter name    = "UART0";
   
   reg [7:0] rxData;
   event     evBit;
   event     evByte;
   event     evTxBit;
   event     evTxByte;
   reg       TX;

   reg [63:0] buffer = 64'b0;

   initial
     begin
        TX = 1'b1;
     end
   
   always @ (negedge RX)
     begin
        rxData[7:0] = 8'h0;
        #(0.5*bittime);

        repeat (8) begin
            #bittime ->evBit;
            rxData[7:0] = {RX,rxData[7:1]};
        end

        // call display on '\r' and '\n'
        if (rxData == 10 || rxData == 13) begin
            if (buffer)
                $display ("%d %s Received: %x (%s)", $stime, name, buffer, buffer);
            buffer = 0;
        end
        else
            buffer = {buffer,rxData};
        ->evByte;
     end

   task tskRxData;
      output [7:0] data;
      begin
         @(evByte);
         data = rxData;
      end
   endtask // for
      
   task tskTxData;
      input [7:0] data;
      reg [9:0]   tmp;
      integer     i;
      begin
         tmp = {1'b1, data[7:0], 1'b0};
         for (i=0;i<10;i=i+1)
           begin
              TX = tmp[i];
              #bittime;
              ->evTxBit;
           end
         ->evTxByte;
      end
   endtask // tskTxData
   
endmodule // model_uart
