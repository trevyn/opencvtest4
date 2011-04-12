#include <stdlib.h>
#include <PinChangeInt.h>
#include <PinChangeIntConfig.h>


#define encoder0PinA  21
#define encoder0PinB  52

volatile long encoder0Pos = 0;


void setup() {
  
  // setup encoder inputs and interrupt handler
  
  pinMode(encoder0PinA, INPUT); 
  digitalWrite(encoder0PinA, HIGH);       // turn on pullup resistor
  pinMode(encoder0PinB, INPUT); 
  digitalWrite(encoder0PinB, HIGH);       // turn on pullup resistor

//  PCattachInterrupt(21, doEncoder, CHANGE);  // encoder pin on interrupt 2 - pin 21

//  attachInterrupt(2, doEncoder, CHANGE);  // encoder pin on interrupt 2 - pin 21

  // setup output pins
  
  PORTC= B00000000;
  DDRC = B11111111;  // set as outputs
  PORTC= B00000000;
  
  // setup serial
  
  Serial.begin(115200);
  Serial.println("start");                // a personal quirk

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
  
  char lastd;
  char driveByte= 0;
    PORTC= B00000000;  // force stop
  
 loop1:
    
   while(Serial.available() < 1){ // any key
  }

 
      char incomingByte = Serial.read();
       Serial.print("got keypress: ");
       Serial.println(incomingByte);

//  cli();  // disable interrupts


      switch(incomingByte) {
        case 'i':
          driveByte= B11000000;
         break;
        case 'k':
          driveByte= B01000000;
        break;
        case 'j':
            PORTC= B00110000;
        break;
        case 'l':
            PORTC= B00010000;
        break;
        case '0':  // home ;)
          if(encoder0Pos > 0) {  // go down
              PORTC= B00010000;
            do{
             char d= PIND & B00000001;  // pin 21
             if(lastd != d) {
               char b= (PINB & B00000010)>>1;  // pin 50
               if (d==b)
                   encoder0Pos--;
               else
                  encoder0Pos++;
               lastd= d;
             }
            }while(encoder0Pos > 0);
          }
          else if(encoder0Pos < 0) {  // go up
              PORTC= B00110000;
            do{
              char d= PIND & B00000001;  // pin 21
             if(lastd != d) {
               char b= (PINB & B00000010)>>1;  // pin 50
               if (d==b)
                   encoder0Pos--;
               else
                  encoder0Pos++;
               lastd= d;
             }
            }while(encoder0Pos < 0);
          }
          
          
          PORTC= B00000000;
        break;
      }

      // run: 1ms on, 5ms off x30
      
      for(int x= 0; x < 60; x++) {
        unsigned long stopMillis;
        
        stopMillis= millis()+1;
        PORTC= driveByte;
        do {
        } while(millis() < stopMillis);

        stopMillis= millis()+30;
        PORTC= B00000000;  // stop
        do {
        } while(millis() < stopMillis);

      }


/*      unsigned long stopMillis= millis()+10;

      do {
         char d= PIND & B00000001;  // pin 21
         if(lastd != d) {
           char b= (PINB & B00000010)>>1;  // pin 50
           if (d==b)
               encoder0Pos--;
           else
              encoder0Pos++;
           lastd= d;
         }
      } while(millis() < stopMillis);

       // stop and wait for settle

       PORTC= B00000000;  // stop


     stopMillis= millis()+15;

      do {
         char d= PIND & B00000001;  // pin 21
         if(lastd != d) {
           char b= (PINB & B00000010)>>1;  // pin 50
           if (d==b)
               encoder0Pos--;
           else
              encoder0Pos++;
           lastd= d;
         }
      } while(millis() < stopMillis);
     
     
///     sei();
     
      
       Serial.println (encoder0Pos, DEC);  // print encoder position
//     delay(10);  // wait 5ms for position to settle
//      Serial.println (encoder0Pos, DEC);  // print encoder position
*/
          
  goto loop1;
}

void doEncoder() {
//  encoder0Pos++;
  /* If pinA and pinB are both high or both low, it is spinning
   * forward. If they're different, it's going backward.
   *
   * For more information on speeding up this process, see
   * [Reference/PortManipulation], specifically the PIND register.
   */
   char d= PIND & B00000001;  // pin 21
   char b= (PINB & B00000010)>>1;  // pin 50
   
   
//  if (digitalRead(encoder0PinA) == digitalRead(encoder0PinB)) {
  if (d==b) {
    encoder0Pos--;
  } else {
    encoder0Pos++;
  }

}

