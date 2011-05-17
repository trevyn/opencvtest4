#include <stdarg.h>
void p(char *fmt, ... );

// 4x 5v tolerant input pins on different interrupt lines for encoders:
// 33 B14
// 34 B15
// 35 C6
// 36 C7
#define ENCODER_XA_READ_FAST() (((GPIOB_BASE)->IDR & BIT(14)) >> 14)
#define ENCODER_XB_READ_FAST() (((GPIOB_BASE)->IDR & BIT(15)) >> 15)
#define ENCODER_YA_READ_FAST() (((GPIOC_BASE)->IDR & BIT(6)) >> 6)
#define ENCODER_YB_READ_FAST() (((GPIOC_BASE)->IDR & BIT(7)) >> 7)

// 3x output pins for motor direction control
// 0 A3 P
// 2 A0 P
// 4 B5 
#define motorYDirPin 0
#define motorXDirPin 2
#define motorZDirPin 4

// 3x pwm outputs for motor speed control (0-5 for direction and speed, all pwmable except 4)
// 1 A2 P
// 3 A1 P
// 5 B6 P
#define motorYPwmPin 1
#define motorXPwmPin 3
#define motorZPwmPin 5

#define voltageSensePin 20
#define ledPin 13

#define xDirForward LOW
#define xDirReverse HIGH
#define yDirForward HIGH
#define yDirReverse LOW
#define zDirUp HIGH
#define zDirDown LOW

//#define PIN_B6_HIGH (GPIOB_BASE)->BSRR = BIT(6)
//#define PIN_B6_LOW  (GPIOB_BASE)->BRR  = BIT(6)

volatile long encoderXPos = 0;
volatile long encoderYPos = 0;

long xTarget= 0;
long yTarget= 0;


void setup() {
  // set up encoder inputs as inputs
  pinMode(33, INPUT);
  pinMode(34, INPUT);
  pinMode(35, INPUT);
  pinMode(36, INPUT);
  
  pinMode(voltageSensePin, INPUT_ANALOG);
  pinMode(ledPin, OUTPUT);
  
   pinMode(13, OUTPUT);
  pinMode(14, INPUT_PULLUP);
 
    
  
  // install interrupts on A channels
  attachInterrupt(33, encoderXinterrupt, CHANGE);
  attachInterrupt(35, encoderYinterrupt, CHANGE);
  
  // set up outputs
  pinMode(motorXDirPin, OUTPUT);
  pinMode(motorYDirPin, OUTPUT);
  pinMode(motorZDirPin, OUTPUT);

  pwmWrite(motorXPwmPin, 0);
  pinMode(motorXPwmPin, PWM);
  pwmWrite(motorXPwmPin, 0);

  pwmWrite(motorYPwmPin, 0);
  pinMode(motorYPwmPin, PWM);
  pwmWrite(motorYPwmPin, 0);

  pwmWrite(motorZPwmPin, 0);
  pinMode(motorZPwmPin, PWM);
  pwmWrite(motorZPwmPin, 0);
  
  // set pwm frequency
  // this is actually complicated, as the timer overflow affects the actual value of 100% duty cycle on pwmWrite() calls.
  
//Timer1.setPeriod(2041);
//Timer2.setPeriod(2041);
//Timer3.setPeriod(2041);
//Timer4.setPeriod(2041);
//setPrescaleFactor
  
  SerialUSB.println("start");
}

void encoderXinterrupt(void) {
  if(ENCODER_XA_READ_FAST() == ENCODER_XB_READ_FAST())
     encoderXPos--;
  else
     encoderXPos++;
}

void encoderYinterrupt(void) {
  if(ENCODER_YA_READ_FAST() == ENCODER_YB_READ_FAST())
     encoderYPos--;
  else
     encoderYPos++;
}


unsigned char cmdLen= 0;
char cmdBuf[256];
long cmdPos, posMultiplier;
long pos= 0;
uint32 lastMillisOn= 0;

