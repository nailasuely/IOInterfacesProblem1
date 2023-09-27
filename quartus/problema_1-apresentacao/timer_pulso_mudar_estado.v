module timer_pulso_mudar_estado (clock, activate, next_state);
    input clock; //entrada de clock 50MHz
	input activate; //entrada de ativação, para iniciar a contagem
    output reg next_state; //saida indicando que ja passou o tempo, e pode passar ao prox estado

    reg [30:0] counter = 30'd0; //registrador de contador

    always @(posedge clock)
        begin
            if(activate == 1'b1) //se tiver sinal pedindo para contagem
                begin 
                    if(counter == 30'd200000000) //contador que vai ate 4 segundos
                        begin
									//counter <= 27'd0;
                            next_state = 1'b1; //envia o sinal que pode passar para o prox estado
                        end
                    else //enquanto o contador nao terminar, continua contando, e impedindo de pasasar ao prox estado
                        begin
                            next_state =1'b0;
                            counter = counter + 1'b1;
                        end
                end
            else //enquanto nao houver sinal de ativação, permanece esse sinal desativado
                begin
                    next_state =1'b0;
						  counter <= 30'd0;
                end
        end

endmodule 