// Módulo para Transmissão UART
module uart_tx 
  #(parameter CLKS_PER_BIT = 437) // Parâmetro: Número de ciclos de clock por bit UART
  (
   input       i_Clock,      
   input       i_Tx_DV,      // Indicador de dado válido de transmissão
   input [7:0] i_Tx_Byte,    // Byte de dados a ser transmitido
   output      o_Tx_Active,  // Indicador de transmissão ativa
   output reg  o_Tx_Serial,  // Sinal serial de saída (dados transmitidos)
   output      o_Tx_Done     // Indicador de transmissão concluída
   );
  
  // Definição dos estados da máquina de estados
  parameter s_IDLE         = 3'b000;
  parameter s_TX_START_BIT = 3'b001;
  parameter s_TX_DATA_BITS = 3'b010;
  parameter s_TX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;
   
  // Registros para controlar o estado da máquina de estados
  reg [2:0]    r_SM_Main     = 0;     // Estado da máquina de estados
  reg [7:0]    r_Clock_Count = 0;     // Contador de ciclos de clock
  reg [2:0]    r_Bit_Index   = 0;     // Índice do bit (8 bits no total)
  reg [7:0]    r_Tx_Data     = 0;     // Byte de dados a ser transmitido
  reg          r_Tx_Done     = 0;     // Indicador de transmissão concluída
  reg          r_Tx_Active   = 0;     // Indicador de transmissão ativa
     
  always @(posedge i_Clock)
    begin
       
      case (r_SM_Main)
        s_IDLE :
          begin
            o_Tx_Serial   <= 1'b1;         // Mantém a linha em nível alto para o estado de espera
            r_Tx_Done     <= 1'b0;         // Redefine o indicador de transmissão concluída
            r_Clock_Count <= 0;            // Redefine o contador de ciclos de clock
            r_Bit_Index   <= 0;            // Redefine o índice do bit
             
            if (i_Tx_DV == 1'b1)           // Verifica se há um dado válido para transmitir
              begin
                r_Tx_Active <= 1'b1;       // Indica transmissão ativa
                r_Tx_Data   <= i_Tx_Byte;  // Armazena o byte de dados a ser transmitido
                r_SM_Main   <= s_TX_START_BIT; // Avança para o estado de início da transmissão
              end
            else
              r_SM_Main <= s_IDLE;         // Caso contrário, permanece no estado de espera
          end // case: s_IDLE
         
        // Envia o bit de início. Bit de início = 0
        s_TX_START_BIT :
          begin
            o_Tx_Serial <= 1'b0;          // Coloca a linha em nível baixo para o bit de início
             
            // Aguarda CLKS_PER_BIT-1 ciclos de clock para concluir o bit de início
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_START_BIT;
              end
            else
              begin
                r_Clock_Count <= 0;
                r_SM_Main     <= s_TX_DATA_BITS; // Avança para a transmissão dos bits de dados
              end
          end // case: s_TX_START_BIT
         
        // Aguarda CLKS_PER_BIT-1 ciclos de clock para concluir os bits de dados         
        s_TX_DATA_BITS :
          begin
            o_Tx_Serial <= r_Tx_Data[r_Bit_Index]; // Transmite o bit de dados correspondente
             
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_DATA_BITS;
              end
            else
              begin
                r_Clock_Count <= 0;
                 
                // Verifica se todos os bits foram transmitidos
                if (r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index + 1;
                    r_SM_Main   <= s_TX_DATA_BITS;
                  end
                else
                  begin
                    r_Bit_Index <= 0;
                    r_SM_Main   <= s_TX_STOP_BIT; // Avança para a transmissão do bit de parada
                  end
              end
          end // case: s_TX_DATA_BITS
         
        // Envia o bit de parada
        s_TX_STOP_BIT :
          begin
            o_Tx_Serial <= 1'b1;          // Coloca a linha em nível alto para o bit de parada
             
            // Aguarda CLKS_PER_BIT-1 ciclos de clock para concluir o bit de parada
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_STOP_BIT;
              end
            else
              begin
                r_Tx_Done     <= 1'b1;     // Indica que a transmissão foi concluída
                r_Clock_Count <= 0;
                r_SM_Main     <= s_CLEANUP; // Avança para a fase de limpeza
                r_Tx_Active   <= 1'b0;     // Desativa a transmissão
              end
          end // case: s_TX_STOP_BIT
         
        // Permanece aqui por 1 ciclo de clock antes de retornar ao estado de espera
        s_CLEANUP :
          begin
            r_Tx_Done <= 1'b1;           // Indica que a transmissão foi concluída
            r_SM_Main <= s_IDLE;         // Retorna ao estado de espera
          end
         
        default :
          r_SM_Main <= s_IDLE;           // Trata estados não reconhecidos como s_IDLE
         
      endcase
    end
 
  assign o_Tx_Active = r_Tx_Active;    // Atribui o indicador de transmissão ativa à sa
  assign o_Tx_Done   = r_Tx_Done;      // Atribui o indicador de transmissão concluída à saída correspondente
   
endmodule 