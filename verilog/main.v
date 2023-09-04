module main(dht_data, rx_uart, tx_uart, clock);
    inout dht_data;
    input rx_uart;
    input clock;
    output tx_uart;

    //Fios necessários para uso no projeto
    wire rx_done, tx_active, transmission_occurring, tx_done;
    wire [7:0] rx_info, info_for_send;

    //modulo que recebe a informação da comunicação serial
    /*
    input        i_Clock,
    input        i_Rx_Serial, // Pino de Entrada do RX
    output       o_Rx_DV, // Saída para indicar se o dado já foi recebido
    output [7:0] o_Rx_Byte // Saida do dado recebido
    */
    uart_rx data_receiver (clock, rx_uart, rx_done, rx_info);









    //modulo que envia a informação para a comunicação serial
    /*
        input       i_Clock,
        input       i_Tx_DV, // Bit para que o TX comece a transmitir 
        input [7:0] i_Tx_Byte, // Dado que deve ser transmitido 
        output      o_Tx_Active, // Bit para indicar se a transmissão está ativa
        output reg  o_Tx_Serial, // Saida serial para envio do dado
        output      o_Tx_Done // Bit para indicar que a transmissão foi finalizada
    
    */
    uart_tx data_sender (clock, tx_active, info_for_send, transmission_occurring, tx_uart, tx_done);



endmodule 