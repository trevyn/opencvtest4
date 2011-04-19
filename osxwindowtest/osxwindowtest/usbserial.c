//
//  usbserial.c
//  osxwindowtest
//
//  Created by Eden on 4/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <stdio.h>   /* Standard input/output definitions */
#include <string.h>  /* String function definitions */
#include <unistd.h>  /* UNIX standard function definitions */
#include <fcntl.h>   /* File control definitions */
#include <errno.h>   /* Error number definitions */
#include <termios.h> /* POSIX terminal control definitions */

/* change this to your USB port Device Name*/
#define PORT "/dev/tty.usbserial-A7006QPR"  

void USBSerialGetline(char *buffer, int bufsize);
int  USBSerialInit();


/*
 ** this is just a sample c Main program.
 ** It reads lines and prints them
 */
//int main(int argc, char *argv[])
//{
//}  

int USBSerialInit()
{
    int fd;
    int i, j;
    struct termios options;
    
    /* open the USB Serial Port */
    fd = open(PORT, O_RDWR | O_NOCTTY | O_NDELAY);
    if (fd == -1)
    {
        perror("open_port: Unable to open serial port - ");
        return -1;
    }
    else fcntl(fd, F_SETFL, 0);
    /* set the port to 9600 Baud, 8 data bits, etc. */
    tcgetattr(fd, &options);
    cfsetispeed(&options, B115200);
    cfsetospeed(&options, B115200);
    options.c_cflag |= (CLOCAL | CREAD);
    options.c_cflag &= ~CSIZE; /* Mask the character size bits */
    options.c_cflag |= CS8;    /* Select 8 data bits */
    options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
    tcsetattr(fd, TCSANOW, &options);
    return fd;
}

/*
 ** this reads an entire line of text, up to a Newline
 ** and discards any Carriage Returns
 ** The resulting line has the Newline stripped and
 ** is null-terminated
 */
void USBSerialGetLine(int fd,char *buffer,int bufsize)
{
    char *bufptr;
    int nbytes;
    char inchar;
    
    bufptr = buffer;
    while ((nbytes = read(fd, &inchar, 1)) > 0)
    {
        if (inchar == '\r') continue;
        if (inchar == '\n') break;
        *bufptr = inchar;
        ++bufptr;
    }
    *bufptr = '\0';
}