void loop() {
  long didRun= 0;

  while(1) {
  
    if(digitalRead(14) == LOW) {  // enable switch
    
      didRun= 10000;
    
      if(analogRead(20) > 600) {  // voltage present
        digitalWrite(13, HIGH);     
        pwmMotor(motorZDirPin, motorZPwmPin, zDirUp, 65535);
      }
      else {
        digitalWrite(13, LOW);     
        pwmMotor(motorZDirPin, motorZPwmPin, zDirDown, 65535);
      }
    }
    else {
      digitalWrite(13, LOW);
       if(didRun) {
         didRun--;
          if(didRun == 1) {
               pwmMotor(motorZDirPin, motorZPwmPin, zDirUp, 65535);
               delay(3500);
               didRun= 0;
          }
       }
      
               
      pwmMotor(motorZDirPin, motorZPwmPin, zDirDown, 0);
    }
  
/*  if(analogRead(voltageSensePin) > 600) {
    lastMillisOn= millis();
    do {
      pwmMotor(motorZDirPin, motorZPwmPin, HIGH, 10000);
      
      
//      driveMotor(motorZDirPin, motorZPwmPin, HIGH, 30000, 1);
//      delay(2);
    }
    while (analogRead(voltageSensePin) > 240);

      pwmMotor(motorZDirPin, motorZPwmPin, HIGH, 0);


//    delay(10);
    digitalWrite(ledPin, HIGH);
  }
  else if(millis() > lastMillisOn+20) {  // X ms delay before lowering it more
    driveMotor(motorZDirPin, motorZPwmPin, LOW, 10000, 1);
//    delay(1);
    digitalWrite(ledPin, LOW);
  }*/

  }
  
  
//  delay(5);
  
    if(SerialUSB.available()) {
      
      char incomingByte = SerialUSB.read();
      cmdBuf[cmdLen++]= incomingByte;
      cmdBuf[cmdLen]= 0;
  
      if (cmdBuf[cmdLen-1] == '\\') {
        p("got command: %s\n", cmdBuf);
        
        // act on command
        
        uint32 startMillis;
        
        long xStart, xFun;
        long yStart, yFun;

        
        switch(cmdBuf[0]) {
          case '1':
            for(int x= 0; x < 2; x++) {
            encoderMoveTo(750, 0);
            encoderMoveTo(0, 0);
            }
          
          break;
          case '2':
            for(int x= 0; x < 5; x++) {
            driveMotor(motorZDirPin, motorZPwmPin, LOW, 10000, 1);
            encoderMoveTo(750, 0);
            driveMotor(motorZDirPin, motorZPwmPin, LOW, 10000, 1);
            encoderMoveTo(0, 0);
            }
          
          break;
          case 'q':
            driveMotor(motorZDirPin, motorZPwmPin, HIGH, 65535, 1000);
          break;
          case 'a':
            driveMotor(motorZDirPin, motorZPwmPin, LOW, 65535, 1000);
          break;
          case 'w':
            driveMotor(motorZDirPin, motorZPwmPin, HIGH, 65535, 200);
          break;
          case 's':
            driveMotor(motorZDirPin, motorZPwmPin, LOW, 65535, 200);
          break;
          case 'e':
            driveMotor(motorZDirPin, motorZPwmPin, HIGH, 65535, 30);
          break;
          case 'd':
            driveMotor(motorZDirPin, motorZPwmPin, LOW, 65535, 30);
          break;

          case 'i':
            driveMotor(motorYDirPin, motorYPwmPin, HIGH, 65535, 50);
          break;
          case 'k':
            driveMotor(motorYDirPin, motorYPwmPin, LOW, 65535, 50);
          break;
          case 'l':
            driveMotor(motorXDirPin, motorXPwmPin, HIGH, 65535, 50);
          break;
          case 'j':
            driveMotor(motorXDirPin, motorXPwmPin, LOW, 65535, 50);
          break;
          case 'u':
            driveMotor(motorZDirPin, motorZPwmPin, HIGH, 10000, 50);
          break;
          case 'm':
            driveMotor(motorZDirPin, motorZPwmPin, LOW, 10000, 50);
          break;
//          case 's':
//            encoderSettle();
//          break;
          case 'z':
            encoderXPos= 0;
            encoderYPos= 0;
            encoderSettle();
          break;
          case 'c':  // circle!
          
            xStart= encoderXPos;
            yStart= encoderYPos;
          
            for(int x= 0; x <= 1000; x++) {
              double pi= 3.14159;
              
             xFun= sin((2*pi*x)/1000)*2000;
              yFun= cos((2*pi*x)/1000)*2000-2000;
               
//               p("%ld: %ld, %ld (diff: %ld, %ld)\n", x, xStart+xFun, yStart+yFun, xFun, yFun);
               
               encoderMoveTo(xStart+xFun, yStart+yFun);
            }

            encoderSettle();

          break;

          case 't':
             p("start 5 sec\n");
             startMillis= millis();
 
             do{
               encoderMoveStep((millis()-startMillis)/5, 0, 30000); 
             } while(millis() < (startMillis + 5000));
 
             encoderStop();
 
             p("done\n");
          break;

          case 'p':  // attempt at PI control!
 
             {
               long instXTarget, instYTarget, xError, yError, xErrorAcc, yErrorAcc, xOutput, yOutput, xDir, yDir, xFun, yFun;
               float pCoeff, iCoeff;
                           double pi= 3.14159;
  

              xErrorAcc= 0;
              yErrorAcc= 0;

               p("start 5 sec pi\n");
               startMillis= millis();
               long printMillis= millis();
   
               do {
               
                 // do PI control
                 
              xFun= sin((2*pi*(millis()-startMillis))/20000)*2000;
              yFun= cos((2*pi*(millis()-startMillis))/20000)*2000-2000;
 
                 instXTarget= xFun;
                 instYTarget= yFun; //(millis()-startMillis)/5;
                 
                 xError= instXTarget - encoderXPos;
                 yError= instYTarget - encoderYPos;
               
                 xErrorAcc+= xError;
                 yErrorAcc+= yError;
               
                 pCoeff= 1000;
                 iCoeff= 0.0;
               
                 xOutput= (xError*pCoeff)+(xErrorAcc*iCoeff);
                 yOutput= (yError*pCoeff)+(yErrorAcc*iCoeff);
                                  
                 // deconstruct output variables into direction, and clamp PWM speed to 65535
 
                 if(xOutput < 0) {
                    xDir= xDirForward;
                    xOutput= -xOutput;
                 }
                 else {
                    xDir= xDirReverse;
                 }

                 if(yOutput < 0) {
                    yDir= yDirForward;
                    yOutput= -yOutput;
                 }
                 else {
                    yDir= yDirReverse;
                 }
             
                 if(xOutput > 65535)
                   xOutput= 65535;
                 if(yOutput > 65535)
                   yOutput= 65535;
                 
                 // do it
                 if(millis() > printMillis) {
                  
                   p("p(%ld, %ld) t(%ld,%ld) e(%ld,%ld) a(%ld,%ld) o(%ld,%ld) d(%ld,%ld)\n", encoderXPos, encoderYPos, instXTarget, instYTarget, xError, yError, xErrorAcc, yErrorAcc, xOutput, yOutput, xDir, yDir);
                   printMillis+= 50;
                 }
                
                 pwmMotor(motorYDirPin, motorYPwmPin, yDir, yOutput);
                 pwmMotor(motorXDirPin, motorXPwmPin, xDir, xOutput);

               } while(millis() < (startMillis + 20000));
   
               encoderStop();
               encoderSettle();
               
               p("done\n");
             }
          break;



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
            p("pos start: %ld, %ld\n", encoderXPos, encoderYPos);

            encoderMoveTo(xTarget, yTarget);
            encoderSettle();

            p("pos end: %ld, %ld\n", encoderXPos, encoderYPos);
                 
          break;
             
        }
        
        cmdLen= 0;
      }
    }
}

