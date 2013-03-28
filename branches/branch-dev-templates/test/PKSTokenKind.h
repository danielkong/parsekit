//
//  PKSTokenKind.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import <Foundation/Foundation.h>

@interface PKSTokenKind : NSObject

@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, assign) NSInteger integerValue;
@end
