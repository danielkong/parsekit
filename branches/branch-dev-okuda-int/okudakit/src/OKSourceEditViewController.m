//
//  OKSourceEditViewController.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 4/24/13.
//
//

#import <OkudaKit/OKSourceEditViewController.h>
#import <OkudaKit/OKSourceCodeTextView.h>
#import <OkudaKit/OKSyntaxHighlighter.h>

@interface OKSourceEditViewController ()

@end

@implementation OKSourceEditViewController

- (id)init {
    self = [self initWithNibName:@"OKSourceEditViewController" bundle:[NSBundle bundleForClass:[OKSourceEditViewController class]]];
    return self;
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    self = [super initWithNibName:name bundle:b];
    if (self) {
        
    }
    
    return self;
}


- (void)dealloc {
    self.textView = nil;
    self.gutterView = nil;
    self.sourceString = nil;
    self.highlighter = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    self.sourceString = [[[NSAttributedString alloc] initWithString:@""] autorelease];
    self.highlighter = [[[OKSyntaxHighlighter alloc] init] autorelease];

    //[_textView setFont:[NSFont userFixedPitchFontOfSize:11.0]];
    //[_textView setFont:[NSFont fontWithName:@"Monaco" size:11.0]];
    
//    [_textView setBackgroundColor:[NSColor colorWithDeviceWhite:0.18 alpha:1.0]];
    [_textView setInsertionPointColor:[NSColor blackColor]];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"example" ofType:@"js"];
    NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    self.sourceString = [_highlighter highlightedStringForString:s ofGrammar:@"javascript"];
}

#pragma mark -
#pragma mark NSTextDelegate

- (void)textDidChange:(NSNotification *)n {
    NSAssert([n object] == _textView, @"");
    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSString *s = [_textView string];
    if ([s length]) {
//        NSRange selRange = [_textView selectedRange];
//        
//        if (selRange.location != NSNotFound) {
            id res = [_highlighter highlightedStringForString:s ofGrammar:@"javascript"];
        NSLog(@"%@", res);
            self.sourceString = res;
            //        [_textView setSelectedRange:selRange];
//        }
    }
}

@end
