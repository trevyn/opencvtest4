//
//  osxwindowtestAppDelegate.m
//  osxwindowtest
//
//  Created by Eden on 4/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "osxwindowtestAppDelegate.h"
#include "usbserial.h"

@implementation osxwindowtestAppDelegate
@synthesize logView;
@synthesize commandField;

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    fd = USBSerialInit();
    
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t socketSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, globalQueue);
    // This block will be executed when data is available for
    // reading on the socket file descriptor.
    dispatch_source_set_event_handler(socketSource, ^{
        
        printf("getdata: %ld\n", dispatch_source_get_data(socketSource))
        ;
        
        NSLog(@"event handler");
        char buffer[256];
 //       printf("timer hit\n");
        //   fgets(buffer, sizeof(buffer), fd);
        do {
            USBSerialGetLine(fd,buffer,sizeof(buffer));
            if(buffer[0] != '\0')
                printf("serial in: %s\n",buffer);
        } while (buffer[0] != '\0');
        
        printf("getdata: %ld\n", dispatch_source_get_data(socketSource))
        ;

    });
    dispatch_retain(socketSource);
    dispatch_resume(socketSource);


        
 /*       int rcvCounter = 0;
        int rcvLen = read(socketArray[i], (void*)&rcvCounter, sizeof(int));
        if (rcvLen > 0) {
            
//            debug_NSLog(@"Got int:%d from socket %d", rcvCounter, socketArray[i]);
             // If the rcvCounter = 0, let the main thread know the
            // process is complete
            if (!rcvCounter) {
                25
                CHECK(write(socketArray[0], &rcvCounter, sizeof(int)));
                26
                
                27
                // Setup detail. Connect the end of the ring to the
                28
                // beginning. Hence, 'ring'
                29
            } else if (i == ((numProcs+1)*2)-1) {
                30
                --rcvCounter;
                31
                CHECK(write(socketArray[2], &rcvCounter, sizeof(int)));
                32
                
                33
                //  This is the normal case in the ring. Send the
                34
                // message to the next 'process' in the ring
                35
            } else {
                36
                --rcvCounter;
                37
                CHECK(write(socketArray[i+1], &rcvCounter, sizeof(int)));
                38
            }
            39
        }
        40
    });*/
    
    
    
    
/*    NSTimer *timer1;
    
    timer1 = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(updateTimerNoTwo:)
                                                userInfo:nil
                                                 repeats:YES];

    */
    /* loop reading lines from the USB Serial Port  
    while (1)
    {
     }*/
}

- (IBAction)didPushButton:(id)sender {
    
//    printf("%s\n", [[commandField stringValue] UTF8String]);
}


- (IBAction)didHitReturn:(id)sender {
    printf("serial out: %s\n", [[commandField stringValue] UTF8String]);
    write(fd, [[commandField stringValue] UTF8String], strlen([[commandField stringValue] UTF8String]));
    
    NSLog(@"force read");
    char buffer[256];
    //       printf("timer hit\n");
    //   fgets(buffer, sizeof(buffer), fd);
    do {
        USBSerialGetLine(fd,buffer,sizeof(buffer));
        if(buffer[0] != '\0')
            printf("serial in: %s\n",buffer);
    } while (buffer[0] != '\0');

    
}
@end
