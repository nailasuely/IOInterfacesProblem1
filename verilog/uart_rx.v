
module uart_rx 
  #(parameter CLKS_PER_BIT = 457)
  (
   input        i_Clock,
   input        i_Rx_Serial, // Pino de Entrada do RX
   output       o_Rx_DV, // Saída para indicar se o dado já foi recebido
   output [7:0] o_Rx_Byte // Saida do dado recebido
	
   );
	
   //Definicação dos estados da máquina de estados 
  localparam [2:0] s_IDLE         = 3'b000,
						 s_RX_START_BIT = 3'b001,
						 s_RX_DATA_BITS = 3'b010,
						 s_RX_STOP_BIT  = 3'b011,
						 s_CLEANUP      = 3'b100;
   
  reg           r_Rx_Data_R = 1'b1;
  reg           r_Rx_Data   = 1'b1;
   
  reg [11:0]     r_Clock_Count = 0;
  reg [2:0]     r_Bit_Index   = 0; //8 bits total
  reg [7:0]     r_Rx_Byte     = 0;
  reg           r_Rx_DV       = 0;
  reg [2:0]     r_SM_Main     = 0;

   
  // Purpose: Double-register the incoming data.
  // This allows it to be used in the UART RX Clock Domain.
  // (It removes problems caused by metastability)
  always @(posedge i_Clock)
    begin
      r_Rx_Data_R <= i_Rx_Serial;
      r_Rx_Data   <= r_Rx_Data_R;
    end
   
   
  // Purpose: Control RX state machine
  always @(posedge i_Clock)
    begin
       
      case (r_SM_Main)
        s_IDLE :
          begin
            r_Rx_DV       <= 1'b0;
            r_Clock_Count <= 12'd0;
            r_Bit_Index   <= 3'd0;
             
            if (r_Rx_Data == 1'b0)          // Start bit detectado, muda pro estado start bit
              r_SM_Main <= s_RX_START_BIT;
            else
              r_SM_Main <= s_IDLE;
          end
         
        // Checa na metade do start bit para certificar que ainda é baixo
        s_RX_START_BIT :
          begin
            if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
              begin
                if (r_Rx_Data == 1'b0)
                  begin
                    r_Clock_Count <= 12'd0;  //Reseta o counter
                    r_SM_Main     <= s_RX_DATA_BITS; // Vai para o estado de recebimento dos bits de dado
                  end
                else
                  r_SM_Main <= s_IDLE; // Caso não, volta para o estado IDLE
              end
            else
              begin
                r_Clock_Count <= r_Clock_Count + 12'd1;
                r_SM_Main     <= s_RX_START_BIT;
              end
          end // case: s_RX_START_BIT
         
         
        // Espera CLKS_PER_BIT-1 ciclos de clock para ter a amostra do dado
        s_RX_DATA_BITS :
          begin
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 12'd1;
                r_SM_Main     <= s_RX_DATA_BITS;
              end
            else
              begin
                r_Clock_Count          <= 12'd0; //Se o contador chegar ao limite, zera-se ele 
                r_Rx_Byte[r_Bit_Index] <= r_Rx_Data; // E coloca-se o dado recebido no momento no registrador na posição do index
                 
                // Check if we have received all bits
                if (r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index + 3'd1; // Se o index ainda não chegou ao limite, incremeta-se +1
                    r_SM_Main   <= s_RX_DATA_BITS; 
                  end
                else
                  begin
                    r_Bit_Index <= 3'd0;
                    r_SM_Main   <= s_RX_STOP_BIT; // Ao receber todos os 8 bits, muda-se para o caso de stop bit
                  end
              end
          end 
     
     
        // Receive Stop bit.  Stop bit = 1
        s_RX_STOP_BIT :
          begin
            // Espera CLKS_PER_BIT-1 ciclos de clock para o stop bit terminar
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 12'd1;
                r_SM_Main     <= s_RX_STOP_BIT;
              end
            else
              begin
                r_Rx_DV       <= 1'b1;
                r_Clock_Count <= 12'd0;
                r_SM_Main     <= s_CLEANUP;
              end
          end 
     
         
        // Fica neste estado por um ciclo de clock, para dar tempo do DV
        s_CLEANUP :
          begin
						r_SM_Main <= s_IDLE;
						r_Rx_DV   <= 1'b0;
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
         
      endcase
    end   



  
  assign o_Rx_DV   = r_Rx_DV;
  assign o_Rx_Byte = r_Rx_Byte;

  
   
endmodule // uart_rx