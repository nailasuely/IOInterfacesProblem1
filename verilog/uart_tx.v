
 
module uart_tx 
  #(parameter CLKS_PER_BIT = 434)
  (
   input       i_Clock,
   input       i_Tx_DV, // Bit para que o TX comece a transmitir 
   input [7:0] i_Tx_Byte, // Dado que deve ser transmitido 
   output      o_Tx_Active, // Bit para indicar se a transmissão está ativa
   output reg  o_Tx_Serial, // Saida serial para envio do dado
   output      o_Tx_Done // Bit para indicar que a transmissão foi finalizada
   );
  
  // Definição dos casos da máquina de estados
  localparam [2:0] s_IDLE         = 3'b000,
						 s_TX_START_BIT = 3'b001,
						 s_TX_DATA_BITS = 3'b010,
						 s_TX_STOP_BIT  = 3'b011,
						 s_CLEANUP      = 3'b100;
   
  reg [2:0]    r_SM_Main     = 0;
  reg [11:0]   r_Clock_Count = 0;
  reg [2:0]    r_Bit_Index   = 0;
  reg [7:0]    r_Tx_Data     = 0;
  reg          r_Tx_Done     = 0;
  reg          r_Tx_Active   = 0;
  
  always @(posedge i_Clock)
    begin
       
      case (r_SM_Main)
        s_IDLE :
          begin
            o_Tx_Serial   <= 1'b1;         // Deixa a saída no bit 1, enquanto no IDLE, como é feito no padrão RS-232
            r_Tx_Done     <= 1'b0;
            r_Clock_Count <= 12'd0;
            r_Bit_Index   <= 3'd0;
             
            if (i_Tx_DV == 1'b1) // Se ativada a transmissão
              begin
                r_Tx_Active <= 1'b1;
                r_Tx_Data   <= i_Tx_Byte;
                r_SM_Main   <= s_TX_START_BIT; //Muda para o estado de star bit
              end
            else
              r_SM_Main <= s_IDLE;
          end // case: s_IDLE
         
         
        // Send out Start Bit. Start bit = 0
        s_TX_START_BIT :
          begin
            o_Tx_Serial <= 1'b0;
            // Espera CLKS_PER_BIT-1 ciclos de clock para finalização do envio do start bit 
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 12'd1;
                r_SM_Main     <= s_TX_START_BIT;
              end 
            else
              begin
                r_Clock_Count <= 12'd0;
                r_SM_Main     <= s_TX_DATA_BITS;
              end
          end // case: s_TX_START_BIT
         
         
        // Espera CLKS_PER_BIT-1 ciclos de clock para a finalização de cada bit de dados         
        s_TX_DATA_BITS :
          begin
            o_Tx_Serial <= r_Tx_Data[r_Bit_Index];
             
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 12'd1;
                r_SM_Main     <= s_TX_DATA_BITS;
              end
            else
              begin
                r_Clock_Count <= 12'd0;
                 
                // Checa sem enviou todos os bits
                if (r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index + 3'd1;
                    r_SM_Main   <= s_TX_DATA_BITS;
                  end
                else
                  begin // Se enviou muda para o estado de stop bit
                    r_Bit_Index <= 3'd0;
                    r_SM_Main   <= s_TX_STOP_BIT;
                  end
              end
          end // case: s_TX_DATA_BITS
         
         
        // Send out Stop bit.  Stop bit = 1
        s_TX_STOP_BIT :
          begin
            o_Tx_Serial <= 1'b1;
             
            // Espera CLKS_PER_BIT-1 cliclos de clock para finalização do stop bit
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 12'd1;
                r_SM_Main     <= s_TX_STOP_BIT;
              end
            else
              begin
                r_Tx_Done     <= 1'b1; // Indica que o processo de envio foi finalizado
                r_Clock_Count <= 12'd0;
                r_SM_Main     <= s_CLEANUP; // Vai para o estado de clear
                r_Tx_Active   <= 1'b0;
              end
          end // case: s_Tx_STOP_BIT
         
         
        // Fica aqui 1 ciclo de clock
        s_CLEANUP :
          begin
            r_Tx_Done <= 1'b1;
            r_SM_Main <= s_IDLE;
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
         
      endcase
    end
 
  assign o_Tx_Active = r_Tx_Active;
  assign o_Tx_Done   = r_Tx_Done;

endmodule 
