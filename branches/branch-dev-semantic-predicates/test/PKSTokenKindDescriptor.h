//
//  PKSTokenKindDescriptor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/27/13.
//
//

#import <Foundation/Foundation.h>

@interface PKSTokenKindDescriptor : NSObject

+ (PKSTokenKindDescriptor *)descriptorWithStringValue:(NSString *)s name:(NSString *)name;
+ (PKSTokenKindDescriptor *)anyDescriptor;

@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, copy) NSString *name;
@end