void encoderMoveTo(long encoderXTarget, long encoderYTarget) {
  
  unsigned long driveTickCount;

  for(driveTickCount= 0; driveTickCount < 1000000; driveTickCount++) {
   
   encoderMoveStep(encoderXTarget, encoderYTarget, 40000);
    
   if((encoderYPos >= encoderYTarget-5) && (encoderYPos <= encoderYTarget+5) &&
      (encoderXPos >= encoderXTarget-5) && (encoderXPos <= encoderXTarget+5))
      break;
      
  }
  
  // stop, note still needs settling
  
  encoderStop();

}

void encoderStop(void) {
  pwmMotor(motorXDirPin, motorXPwmPin, LOW, 0);
  pwmMotor(motorYDirPin, motorYPwmPin, LOW, 0);
}

void encoderMoveStep(long encoderXTarget, long encoderYTarget, long dutyCycle) {
    if(encoderYTarget > (encoderYPos+5))
      pwmMotor(motorYDirPin, motorYPwmPin, yDirReverse, dutyCycle);
    else if(encoderYTarget < (encoderYPos-5))
      pwmMotor(motorYDirPin, motorYPwmPin, yDirForward, dutyCycle);
    else  // ==
      pwmMotor(motorYDirPin, motorYPwmPin, LOW, 0);

  
    if(encoderXTarget > (encoderXPos+5))
      pwmMotor(motorXDirPin, motorXPwmPin, xDirReverse, dutyCycle);
    else if(encoderXTarget < (encoderXPos-5))
      pwmMotor(motorXDirPin, motorXPwmPin, xDirForward, dutyCycle);
    else  // ==
      pwmMotor(motorXDirPin, motorXPwmPin, LOW, 0);
  
}


void pwmMotor(int dirPin, int pwmPin, int dir, int pwmDuty) {
    digitalWrite(dirPin, dir ? HIGH : LOW);
    pwmWrite(pwmPin, pwmDuty); // duty cycle to 65535
}

void driveMotor(int dirPin, int pwmPin, int dir, int pwmDuty, int delayTime) {
    digitalWrite(dirPin, dir ? HIGH : LOW);
    pwmWrite(pwmPin, pwmDuty); // duty cycle to 65535
    delay(delayTime);
    pwmWrite(pwmPin, 0); // duty cycle to 65535
//    encoderSettle();
}
  

void p(char *fmt, ... ){
        char tmp[256];
        va_list args;
        va_start (args, fmt );
        vsnprintf(tmp, 256, fmt, args);
        va_end (args);
        SerialUSB.print(tmp);
}

void encoderSettle(void) {
  
  long lastEncoderX= encoderXPos;
  long lastEncoderY= encoderYPos;
  long lastMoveTick= 0;
  
  for(long tickCount= 0; tickCount < 150000; tickCount++) {
    if((encoderXPos != lastEncoderX) || (encoderYPos != lastEncoderY)) {
       lastEncoderX= encoderXPos;
       lastEncoderY= encoderYPos;
       lastMoveTick= tickCount;
    }
  }
    
  p("encoders settled at (%ld,%ld), %ld ticks to settle (waited 30k)\n", encoderXPos, encoderYPos, lastMoveTick);  // print encoder position

}  

