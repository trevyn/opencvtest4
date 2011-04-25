#include <stdarg.h>
void p(char *fmt, ... );

// 4x 5v tolerant input pins on different interrupt lines for encoders:
// 33 B14
// 34 B15
// 35 C6
// 36 C7
#define ENCODER_0A_READ_FAST() (((GPIOB_BASE)->IDR & BIT(14)) >> 14)
#define ENCODER_0B_READ_FAST() (((GPIOB_BASE)->IDR & BIT(15)) >> 15)
#define ENCODER_1A_READ_FAST() (((GPIOC_BASE)->IDR & BIT(6)) >> 6)
#define ENCODER_1B_READ_FAST() (((GPIOC_BASE)->IDR & BIT(7)) >> 7)

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

//#define PIN_B6_HIGH (GPIOB_BASE)->BSRR = BIT(6)
//#define PIN_B6_LOW  (GPIOB_BASE)->BRR  = BIT(6)

volatile long encoder0Pos = 0;
volatile long encoder1Pos = 0;

void setup() {
  // set up encoder inputs as inputs
  pinMode(33, INPUT);
  pinMode(34, INPUT);
  pinMode(35, INPUT);
  pinMode(36, INPUT);
  
  // install interrupts on A channels
  attachInterrupt(33, encoder0interrupt, CHANGE);
  attachInterrupt(35, encoder1interrupt, CHANGE);
  
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

void encoder0interrupt(void) {
  if(ENCODER_0A_READ_FAST() == ENCODER_0B_READ_FAST())
     encoder0Pos--;
  else
     encoder0Pos++;
}

void encoder1interrupt(void) {
  if(ENCODER_1A_READ_FAST() == ENCODER_1B_READ_FAST())
     encoder1Pos--;
  else
     encoder1Pos++;
}


unsigned char cmdLen= 0;
char cmdBuf[256];

void loop() {
    if(SerialUSB.available()) {
      
      char incomingByte = SerialUSB.read();
      cmdBuf[cmdLen++]= incomingByte;
      cmdBuf[cmdLen]= 0;
  
      if (cmdBuf[cmdLen-1] == '\\') {
        p("got command: %s\n", cmdBuf);
        
        // act on command
        
        switch(cmdBuf[0]) {
          case 'i':
            driveMotor(motorYDirPin, motorYPwmPin, HIGH);
          break;
          case 'k':
            driveMotor(motorYDirPin, motorYPwmPin, LOW);
          break;
          case 'l':
            driveMotor(motorXDirPin, motorXPwmPin, HIGH);
          break;
          case 'j':
            driveMotor(motorXDirPin, motorXPwmPin, LOW);
          break;
          case 'y':
            driveMotor(motorZDirPin, motorZPwmPin, HIGH);
          break;
          case 'h':
            driveMotor(motorZDirPin, motorZPwmPin, LOW);
          break;
        }
        
        cmdLen= 0;
      }
    }
}
  

void driveMotor(int dirPin, int pwmPin, int dir) {
    digitalWrite(dirPin, dir ? HIGH : LOW);
    pwmWrite(pwmPin, 32767); // duty cycle to 65535
    delay(100);
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
  
  long lastEncoder0= encoder0Pos;
  long lastEncoder1= encoder1Pos;
  long lastMoveTick= 0;
  
  for(long tickCount= 0; tickCount < 150000; tickCount++) {
    if((encoder0Pos != lastEncoder0) || (encoder1Pos != lastEncoder1)) {
       lastEncoder0= encoder0Pos;
       lastEncoder1= encoder1Pos;
       lastMoveTick= tickCount;
    }
  }
    
  p("encoders settled at (%ld,%ld), %ld ticks to settle (waited 30k)\n", encoder0Pos, encoder1Pos, lastMoveTick);  // print encoder position

}  

