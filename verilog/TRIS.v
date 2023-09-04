

module TRIS(
    inout PORT,
    input DIR,
    input SEND,
    output READ
    );

assign PORT = DIR ? SEND : 1'bZ; // Se DIR 1 -- copia DHT_OUT para saida, caso nao, deixa o pino indefinido para atuar como entrada
assign READ = DIR ?  1'bz : PORT;

endmodule
