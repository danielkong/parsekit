//
//  PKSRecognitionException.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/28/13.
//
//

#import <ParseKit/PKSRecognitionException.h>

@implementation PKSRecognitionException

- (id)init {
    self = [super initWithName:NSStringFromClass([self class]) reason:nil userInfo:nil];
    if (self) {
        
    }
    return self;
}


- (void)dealloc {
    self.currentReason = nil;
    [super dealloc];
}


- (NSString *)reason {
    return self.currentReason;
}

@end
