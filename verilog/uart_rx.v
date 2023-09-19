/*
Este módulo Verilog descreve uma máquina de recebimento UART
que é responsável por receber dados seriais em uma placa com um clock de 50 MHz
e taxa de baud de 9600.
*/

module uart_rx #(
    parameter CLKS_PER_BIT = 5208 // (50,000,000 / 9,600 = 5208)
)(
    input  clk,  // Entrada: Clock da placa a 50 MHz
    input  input_rx, // Entrada: Dados recebidos pela porta serial
    output done, // Saída: Sinalizado quando um dado foi recebido completamente
    output [7:0] out_rx  // Saída: Dados de saída completos
);

    // ──── Definição dos estados da máquina de recebimento UART ─────
    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    // ──── Declaração dos registradores internos ─────
    reg data_serial_buffer = 1'b1;
    // Registrador para armazenar o dado recebido
    reg rx_data            = 1'b1;
    // Registrador para registrar o estado da máquina de recebimento
    reg [1:0]  state       = 1'b0;
    // Contador de tempo usado para determinar a taxa de baud
    reg [12:0] counter     = 13'd0;
    // Índice do bit atual sendo recebido
    reg [2:0]  bit_index   = 1'b0;
    // Flag para sinalizar quando um dado está disponível para saída
    reg        data_avail  = 1'b0;
    // Registrador para armazenar o byte de dados recebido
    reg [7:0]  data_reg    = 1'b0;

   // ────  Declaração das saídas ────
    assign out_rx = data_reg;
    assign done = data_avail;

    always @(posedge clk) begin
        data_serial_buffer <= input_rx;
        rx_data            <= data_serial_buffer;
    end

    // ──── Lógica de transição de estados ────
    always @(posedge clk) begin
        case (state)
            IDLE:begin

                data_avail <= 0;
                counter    <= 13'd0;
                bit_index  <= 3'b000;
                // Verifica se o sinal de entrada é baixo para iniciar a recepção.
                if (rx_data == 0)
                    state <= START;
                else
                    state <= IDLE;
            end
            // Estado de início (start)
            START: begin
                data_avail   <= 0;
                bit_index    <= 3'b000;
                // Verifica se o contador atingiu metade do período do bit.
                if (counter == (CLKS_PER_BIT - 1) / 2) begin
                    counter <= 13'd0;
                     // Verifica se o sinal de entrada permanece baixo para continuar a recepção.
                    if (rx_data == 0) begin
                        state <= DATA;
                    end
                    else
                        state <= IDLE;
                end
                else begin
                    counter <= counter + 13'b1;
                    state   <= START;
                end
            end

            DATA: begin
                data_avail <= 0;
                // Incrementa o contador de tempo e permanece no estado de recepção de dados.
                if (counter < CLKS_PER_BIT - 1) begin
                    counter <= counter + 13'b1;
                    state   <= DATA;
                end
                else begin
                    counter             <= 13'd0;
                    data_reg[bit_index] <= rx_data;

                    if (bit_index >= 7) begin
                        // Zerar o índice do bit e ir para o estado de parada
                        bit_index <= 3'b000;
                        state <= STOP;
                    end
                    else
                    begin
                        // Incrementa o contador de tempo e permanece no estado de início.
                        bit_index <= bit_index + 3'b1;
                        state <= DATA;
                    end
                end
            end

            // Estado de parada
            STOP:begin
                data_avail <= 1;
                bit_index <= 3'b000;

                if (counter >= CLKS_PER_BIT - 1) begin
                    counter <= 13'd0;
                    state <= IDLE;
                end
                else begin
                    counter <= counter + 13'b1;
                    state <= STOP;
                end
            end

            // Estado padrão (caso de erro)
            // Basicamente ele retorna ao estado de idle e limpa variáveis.
            default: begin
                state <= IDLE;
                data_avail <= 0;
                counter    <= 13'd0;
                bit_index  <= 0;
            end
        endcase
    end

endmodule