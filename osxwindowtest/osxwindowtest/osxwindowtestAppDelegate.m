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

@synthesize logTextView;
@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    fd = USBSerialInit();
    
    // GCD can't dispatch off of serial port socket data availability, apparently, so we'll just whack it with a timer.
    
    NSTimer *timer1;
    
    timer1 = [NSTimer scheduledTimerWithTimeInterval:.1
                                                  target:self
                                                selector:@selector(updateTimerNoTwo:)
                                                userInfo:nil
                                                 repeats:YES];

}

- (IBAction)didPushButton:(id)sender {
    
//    printf("%s\n", [[commandField stringValue] UTF8String]);
}

- (void) updateTimerNoTwo:(NSTimer *) timer {

    char buffer[256];

    do {
        USBSerialGetLine(fd,buffer,sizeof(buffer));
        if(buffer[0] != '\0') {
            [self logString:[NSString stringWithUTF8String:buffer]];
            
        }
//        printf("serial in: %s\n",buffer);
    } while (buffer[0] != '\0');
    
}

- (void)logString:(NSString *) string {
    
    [[[logTextView textStorage] mutableString] appendString: string];
    [logTextView scrollRangeToVisible: NSMakeRange([[logTextView string] length], 0)];

}

- (IBAction)didHitReturn:(id)sender {
    printf("serial out: %s\n", [[commandField stringValue] UTF8String]);
    write(fd, [[commandField stringValue] UTF8String], strlen([[commandField stringValue] UTF8String]));
    
}
@end
