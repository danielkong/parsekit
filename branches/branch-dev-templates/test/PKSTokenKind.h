//
//  PKSTokenKind.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import <Foundation/Foundation.h>

@interface PKSTokenKind : NSObject

+ (PKSTokenKind *)tokenKindWithStringValue:(NSString *)s name:(NSString *)name;

@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, copy) NSString *name;
@end
