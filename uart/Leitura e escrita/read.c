#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <math.h>
#include <termios.h>


int main(){
	
	int fd, len;
	unsigned char text[255]; //uma boa seria restringir a quantidade de bits


	int leitura = 1;
	struct termios options; // Serial ports setting 


	fd = open("/dev/ttyS0", O_RDONLY);
	if (fd < 0) {
		perror("Erro para abrir a porta serial");
		return -1;
	}


	options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
	options.c_iflag = IGNPAR;
	options.c_oflag = 0;
	options.c_lflag = 0;

	tcflush(fd, TCIFLUSH);
	tcsetattr(fd, TCSANOW, &options);
    
	while(leitura){
 
		memset(text, 0, 255);
        len = read(fd, text, 255);

		// Saídas baseadas no comando recebido

        //Formata isso aqui conforme o comando recebido
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
                    printf("\nMedida de umidade: ");
                    printf("Quantidade de bytes recebidos: %d \n", len);
                    // Itera sobre os bytes e imprime apenas os bytes do código de protocolo e da temperatura
                    for (int i = 0; i < len; i++) {
                        // Código de protocolo
                        if (i == 0) {
                            printf("0x%02x - Código de protocolo\n", text[i]);
                        }

                        // Temperatura
                        if (i == 2) {
                            printf("Umidade: %d \n", text[i]);
                        }
                    }
                } else if (text[0] == 0x09) {
                    printf("\nMedida de temperatura: ");
                    for (int i = 0; i < len; i++) {
                        // Código de protocolo
                        if (i == 0) {
                            printf("0x%02x - Código de protocolo\n", text[i]);
                        }
                        // Temperatura
                        if (i == 2) {
                            printf("Temperatura: %d \n", text[i]);
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
                    for (int i = 0; i < len; i++) {
                        // Código de protocolo
                        if (i == 0) {
                            printf("0x%02x - Código de protocolo\n", text[i]);
                        }
                        // Temperatura
                        if (i == 2) {
                            printf("Temperatura: %d \n", text[i]);
                        }
                    }
                } else if (text[0] == 0xFE) {
                    printf("\nMedida de umidade contínua\n");
                    for (int i = 0; i < len; i++) {
                        // Código de protocolo
                        if (i == 0) {
                            printf("0x%02x - Código de protocolo\n", text[i]);
                        }

                        // Temperatura
                        if (i == 2) {
                            printf("Umidade: %d \n", text[i]);
                        }
                    }
                } else if (text[0] == 0xFC) {
                    printf("\nByte secundário para complementar o byte primário\n");
                } else if (text[0] == 0xFB) {
                    printf("\nComando inválido\n"); 
                } else {
                    printf("\n\nErro no formato de dado recebido\n");
                }
            }}
        
		
		sleep(5);

	}

	close(fd);// Fecha a porta
    return 0;
}