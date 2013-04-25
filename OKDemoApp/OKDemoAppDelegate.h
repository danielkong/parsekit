//
//  OKDemoAppDelegate.h
//  OkudaKit
//
//  Created by Todd Ditchendorf on 7/27/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OKSyntaxHighlighter;
@class OKSourceEditViewController;

@interface OKDemoAppDelegate : NSObject {
    IBOutlet NSWindow *window;
    IBOutlet NSView *containerView;
    IBOutlet NSTextView *textView;
    
    NSAttributedString *displayString;
}

- (IBAction)highlight:(id)sender;
- (IBAction)clear:(id)sender;

@property (nonatomic, copy) NSAttributedString *displayString;

@property (nonatomic, retain) OKSourceEditViewController *viewController;
@end
