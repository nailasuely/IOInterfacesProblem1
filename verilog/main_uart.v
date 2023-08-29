
module main(
   input        i_Clock,  // Entrada de clock (Interno da FPGA 50Mhz)
   input        i_Rx_Serial,  // Entrada do RX
	inout			 dht_data_int,// Pino de entrada e saída do sensor DHT11 
   output 	    o_Tx_Active, // Pino para informar se a transmissão está acorrendo
   output    	 o_Tx_Serial, // Saída do pino de transmissão
   output       o_Tx_Done,// Saída para indicar que a trasnmissão foi completa
	output teste,
	output gnd
	
);

	// DEfinição dos fios que serão usados nas intâncias dos modulos necessários
	wire 			 o_Rx_DV;
   wire [7:0]   o_Rx_Byte;

	
	
// Instância do modulo UART RX
uart_rx instrx(
	.i_Clock(i_Clock),
   .i_Rx_Serial(i_Rx_Serial),
   .o_Rx_DV(o_Rx_DV),
   .o_Rx_Byte(o_Rx_Byte)

);




// Instância do modulo UART TX
uart_tx insttx(
	.i_Clock(i_Clock),
	.i_Tx_DV(o_Rx_DV),
	.i_Tx_Byte (o_Rx_Byte), 
   .o_Tx_Active(o_Tx_Active),
   .o_Tx_Serial(o_Tx_Serial),
   .o_Tx_Done(o_Tx_Done)
	
);

assign gnd = 1'b0;
assign teste = i_Clock;

endmodule 