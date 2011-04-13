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



//  for(int x=0; x< 40; x++) {     
//    PORTA= B00000011;
//         delay(15);
//    PORTA= B00000000;
//         delay(5);
//  }
//    PORTA= B00000000;

 //        delay(3000);
  
   char driveByte= 0;
    PORTC= B00000000;  // force stop

  unsigned char cmdLen= 0;
  char cmdBuf[256];
  
 loop1:
    
   while(Serial.available() < 1){ // any key
    encoderDelayMs(5);  // read encoder!
  }
  
      char incomingByte = Serial.read();
      cmdBuf[cmdLen++]= incomingByte;
      cmdBuf[cmdLen]= 0;
  
      if (cmdBuf[cmdLen-1] == 'x') {
        p("got command: %s\n", cmdBuf);
         cmdLen= 0;
      }   
      
       Serial.print("got keypress: ");
       Serial.println(incomingByte);

//  -- bad idea because i think this kills millis()


      switch(incomingByte) {
/*        case 'y':
          driveByte= B11000000;
         break;
        case 'h':
          driveByte= B01000000;
        break;
       case 'i':
          driveByte= B00110000;
         break;
        case 'k':
          driveByte= B00010000;
        break;
       case 'j':
          driveByte= B00001100;
         break;
        case 'l':
          driveByte= B00000100;
        break;*/
       }

      // run

        p("pos start: %ld, %ld\n", encoder0Pos, encoder1Pos);

      
//      for(int x= 0; x < 1; x++) {
        
//         PORTC= driveByte;
         encoder1MoveTo(5);
  
         PORTC= B00000000;  // stop
//      }
//       Serial.println (encoder0Pos, DEC);  // print encoder position
//jj
//Serial.println (encoder1Pos, DEC);  // print encoder position

        p("pos end: %ld, %ld\n", encoder0Pos, encoder1Pos);

///     
          
  goto loop1;
}

void encoder1MoveTo(long encoder1Target) {


  char driveByte;
  
  
  if(encoder1Target == encoder1Pos)
    return;

  char comingFromBelow= (encoder1Target > encoder1Pos);
  
  if( (encoder1Target > encoder1Pos))
    driveByte= B00000100;
  else
    driveByte= B00001100;
      
cli();  // disable interrupts
  
unsigned long tickCount, driveTickCount;

  char a1,b1,lasta1;

  PORTC= driveByte;

  for(driveTickCount= 0; driveTickCount < 10000; driveTickCount++) {
 
   // read encoder 0
 
    char a0= PINL & B00000001;  // pin 21
    if(a0 != lasta0) {
     char b0= (PINL & B00000010)>>1;  // pin 50
     if (a0==b0)
        encoder0Pos--;
     else
        encoder0Pos++;
     lasta0= a0;
    }

  // read encoder 1

    a1= (PINL & B00000100)>>2;  // pin 21
    if(a1 != lasta1) {
     b1= (PINL & B00001000)>>3;  // pin 50
     if (a1==b1)
        encoder1Pos--;
     else
        encoder1Pos++;
     lasta1= a1;
   }
   
   if(comingFromBelow) {
     if(encoder1Pos >= encoder1Target)
       break;
   }
   else {
     if(encoder1Pos <= encoder1Target)
       break;
   }
      
  }
  
  // stop, allow to settle & re-read
  
  PORTC= B00000000;

  unsigned long lastMoveTick= 0;

  for(tickCount= 0; tickCount < 30000; tickCount++) {
 
   // read encoder 0
 
    char a0= PINL & B00000001;  // pin 21
    if(a0 != lasta0) {
     char b0= (PINL & B00000010)>>1;  // pin 50
     if (a0==b0)
        encoder0Pos--;
     else
        encoder0Pos++;
     lasta0= a0;
     lastMoveTick= tickCount;
    }

  // read encoder 1

    char a1= (PINL & B00000100)>>2;  // pin 21
    if(a1 != lasta1) {
     char b1= (PINL & B00001000)>>3;  // pin 50
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
 
/*    char a0= PINL & B00000001;  // pin 21
    if(a0 != lasta0) {
     char b0= (PINL & B00000010)>>1;  // pin 50
     if (a0==b0)
        encoder0Pos--;
     else
        encoder0Pos++;
     lasta0= a0;
    }*/

  // read encoder 1

    char a1= (PINL & B00000100)>>2;  // pin 21
    if(a1 != lasta1) {
     char b1= (PINL & B00001000)>>3;  // pin 50
     if (a1==b1)
        encoder1Pos--;
     else
        encoder1Pos++;
     lasta1= a1;
   }
   
  }while(millis() < stopMs);
 // }while(encoder0Pos > 0);
 }


