#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

int main() {
    int fd, len;
    char text[255];
    struct termios options;  //configuração das opções da porta serial.


    //  Porta serial em sistemas Linux
    fd = open("/dev/ttyS0", O_RDWR | O_NDELAY | O_NOCTTY);

    // Verifica se a abertura da porta ocorreu de forma correta
    if (fd < 0) {
        perror("Error opening serial port");
        return -1;
    }

    options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
    options.c_iflag = IGNPAR;
    options.c_oflag = 0;
    options.c_lflag = 0;

    tcflush(fd, TCIFLUSH);
    tcsetattr(fd, TCSANOW, &options);

    strcpy(text, "@");
    len = strlen(text);
    len = write(fd, text, len);
    printf("Wrote %d bytes over UART, this byte is: \n", len);

    printf("You have 5s to send me some input data...\n");
    sleep(5);

    // Fecha a porta serial:
    close(fd);

    return 0;
}
