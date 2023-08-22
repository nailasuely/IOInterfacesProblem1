module tristate(
    inout port,   
    input dir,    // Sinal de controle(0 para entrada, 1 para saída)
    input data_out,   // Dados a serem enviados para o pino de saída (quando dir = 1)
    output data_in  
);

assign port = (dir) ? data_out : 1'bz; // Quando dir é 1, copia data_out para port, caso contrário, define port como alta impedância (Z)
assign data_in = (dir) ? 1'bz : port; // Quando dir é 0, copia o valor de port para data_in, caso contrário, define data_in como alta impedância (Z)

endmodule
