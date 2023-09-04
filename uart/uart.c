#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

void enviarDadosUART(char *dados, int uart_fd)
{
    if (uart_fd != -1)
    {
        write(uart_fd, dados, strlen(dados));
    }
    else
    {
        perror("\nFalha para abrir o arquivo");
    }
}
// Função para receber dados da UART
void receberDadosUART(int uart_fd, char *dadosRecebidos) {
    int tamanho_rx;
    unsigned char byte1[9];
    unsigned char byte2[9];

    if (uart_fd != 0) {
        // Leitura do primeiro byte
        tamanho_rx = read(uart_fd, (void *)byte1, 8);
        if (tamanho_rx < 0) {
            perror("\nOcorreu um erro na leitura do primeiro byte");
        } else if (tamanho_rx == 0) {
            printf("\nNenhum dado lido do primeiro byte\n");
        } else {
            // Adiciona o caractere nulo ao final dos dados lidos e copia para dadosRecebidos
            byte1[tamanho_rx] = '\0';
            strcpy(dadosRecebidos, byte1);
        }
        sleep(8); // Aguarda 1 segundo

        // Leitura do segundo byte
        tamanho_rx = read(uart_fd, (void *)byte2, 8);
        if (tamanho_rx < 0) {
            perror("\nOcorreu um erro na leitura do segundo byte");
        } else if (tamanho_rx == 0) {
            printf("\nNenhum dado lido do segundo byte\n");
        } else {
            // Adiciona o caractere nulo ao final dos dados lidos e os anexa aos dadosRecebidos
            byte2[tamanho_rx] = '\0';
            strcat(dadosRecebidos, byte2);
        }
    } else {
        perror("\nFalha na abertura do arquivo");
    }
}

