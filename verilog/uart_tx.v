  /*
    Módulo TX

    Este módulo é responsável pela transmissão de dados através de uma porta UART.
    Ele opera em quatro estados: IDLE, START, DATA e STOP.
    Durante a transmissão, ele envia os bits de dados com a taxa de baud especificada.
    (50,000,000 / 9,600 = 5208)
    */
module uart_tx #(
    parameter CLKS_PER_BIT = 5208
) (
    input        clk,
    input        initial_data,
    input  [7:0] data_transmission,
    output reg   out_tx,
    output reg   done
);

    // ──── ESTADOS DA MÁQUINA DE ESTADOS DA UART ────
    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    // ──── REGISTRADORES INTERNOS ────
    reg [1:0]  state = 0;
    reg [12:0] counter = 0;
    reg [2:0]  bit_index = 0;
    reg [7:0]  data_bit = 0;


    // ──── Lógica de transição de estados ────
    always @(posedge clk) begin
        case (state)
            // ESPERA:
            // Inicializa as variáveis e espera por dados a serem enviados.
            IDLE: begin
                out_tx    = 1;
                done      = 0;
                counter   = 0;
                bit_index = 0;

                // Verifica se há dados a serem enviados.
                if (initial_data == 1) begin

                    data_bit  <= data_transmission;
                    state <= START;
                end
                else begin
                    state <= IDLE;
                end
            end
            //Estado de início da transmissão:
            // Inicializa as variáveis e envia o bit de start.
            START: begin

                out_tx <= 0;
                done <= 0;
                bit_index = 0;

                if (counter < CLKS_PER_BIT - 1) begin
                    counter <= counter + 13'b1;
                    state <= START;
                end
                else begin
                    counter <= 0;
                    state <= DATA;
                end
            end
            // Estado de transmissão de dados:
            // Envia os bits de dados.
            DATA: begin

                done <= 0;
                out_tx <= data_bit[bit_index];

                if (counter < CLKS_PER_BIT - 1) begin
                    counter <= counter + 13'b1;
                    state <= DATA;
                end
                else begin
                    counter <= 13'd0;
                    if (bit_index >= 7) begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                    else begin
                        bit_index <= bit_index + 1'b1;
                        state <= DATA;
                    end
                end
            end
            // Estado de parada da transmissão:
            // Envia o bit de stop e conclui a transmissão.
            STOP: begin
                out_tx <= 1;
                bit_index = 0;

                if (counter < CLKS_PER_BIT - 1) begin
                    counter <= counter + 13'b1;
                    state <= STOP;
                end
                else begin
                    done <= 1;
                    state <= IDLE;

                    counter <= 0;
                end
            end
            // Estado padrão (caso de erro):
            // Retorna ao estado de ociosidade e limpa variáveis.
            default: begin
                state <= IDLE;
                out_tx = 1;
                done = 0;
                counter = 0;
                bit_index = 0;
                end
        endcase
    end

endmodule