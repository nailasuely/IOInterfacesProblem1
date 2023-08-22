/*
Arquivo baixado de http://www.nandland.com
Este arquivo contém o Receptor UART. Este receptor é capaz de
receber 8 bits de dados seriais, um bit de início, um bit de parada,
e nenhum bit de paridade. Quando a recepção estiver completa, o_o_rx_dv será
colocado em nível alto por um ciclo de clock.

Defina o Parâmetro CLKS_PER_BIT da seguinte maneira:
CLKS_PER_BIT = (Frequência de i_Clock)/(Frequência da UART)
Exemplo: Clock de 50 MHz, UART de 115200 bauds
(50000000)/(115200) = 457
*/


// Módulo para Recebimento UART
module uart_rx
  #(parameter CLKS_PER_BIT = 457) // Parâmetro: Número de ciclos de clock por bit UART

  (
   input        i_Clock,     // Sinal de relógio de entrada
   input        i_Rx_Serial, // Sinal de dados serial de entrada
   output       o_Rx_DV,     // Indicador de dado válido de saída
   output [7:0] o_Rx_Byte    // Dados de saída de 8 bits
   );

  parameter s_IDLE         = 3'b000; // Estados da máquina de estados
  parameter s_RX_START_BIT = 3'b001;
  parameter s_RX_DATA_BITS = 3'b010;
  parameter s_RX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;

  reg           r_Rx_Data_R = 1'b1; // Registrador para armazenar o dado de entrada atual
  reg           r_Rx_Data   = 1'b1; // Registrador para armazenar o dado de entrada anterior

  reg [7:0]     r_Clock_Count = 0;   // Contador de ciclos de clock
  reg [2:0]     r_Bit_Index   = 0;   // Índice do bit (8 bits no total)
  reg [7:0]     r_Rx_Byte     = 0;   // Byte de dados recebidos
  reg           r_Rx_DV       = 0;   // Indicador de dado válido
  reg [2:0]     r_SM_Main     = 0;   // Estado da máquina de estados

  // Propósito: Registrar duas vezes os dados de entrada.
  always @(posedge i_Clock)
    begin
      r_Rx_Data_R <= i_Rx_Serial; // Registrar a entrada serial atual
      r_Rx_Data   <= r_Rx_Data_R; // Registrar a entrada serial anterior
    end

  // Propósito: Controlar a máquina de estados de RX
  always @(posedge i_Clock)
    begin

      case (r_SM_Main)
        s_IDLE :
          begin
            r_Rx_DV       <= 1'b0; // Redefinir o indicador de dado válido
            r_Clock_Count <= 0;    // Redefinir o contador de ciclos de clock
            r_Bit_Index   <= 0;    // Redefinir o índice do bit

            if (r_Rx_Data == 1'b0) // Se o bit de início foi detectado
              r_SM_Main <= s_RX_START_BIT;
            else
              r_SM_Main <= s_IDLE; // Caso contrário, permanecer no estado de espera
          end

        // Verificar o meio do bit de início para garantir que ainda está em nível baixo
        s_RX_START_BIT :
          begin
            if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
              begin
                if (r_Rx_Data == 1'b0)
                  begin
                    r_Clock_Count <= 0;  // Redefinir o contador, encontrou o meio
                    r_SM_Main     <= s_RX_DATA_BITS; // Avançar para a leitura dos dados
                  end
                else
                  r_SM_Main <= s_IDLE; // Caso contrário, voltar ao estado de espera
              end
            else
              begin
                r_Clock_Count <= r_Clock_Count + 1; // Continuar verificando
                r_SM_Main     <= s_RX_START_BIT;
              end
          end // Caso: s_RX_START_BIT

        // Aguardar CLKS_PER_BIT-1 ciclos de clock para amostrar os dados seriais
        s_RX_DATA_BITS :
          begin
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1; // Continuar a contagem dos ciclos de clock
                r_SM_Main     <= s_RX_DATA_BITS;
              end
            else
              begin
                r_Clock_Count          <= 0; // Redefinir o contador
                r_Rx_Byte[r_Bit_Index] <= r_Rx_Data; // Armazenar o bit de dado

                // Verificar se todos os bits foram recebidos
                if (r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index + 1; // Avançar para o próximo bit
                    r_SM_Main   <= s_RX_DATA_BITS;
                  end
                else
                  begin
                    r_Bit_Index <= 0; // Redefinir o índice do bit
                    r_SM_Main   <= s_RX_STOP_BIT; // Aguardar o bit de parada
                  end
              end
          end // Caso: s_RX_DATA_BITS

        // Receber o bit de parada. Bit de parada = 1
        s_RX_STOP_BIT :
          begin
            // Aguardar CLKS_PER_BIT-1 ciclos de clock para finalizar o bit de parada
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1; // Continuar a contagem dos ciclos de clock
                r_SM_Main     <= s_RX_STOP_BIT;
              end
            else
              begin
                r_Rx_DV       <= 1'b1; // Indicar que um byte válido foi recebido
                r_Clock_Count <= 0;    // Redefinir o contador
                r_SM_Main     <= s_CLEANUP; // Realizar a limpeza
              end
          end // Caso: s_RX_STOP_BIT

        // Permanecer aqui por 1 ciclo de clock
        s_CLEANUP :
          begin
            r_SM_Main <= s_IDLE; // Voltar ao estado de espera
            r_Rx_DV   <= 1'b0;   // Redefinir o indicador de dado válido
          end

        default :
          r_SM_Main <= s_IDLE; // Tratar estados não reconhecidos como s_IDLE

      endcase
    end

  assign o_Rx_DV   = r_Rx_DV;    // Atribuir o indicador de dado válido à saída
  assign o_Rx_Byte = r_Rx_Byte; // Atribuir o byte de dados à saída

  endmodule // uart_rx
