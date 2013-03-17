//
//  PKBaseSymbol.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import <Foundation/Foundation.h>

@protocol PKType;

@interface PKBaseSymbol : NSObject

+ (PKBaseSymbol *)symbolWithName:(NSString *)name type:(id <PKType>)type;

- (id)initWithName:(NSString *)name type:(id <PKType>)type;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, retain, readonly) id <PKType>type;
@end
