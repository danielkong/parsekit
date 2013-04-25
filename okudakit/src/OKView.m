//
//  OKView.m
//  OkudaKit
//
//  Created by Todd Ditchendorf on 10/19/12.
//
//

#import <OkudaKit/OKView.h>

@implementation OKView

- (void)dealloc {
    self.backgroundColor = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSView

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    OKAssertMainThread();
    
    [super resizeSubviewsWithOldSize:oldSize];
    
    [self layoutSubviews];
}


#pragma mark -
#pragma mark Public

- (void)setNeedsLayout {
    OKPerformOnMainThreadAfterDelay(0.0, ^{
        [self layoutSubviews];
    });
}


- (void)layoutSubviews {
    OKAssertMainThread();
    
}

@end
