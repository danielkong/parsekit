//
//  OKDemoAppDelegate.m
//  OkudaKit
//
//  Created by Todd Ditchendorf on 7/27/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "OKDemoAppDelegate.h"
#import <OkudaKit/OkudaKit.h>

@implementation OKDemoAppDelegate

- (void)dealloc {
    self.displayString = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [self performSelector:@selector(highlight:) withObject:nil afterDelay:0.0];
    
    self.viewController = [[[OKSourceEditViewController alloc] init] autorelease];
    [_viewController.view setFrame:[containerView bounds]];
    [containerView addSubview:_viewController.view];
}


- (void)doJSONHighlighting {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"yahoo" ofType:@"json"];
    NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    OKSyntaxHighlighter *shc = [[[OKSyntaxHighlighter alloc] init] autorelease];
    self.displayString = [shc highlightedStringForString:s ofGrammar:@"json"];
}


- (void)doCSSHighlighting {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"example" ofType:@"css"];
    NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    OKSyntaxHighlighter *shc = [[[OKSyntaxHighlighter alloc] init] autorelease];
    self.displayString = [shc highlightedStringForString:s ofGrammar:@"css"];
}


- (void)doHTMLHighlighting {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"example" ofType:@"html"];
    NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    OKSyntaxHighlighter *shc = [[[OKSyntaxHighlighter alloc] init] autorelease];
    self.displayString = [shc highlightedStringForString:s ofGrammar:@"html"];
}


- (void)doJavaScriptHighlighting {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"example" ofType:@"js"];
    NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    OKSyntaxHighlighter *shc = [[[OKSyntaxHighlighter alloc] init] autorelease];
    self.displayString = [shc highlightedStringForString:s ofGrammar:@"javascript"];
}


- (IBAction)highlight:(id)sender {
    self.displayString = nil;
    [self doJavaScriptHighlighting];
}


- (IBAction)clear:(id)sender {
    self.displayString = nil;
}

@synthesize displayString;
@end
