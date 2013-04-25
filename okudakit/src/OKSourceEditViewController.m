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
    self.highlighter = [[[OKSyntaxHighlighter alloc] init] autorelease];

    NSString *path = [[NSBundle mainBundle] pathForResource:@"example" ofType:@"js"];
    NSString *s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    self.sourceString = [_highlighter highlightedStringForString:s ofGrammar:@"javascript"];

    [_textView setFont:[NSFont userFixedPitchFontOfSize:11.0]];
    //[_textView setFont:[NSFont fontWithName:@"Monaco" size:11.0]];
    
    
}

@end
