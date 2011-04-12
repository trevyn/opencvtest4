#include <stdlib.h>

volatile long encoder0Pos = 0;
volatile long encoder1Pos = 0;
volatile char lasta0;
volatile char lasta1;

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
  
 loop1:
    
   while(Serial.available() < 1){ // any key
    encoderDelayMs(5);  // read encoder!
  }

 
      char incomingByte = Serial.read();
       Serial.print("got keypress: ");
       Serial.println(incomingByte);

//  cli();  // disable interrupts


      switch(incomingByte) {
        case 'y':
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
        break;
       }

      // run: 1ms on, 5ms off x30
      
      for(int x= 0; x < 2; x++) {
        
         PORTC= driveByte;
          encoderDelayMs(20);
  
         PORTC= B00000000;  // stop
 //          encoderDelayMs(10);        
      }

///     sei();      
//       Serial.println (encoder0Pos, DEC);  // print encoder position
          
  goto loop1;
}


void encoderDelayMs(unsigned long delayMs) {
  
  unsigned long stopMs= millis()+delayMs;

  do{
    char a0= PIND & B00000001;  // pin 21
    if(a0 != lasta0) {
     char b0= (PINB & B00000010)>>1;  // pin 50
     if (a0==b0)
         encoder0Pos--;
     else
        encoder0Pos++;
     lasta0= a0;
   }
  }while(millis() < stopMs);
 // }while(encoder0Pos > 0);
 }


