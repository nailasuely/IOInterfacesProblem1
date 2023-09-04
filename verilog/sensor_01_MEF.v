module sensor_01_MEF(clock, request, dht_data, information, tx_uart, transmission_ocurring, tx_done,ve);
    input clock; //entrada de clock
    input [1:0] request;    //entrada recebida pela maquina principal, sobre a requisição desejada
    inout dht_data; //entrada e saida dos dados recebidos pelo sensor
    output reg [7:0] information; //saida para a outra maquina de estados
	 output tx_uart, ve;
	 output transmission_ocurring, tx_done;

    localparam [1:0] s_idle = 2'b00, s_receiver_data = 2'b01, s_error_sensor = 2'b10, s_send_data = 2'b11;
	

    reg [1:0] choose_case;
	 reg fineshed;
	 reg [7:0] info;
	 reg vermelho;

    wire [7:0] hum_int, hum_float, temp_int, temp_float, check_sum;
    wire readout_done, wait_sensor, debug_sensor, error_sensor;
	 
    
    reg enable_sensor, rst_sensor;
    DHT11 dht11_comunication (clock, enable_sensor, rst_sensor, dht_data, hum_int, hum_float, temp_int, temp_float, check_sum, wait_sensor, debug_sensor, error_sensor, readout_done);
	 uart_tx data_sender (clock, fineshed, info, transmission_occurring, tx_uart, tx_done);

    always @(posedge clock)
        begin
            case(choose_case)
                s_idle:
                    begin
                        if(request == 2'b01)
                            begin
										vermelho = 1'b0;
										fineshed =1'b0;
                                enable_sensor <= 1'b1; // Ativa o sensor
                                rst_sensor <= 1'b1; // Dar-se um sinal de rst para iniciar a obtenção de dados
                                choose_case <= s_receiver_data;
                            end
                        else
                            begin
                                //possa ser que precise informar que o request chegou errado
                                choose_case <= s_idle;
                            end
                    end   
                s_receiver_data:
                    
                    begin
								rst_sensor <=1'b0;
                        if(readout_done == 1'b1)
                            begin
                                        if(request == 2'b00)
                                            begin
                                                information <=hum_int;
																vermelho = 1'b1;
                                                information <= temp_int;
																info <=temp_int;
																fineshed = 1'b1;
                                            end
                                        if(request <= 2'b01)
                                            begin
																vermelho = 1'b1;
                                                information <= temp_int;
																info <=temp_int;
																fineshed = 1'b1;
																
                                            end
                                        if(request <= 2'b10)
                                            begin
                                                if(error_sensor == 1'b0) //sem error, sensor normal
                                                        begin
                                                            information <= 8'b00000000;
                                                        end
                                                else //sensor com problema
                                                        begin 
                                                            information <= 8'b11111111;
                                                        end
                                            end
                            end
							  else
									begin
										 choose_case <=s_idle;
									end
                    end
                s_error_sensor:
                    begin
                    
                    end
                s_send_data:
                    begin
                    
                    end
                default: 
                    choose_case <= s_idle;
					endcase
			end

assign ve =vermelho;

endmodule 