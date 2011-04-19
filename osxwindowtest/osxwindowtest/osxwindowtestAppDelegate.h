//
//  osxwindowtestAppDelegate.h
//  osxwindowtest
//
//  Created by Eden on 4/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface osxwindowtestAppDelegate : NSObject <NSApplicationDelegate> {

@private
    NSWindow *window;
    NSScrollView *logView;
    NSTextField *commandField;
    int fd;

}


@property (assign) IBOutlet NSWindow *window;
- (IBAction)didPushButton:(id)sender;
@property (assign) IBOutlet NSScrollView *logView;
@property (assign) IBOutlet NSTextField *commandField;
- (IBAction)didHitReturn:(id)sender;

@end
