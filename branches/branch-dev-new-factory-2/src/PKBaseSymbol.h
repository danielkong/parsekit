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

- (id)initWithName:(NSString *)name type:(NSString *)type;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, retain, readonly) id <PKType>type;
@end
