//
//  PKSRecognitionException.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/28/13.
//
//

#import <Foundation/Foundation.h>

@interface PKSRecognitionException : NSObject //NSException

@property (nonatomic, retain) NSString *currentReason;
@end
