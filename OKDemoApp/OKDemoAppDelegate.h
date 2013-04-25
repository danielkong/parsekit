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

@interface OKDemoAppDelegate : NSObject

- (IBAction)highlight:(id)sender;
- (IBAction)clear:(id)sender;


@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSView *containerView;

@property (nonatomic, retain) OKSourceEditViewController *viewController;
@property (nonatomic, copy) NSAttributedString *displayString;
@end
