//
//  OKSourceCodeTextView.h
//  TextTest
//
//  Created by Todd Ditchendorf on 9/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OKGutterView;

@interface OKSourceCodeTextView : NSTextView {
    IBOutlet OKGutterView *gutterView;
    IBOutlet NSScrollView *scrollView;
    CGFloat sourceTextViewOffset;
}
- (void)renderGutter;

@property (assign) OKGutterView *gutterView;
@end
