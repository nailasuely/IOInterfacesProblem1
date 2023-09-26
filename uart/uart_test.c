#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

void tabela(){
    printf("\n");
    printf( "┌─────────┬──────────────────────────────────────────────────┐\n"
            "│    1    │   Situação atual do sensor.                      │\n"
            "│    2    │   Medida de temperatura..                        │\n"
            "│    3    │   Medida de umidade.                             │\n"
            "│    4    │   Ativa sensoriamento contínuo de umidade.       │\n"
            "│    5    │   Ativa sensoriamento contínuo de temperatura.   │\n"
            "│    6    │   Desativa sensoriamento contínuo de umidade     │\n"
            "│    7    │   Desativa sensoriamento contínuo de temperatura.│\n"
            "│    0    │   Sair.                                          │\n"
            "└─────────┴──────────────────────────────────────────────────┘\n");
    printf("Escolha uma das opções: ");
}


int main()
{
    int fd, len;
    unsigned char text[255];

    int uart_fd = 0;
    int sensorSelecionado = 0; // Armazena a opção do sensor selecionado pelo usuário

    sensorSelecionado = 1;
    //Indica que o sensor escolhido foi o DHT11, posteriormente isso pode ser
    // perguntado para o usuário.

    int comandoSelecionado = -1; // Armazena a opção de comando selecionado pelo usuário
    unsigned char respostaComando[9]; // Armazena a resposta do comando lida pela UART


    char codigoSituacao[] = "0"; // Código para a situação atual do sensor
    char codigoTemperatura[] = "1"; // Código para a medida de temperatura
    char codigoUmidade[] = "2"; // Código para a medida de umidade

    char ativaContinuoTemperatura[] = "3"; // Ativa sensoriamento contínuo de temperatura
    char ativaContinuoUmidade[] = "4"; // Ativa sensoriamento contínuo de umidade

    char desativaContinuoUmidade[] = "5"; // Desativa sensoriamento contínuo de umidade
    char desativaContinuoTemperatura[] = "6"; //    Ativa sensoriamento contínuo de temperatura
    
    int leituraContinua = 0;


    //MENU
    do {
        tabela();
        scanf("%i", &comandoSelecionado);
        while (comandoSelecionado < 0 || comandoSelecionado > 8) {
            tabela();
            scanf("%i", &comandoSelecionado);
        }

        char codigoRequisicao[9];
        switch (comandoSelecionado) {
            case 1:
                strcpy(codigoRequisicao, codigoSituacao);
                break;
            case 2:
                strcpy(codigoRequisicao, codigoTemperatura);
                break;
            case 3:
                strcpy(codigoRequisicao, codigoUmidade);
                break;
            case 4:
                strcpy(codigoRequisicao, ativaContinuoUmidade);
                leituraContinua = 1; // Ativa leitura contínua
                break;
            case 5:
                strcpy(codigoRequisicao, ativaContinuoTemperatura);
                leituraContinua = 1; // Ativa leitura contínua
                break;
            case 6:
                strcpy(codigoRequisicao, desativaContinuoTemperatura);
                leituraContinua = 0; // Desativa leitura contínua
                break;
            case 7:
                strcpy(codigoRequisicao, desativaContinuoUmidade);
                leituraContinua = 0; // Desativa leitura contínua
                break;
            case 0:
                printf("Saindo...");
                break;
            default:
                tabela();
                scanf("%i", &comandoSelecionado);
        }
        
    if (leituraContinua) {
        while (comandoSelecionado != 6 && comandoSelecionado != 7) {
            fd = open("/dev/ttyS0", O_RDWR | O_NDELAY | O_NOCTTY);

            if (fd < 0) {
                perror("Erro ao abrir a porta serial");
                return -1;
            }

            // Configurações da porta serial
            struct termios options;
            tcgetattr(fd, &options);
            options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
            options.c_iflag = IGNPAR;
            options.c_oflag = 0;
            options.c_lflag = 0;
            tcflush(fd, TCIFLUSH);
            tcsetattr(fd, TCSANOW, &options);

            // Escreve o comando na porta serial
            strcpy(text, codigoRequisicao);
            len = strlen(text);
            len = write(fd, text, len);
            printf("\n Você enviou %d bytes para UART. \n", len);
            printf("Aguarde 7 segundos\n");

            sleep(7);

            // Lê a resposta da porta serial
            memset(text, 0, 255);
            len = read(fd, text, 255);

            printf("\n──────────────────────── Medida continua ────────────────────────");
                   printf("\n\n");
		    // Itera sobre os bytes e imprime apenas os bytes do código de protocolo e da temperatura
		    printf("\n");
		    for (int i = 0; i < len; i++) {
	         	// Código de protocolo
			if (i == 0) {
		        	printf("0x%02x - Código de protocolo\n", text[i]);
			  }
			// Temperatura
			if (i == 2) {
		           printf("%d - Temperatura ou Umidade  \n", text[i]);;
			 }
			}
	    printf("\n────────────────────────────────────────────────────────────────");
			
            close(fd);
            sleep(6); // Intervalo entre as leituras contínuas

            // Verifica se o usuário pressionou enter
            //printf("\nPressione enter para parar leitura continua\n");
            char caractere = getchar();
            while(caractere == 10) {
                leituraContinua = 0;
                comandoSelecionado = 0 ;
            }
            }
        }
    }
         else{
            fd = open("/dev/ttyS0", O_RDWR | O_NDELAY | O_NOCTTY);

        if (fd < 0) {
            perror("Erro par abrir a porta serial");
            return -1;
        }
        
		struct termios options;
        /* Read current serial port settings */
        tcgetattr(fd, &options);

        /* Set up serial port */
        options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
        options.c_iflag = IGNPAR;
        options.c_oflag = 0;
        options.c_lflag = 0;
        tcflush(fd, TCIFLUSH);
        tcsetattr(fd, TCSANOW, &options);

        /* Write to serial port */
        strcpy(text, codigoRequisicao);
        len = strlen(text);
        len = write(fd, text, len);
        printf("Voce enviou %d bytes para UART. \n", len);
        printf("Aguarde 7 segundos\n");
        
        sleep(7);

        /* Read from serial port */
        memset(text, 0, 255);
        len = read(fd, text, 255);
        
        // --------------------------------------------------------------------------------------------------
         if (fd != 0) {
            if (len < 0) {
                perror("\nOcorreu um erro na leitura de dados");
            } else if (len == 0) {
                printf("\nNenhum dado lido\n");
            } else {
                if (text[0] == 0x1F) {
                    printf("\nO sensor está com problema\n");
                } else if (text[0] == 0x07) {
                    printf("\nO sensor está funcionando corretamente\n");
                } else if (text[0] == 0x08) {
                    printf("\n──────────────────────── Medida de umidade ────────────────────────");
                    printf("\n");
                    for (int i = 0; i < len; i++) {
                        // Código de protocolo
                        if (i == 0) {
                                printf("0x%02x - Código de protocolo\n", text[i]);
                          }
                        // Temperatura
                        if (i == 2) {
                               printf("%d - Temperatura ou Umidade  \n", text[i]);;
                         }
                    }
                    printf("\n");
                } else if (text[0] == 0x09) {
                    printf("\n──────────────────────── Medida de temperatura ──────────────────────── ");
                    printf("\n\n");
                    for (int i = 0; i < len; i++) {
                        // Código de protocolo
                        if (i == 0) {
                            printf("0x%02x - Código de protocolo\n", text[i]);
                      }
                        // Temperatura
                        if (i == 2) {
                           printf("%d - Temperatura ou Umidade  \n", text[i]);;
                     }
			    }
                } else if (text[0] == 0x0A) {
                    printf("\nConfirmação de desativação de sensoriamento contínuo de temperatura\n");
                } else if (text[0] == 0x0B) {
                    printf("\nConfirmação de desativação de sensoriamento contínuo de umidade\n");
                } else if (text[0] == 0xF0) {
                    printf("\nConfirmação de recebimento da requisição\n");
                } else if (text[0] == 0xFD) {
                    printf("\nMedida de temperatura contínua\n");
                    printf("%s\n", text);
                } else if (text[0] == 0xFE) {
                    printf("\nMedida de umidade contínua\n");
                    printf("%s\n", text);
                } else if (text[0] == 0xFC) {
                    printf("\nByte secundário para complementar o byte primário\n");
                } else if (text[0] == 0xFB) {
                    printf("\nComando inválido\n"); 
                } else {
                    printf("\n\nErro no formato de dado recebido\n");
                }
            }}
        }
    }while(comandoSelecionado != 0);
    close(uart_fd);
    return 0;
}




