#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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
            "│    6    │   Desativa sensoriamento contínuo de umidade.    │\n"
            "│    7    │   Desativa sensoriamento contínuo de temperatura.│\n"
            "│    0    │   Sair.                                          │\n"
            "└─────────┴──────────────────────────────────────────────────┘\n");
    printf("Escolha uma das opções: ");
}


int main (){
    int fd, len;
    unsigned char text[255];
    int sensorSelecionado = 0; // Armazena a opção do sensor selecionado pelo usuário
    int comandoSelecionado = -1; // Armazena a opção de comando selecionado pelo usuário

    struct termios options;
    
    char codigoSituacao[] = "0"; // Código para a situação atual do sensor
    char codigoTemperatura[] = "1"; // Código para a medida de temperatura
    char codigoUmidade[] = "2"; // Código para a medida de umidade

    char ativaContinuoTemperatura[] = "3"; // Ativa sensoriamento contínuo de temperatura
    char ativaContinuoUmidade[] = "4"; // Ativa sensoriamento contínuo de umidade

    char desativaContinuoUmidade[] = "5"; // Desativa sensoriamento contínuo de umidade
    char desativaContinuoTemperatura[] = "6"; //    Ativa sensoriamento contínuo de temperatura



    fd = open("/dev/ttyS0", O_WRONLY); // Abra a porta serial para escrita
     if (fd < 0) {
        perror("Erro ao abrir a porta serial");
        return -1;
    }
    
    tcgetattr(fd, &options);

    
    options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;

    /*
    * A taxa de transmissão da porta serial é definida como 9600 bauds por segundo.
    * Estão sendo usados 8 bits de dados por caractere.
    * A detecção de sinais de modem (como DCD) está desativada.
    * A porta serial está configurada para receber dados.
    */

    options.c_iflag = IGNPAR;
    options.c_oflag = 0;
    options.c_lflag = 0;


    tcflush(fd, TCIFLUSH);
    tcsetattr(fd, TCSANOW, &options);

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
                printf("\nComando escolhido: Situação atual do sensor.\n");
                break;
            case 2:
                strcpy(codigoRequisicao, codigoTemperatura);
                printf("\nComando escolhido: Medida de temperatura.\n");
                break;
            case 3:
                strcpy(codigoRequisicao, codigoUmidade);
                printf("\nComando escolhido: Medida de umidade.\n");
                break;
            case 4:
                strcpy(codigoRequisicao, ativaContinuoUmidade);
                printf("\nComando escolhido: Ativa sensoriamento contínuo de umidade.\n");
                break;
            case 5:
                strcpy(codigoRequisicao, ativaContinuoTemperatura);
                printf("\nComando escolhido: Ativa sensoriamento contínuo de temperatura.\n");
                break;
            case 6:
                strcpy(codigoRequisicao, desativaContinuoTemperatura);
                printf("\nComando escolhido: Desativa sensoriamento contínuo de temperatura.\n");
                break;
            case 7:
                strcpy(codigoRequisicao, desativaContinuoUmidade);
                printf("\nComando escolhido: Desativa sensoriamento contínuo de umidade.\n");
                break;
            case 0:
                printf("Saindo...");
                break;
            default:
                tabela();
                scanf("%i", &comandoSelecionado);
        }

        strcpy(text, codigoRequisicao);
        len = strlen(text);
        len = write(fd, text, len);
        printf("Voce enviou %d bytes para UART. \n", len);
        
        printf("Aguarde 5 segundos\n");
        

        // Isso aqui vai depender do código verilog. Trocar tempo depois
        sleep(5);


    }while(comandoSelecionado != 0);
    close(fd);
}
