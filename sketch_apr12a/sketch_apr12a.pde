#include <stdlib.h>
#include <stdarg.h>

volatile long encoder0Pos = 0;
volatile long encoder1Pos = 0;
volatile char lasta0;
volatile char lasta1;

void p(char *fmt, ... ){
        char tmp[256];
        va_list args;
        va_start (args, fmt );
        vsnprintf(tmp, 256, fmt, args);
        va_end (args);
        Serial.print(tmp);
}


void setup() {
  
  // set up pins
  // for arduino mega port/pin assignments, see: http://farm4.static.flickr.com/3321/3495394293_0d2c81798c_b.jpg
  // we're using:
  // portc, lowest 6 bits for motor control outputs
  // portl, lowest 4 bits for encoder inputs
 
    DDRL = B00000000;  // set port l as inputs
    PORTL= B11111111;  // turn on all pullup resistors

    DDRC = B11111111;  // set port c as outputs
    PORTC= B00000000;  // all stop

   // set up serial
  
    Serial.begin(115200);
    Serial.println("start");

//  Serial.println(digitalPinToPort(21), DEC);
//  Serial.println(digitalPinToBitMask(21), DEC);

}


void loop() {



//  int val= analogRead(2);
//  unsigned int cycleMicroseconds= 8000;  // little more than 60hz = 16300
  
//  Serial.println(val);
//  PORTA= (val > 512) ? B00000001 : B00000011;
  
//  float dutycycle= ((float)abs(512-val))/((float)512);
//  unsigned int onMicroseconds= dutycycle*cycleMicroseconds;
//  unsigned int offMicroseconds= cycleMicroseconds-onMicroseconds;



 /*  Serial.print(val);
   Serial.print("\t");
   Serial.print(dutycycle);
   Serial.print("\t");
   Serial.print(onMicroseconds);
   Serial.print("\t");
   Serial.print(offMicroseconds);
   Serial.println();*/

  
   char driveByte= 0;
    PORTC= B00000000;  // force stop

  unsigned char cmdLen= 0;
  char cmdBuf[256];
  
  long xTarget= 0;
  long yTarget= 0;
 
             long cmdPos, posMultiplier;
            long pos= 0;

  
 loop1:
    
   while(Serial.available() < 1){ // any key
    encoderDelayMs(5);  // read encoder!
  }
  
      char incomingByte = Serial.read();
      cmdBuf[cmdLen++]= incomingByte;
      cmdBuf[cmdLen]= 0;
  
      if (cmdBuf[cmdLen-1] == '\\') {
        p("got command: %s\n", cmdBuf);
        
        // act on command
        
        switch(cmdBuf[0]) {
          case 'x':  // set x target

            pos= 0;
          
            if(cmdBuf[1] == '-') {
               cmdPos= 2;
               posMultiplier= -1;
            }
            else {
                cmdPos= 1;
                posMultiplier= 1;
            }
            
            for(;cmdBuf[cmdPos] != '\\';cmdPos++) {
               if((cmdBuf[cmdPos] < '0') || (cmdBuf[cmdPos] > '9'))
                 continue;
               pos*= 10;
               pos+= cmdBuf[cmdPos]-'0';
            }
            pos*= posMultiplier;
            
            p("xTarget: %d\n", pos);

            xTarget= pos;
          break;
          
          case 'y':  // set y target

            pos= 0;
          
            if(cmdBuf[1] == '-') {
               cmdPos= 2;
               posMultiplier= -1;
            }
            else {
                cmdPos= 1;
                posMultiplier= 1;
            }
            
            for(;cmdBuf[cmdPos] != '\\';cmdPos++) {
               if((cmdBuf[cmdPos] < '0') || (cmdBuf[cmdPos] > '9'))
                 continue;
               pos*= 10;
               pos+= cmdBuf[cmdPos]-'0';
            }
            pos*= posMultiplier;
            
            p("yTarget: %d\n", pos);

            yTarget= pos;
          break;

          case 'g':  // xy go

            p("target: %ld, %ld\n", xTarget, yTarget);
            p("pos start: %ld, %ld\n", encoder0Pos, encoder1Pos);
            encoderMoveTo(xTarget, yTarget);
            PORTC= B00000000;  // safety stop
            p("pos end: %ld, %ld\n", encoder0Pos, encoder1Pos);
                 
          break;
          
          case 'i':  // z up 5ms         
            PORTC= B11000000;
             encoderDelayMs(5);         
            PORTC= B00000000;
             encoderDelayMs(5);
          break;

          case 'k':  // z down 5ms         
            PORTC= B01000000;
             encoderDelayMs(5);         
            PORTC= B00000000;
             encoderDelayMs(5);
          break;
          
          case 'c':  // circle!
          
            long xStart= encoder0Pos;
            long yStart= encoder1Pos;
          
            for(int x= 0; x <= 20; x++) {
              double pi= 3.14159;
              
              long xFun= sin((2*pi*x)/20)*2000;
              long yFun= cos((2*pi*x)/20)*2000;
              
               p("%d: %d, %d (diff: %d, %d)\n", x, xStart+xFun, yStart+yFun, xFun, yFun);
               
               encoderMoveTo(xStart+xFun, yStart+yFun);
            }
          break;

        }
        
        cmdLen= 0;
      }   
      
//       Serial.print("got keypress: ");
//       Serial.println(incomingByte);
          
  goto loop1;
}