int main()
{
    int uart_fd = 0;
    int sensorSelecionado = 0; // Armazena a opção do sensor selecionado pelo usuário

     sensorSelecionado = 1;
    //Indica que o sensor escolhido foi o DHT11, posteriormente isso pode ser
    // perguntado para o usuário.

    int comandoSelecionado = 0; // Armazena a opção de comando selecionado pelo usuário
    char respostaComando[9]; // Armazena a resposta do comando lida pela UART


    char codigoSituacao[] = "0x00"; // Código para a situação atual do sensor
    char codigoTemperatura[] = "0x01 "; // Código para a medida de temperatura
    char codigoUmidade[] = "0x02"; // Código para a medida de umidade

    char ativaContinuoTemperatura[] = "0x03"; // Ativa sensoriamento contínuo de temperatura
    char ativaContinuoUmidade[] = "0x04"; // Ativa sensoriamento contínuo de umidade

    char desativaContinuoUmidade[] = "0x05"; // Desativa sensoriamento contínuo de umidade
    char desativaContinuoTemperatura[] = "0x06"; //    Ativa sensoriamento contínuo de temperatura




    uart_fd = open("/dev/ttyS0", O_RDWR | O_NDELAY | O_NOCTTY);

     // Verifica se a abertura da porta ocorreu de forma correta
     if (uart_fd == 0) {
         perror("Error opening serial port");
         return -1;
     }

    struct termios options;
    tcgetattr(uart_fd, &options);
    options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
    options.c_iflag = IGNPAR;
    options.c_oflag = 0;
    options.c_lflag = 0;
    tcflush(uart_fd, TCIFLUSH);
    tcsetattr(uart_fd, TCSANOW, &options);

    //MENU

            printf("Bem-vindo ao Sistema de Sensor\n");
            printf("Escolha uma das opções abaixo:\n");
            printf("1 - Situação atual do sensor.\n");
            printf("2 - Medida de temperatura.\n");
            printf("3 - Medida de umidade.\n");
            printf("4 - Ativa sensoriamento contínuo de umidade.\n");
            printf("5 - Desativa sensoriamento contínuo de temperatura.\n");
            printf("6 - Desativa sensoriamento contínuo de umidade.\n");
            printf("0 - Sair.\n");
            printf("Digite o número correspondente à sua escolha: ");
            scanf("%i", &comandoSelecionado);
        while (comandoSelecionado < 0 || comandoSelecionado > 6)
        {
            printf("Bem-vindo ao Sistema de Sensor\n");
            printf("Escolha uma das opções abaixo:\n");
            printf("1 - Situação atual do sensor.\n");
            printf("2 - Medida de temperatura.\n");
            printf("3 - Medida de umidade.\n");
            printf("4 - Ativa sensoriamento contínuo de umidade.\n");
            printf("5 - Ativa sensoriamento contínuo de temperatura.\n");
            printf("6 - Desativa sensoriamento contínuo de temperatura.\n");
            printf("7 - Desativa sensoriamento contínuo de umidade.\n");
            printf("0 - Sair.\n");
            printf("Digite o número correspondente à sua escolha: ");
            scanf("%i", &comandoSelecionado);
        }


        char codigoRequisicao[9];
        switch (comandoSelecionado)
        {
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
            break;
        case 5:
            strcpy(codigoRequisicao, ativaContinuoTemperatura);
            break;
        case 6:
            strcpy(codigoRequisicao, desativaContinuoTemperatura);
            break;
        case 7:
            strcpy(codigoRequisicao, desativaContinuoUmidade);
            break;
	case 0:
            printf("Saindo...");
            break;
        default:
            printf("Bem-vindo ao Sistema de Sensor\n");
            printf("Escolha uma das opções abaixo:\n");
            printf("1 - Situação atual do sensor.\n");
            printf("2 - Medida de temperatura.\n");
            printf("3 - Medida de umidade.\n");
            printf("4 - Ativa sensoriamento contínuo de umidade.\n");
            printf("5 - Ativa sensoriamento contínuo de temperatura.\n");
            printf("6 - Desativa sensoriamento contínuo de temperatura.\n");
            printf("7 - Desativa sensoriamento contínuo de umidade.\n");
            printf("0 - Sair.\n");
            printf("Digite o número correspondente à sua escolha: ");
            scanf("%i", &comandoSelecionado);
        }

        printf("\nAguarde um pouco\n");
        enviarDadosUART(codigoRequisicao, uart_fd);
        sleep(8);



        char dadoResposta[9];
        int tamanho_rx;
        if (uart_fd != -1)
        {
            tamanho_rx = read(uart_fd, (void *)respostaComando, 8);
            if (tamanho_rx < 0)
            {
                perror("\nOcorreu um erro na leitura de dados");
            }
            else if (tamanho_rx == 0)
            {
                printf("\nNenhum dado lido\n");
            }
            else
            {
                respostaComando[tamanho_rx] = '\0';
                if (strcmp(respostaComando, "0x1F") == 0)
                {
                    printf("\nO sensor está com problema\n");
                }
                else if (strcmp(respostaComando, "0x07") == 0)
                {
                    printf("\nO sensor está funcionando corretamente\n");
                }
                else if (strcmp(respostaComando, "0x08") == 0)
                {
                    printf("\nMedida de umidade");
                    receberDadosUART(uart_fd, dadoResposta);
                    printf("%s\n", dadoResposta);
                }
                else if (strcmp(respostaComando, "0x09") == 0)
                {
                    printf("\nMedida de temperatura");
                    receberDadosUART(uart_fd, dadoResposta);
                    printf("%s\n", dadoResposta);

                }
                else
                {
                    printf("\nO formato do dado não é compreensível. \n");
                    printf("%i\n", tamanho_rx);
                    //receberDadosUART(uart_fd, dadoResposta);
                    printf("%s\n", dadoResposta);
                    printf("%s\n", respostaComando);
                }
            }
        }
        else
        {
            perror("\nErro para abrir arquivo");
        }

    close(uart_fd);
    return 0;
}




