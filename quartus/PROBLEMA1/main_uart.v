module main_uart #(parameter CLKS_PER_BIT = 457) (
  input        i_Clock,
  input        i_Rx_Serial,
  output [7:0] o_Rx_Byte,
  output       o_Rx_DV,
  output       o_Tx_Active,
  output       o_Tx_Serial,
  output       o_Tx_Done
);
  wire        w_Rx_DV;
  wire [7:0]  w_Rx_Byte;
  wire        w_Tx_Active;
  wire        w_Tx_Serial;
  wire        w_Tx_Done;

  // Instanciando os módulos UART_RX e UART_TX
  uart_rx #(CLKS_PER_BIT) rx (
    .i_Clock(i_Clock),
    .i_Rx_Serial(i_Rx_Serial),
    .o_Rx_Byte(w_Rx_Byte),
    .o_Rx_DV(w_Rx_DV)
  );

  uart_tx #(CLKS_PER_BIT) tx (
    .i_Clock(i_Clock),
    .i_Tx_DV(w_Tx_Active),
    .i_Tx_Byte(w_Rx_Byte),
    .o_Tx_Active(w_Tx_Active),
    .o_Tx_Serial(w_Tx_Serial),
    .o_Tx_Done(w_Tx_Done)
  );

  // Reg para armazenar dados recebidos
  reg [7:0] r_Rx_Data;

  always @(posedge w_Rx_DV) begin
    r_Rx_Data <= w_Rx_Byte;
  end

  assign o_Rx_DV   = w_Rx_DV;
  assign o_Rx_Byte = r_Rx_Data;
  assign o_Tx_Active = w_Tx_Active;
  assign o_Tx_Serial = w_Tx_Serial;
  assign o_Tx_Done   = w_Tx_Done;
endmodule
