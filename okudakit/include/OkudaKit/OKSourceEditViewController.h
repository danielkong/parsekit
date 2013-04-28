//
//  OKSourceEditViewController.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 4/24/13.
//
//

#import <Cocoa/Cocoa.h>

@class OKSyntaxHighlighter;
@class OKSourceCodeTextView;
@class OKGutterView;

@interface OKSourceEditViewController : NSViewController

- (id)init; // use me

@property (nonatomic, retain) IBOutlet OKSourceCodeTextView *textView;
@property (nonatomic, retain) IBOutlet OKGutterView *gutterView;

@property (nonatomic, retain) NSAttributedString *sourceString;
@property (nonatomic, retain) OKSyntaxHighlighter *highlighter;
@end