void encoderMoveTo(long encoder0Target, long encoder1Target) {


  char driveByte;
      
cli();  // disable interrupts
  
unsigned long tickCount, driveTickCount;

  char a1,b1;


  for(driveTickCount= 0; driveTickCount < 100000; driveTickCount++) {
 
      driveByte= 0;
  
    if(encoder1Target > encoder1Pos)
      driveByte|= B00000100;
    else if(encoder1Target < encoder1Pos)
      driveByte|= B00001100;
  
    if(encoder0Target > encoder0Pos)
      driveByte|= B00110000;
    else if(encoder0Target < encoder0Pos)
      driveByte|= B00010000;

    PORTC= driveByte;
    
    
   // read encoder 0
 
    char a0= PINL & B00000001;
    if(a0 != lasta0) {
     char b0= (PINL & B00000010)>>1;
     if (a0==b0)
        encoder0Pos--;
     else
        encoder0Pos++;
     lasta0= a0;
    }

  // read encoder 1

    a1= (PINL & B00000100)>>2;
    if(a1 != lasta1) {
     b1= (PINL & B00001000)>>3;
     if (a1==b1)
        encoder1Pos--;
     else
        encoder1Pos++;
     lasta1= a1;
   }
   
   if((encoder1Pos >= encoder1Target-200) && (encoder1Pos <= encoder1Target+200) &&
      (encoder0Pos >= encoder0Target-200) && (encoder0Pos <= encoder0Target+200))
      break;
      
  }
  
  // stop, allow to settle & re-read
  
  PORTC= B00000000;

  unsigned long lastMoveTick= 0;

  for(tickCount= 0; tickCount < 30000; tickCount++) {
 
   // read encoder 0
 
    char a0= PINL & B00000001;
    if(a0 != lasta0) {
     char b0= (PINL & B00000010)>>1;
     if (a0==b0)
        encoder0Pos--;
     else
        encoder0Pos++;
     lasta0= a0;
     lastMoveTick= tickCount;
    }

  // read encoder 1

    char a1= (PINL & B00000100)>>2;
    if(a1 != lasta1) {
     char b1= (PINL & B00001000)>>3;
     if (a1==b1)
        encoder1Pos--;
     else
        encoder1Pos++;
     lasta1= a1;
     lastMoveTick= tickCount;
   }
      
  }
  
  
 // }while(encoder0Pos > 0);

sei();      // re-enable interrupts
       p("drivebyte: %d, drive for %ld ticks, %ld ticks to settle (waited 30k)\n", driveByte, driveTickCount, lastMoveTick);  // print encoder position

}



void encoderDelayMs(unsigned long delayMs) {
  
  unsigned long stopMs= millis()+delayMs;

  do{
 
   // read encoder 0
 
    char a0= PINL & B00000001;
    if(a0 != lasta0) {
     char b0= (PINL & B00000010)>>1;
     if (a0==b0)
        encoder0Pos--;
     else
        encoder0Pos++;
     lasta0= a0;
    }

  // read encoder 1

    char a1= (PINL & B00000100)>>2;
    if(a1 != lasta1) {
     char b1= (PINL & B00001000)>>3;
     if (a1==b1)
        encoder1Pos--;
     else
        encoder1Pos++;
     lasta1= a1;
   }
   
  }while(millis() < stopMs);
 }


