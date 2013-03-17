//
//  PKBuiltInTypeSymbol.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKBaseSymbol.h"
#import "PKType.h"

@interface PKBuiltInTypeSymbol : PKBaseSymbol <PKType>

+ (PKBuiltInTypeSymbol *)symbolWithName:(NSString *)name;

- (id)initWithName:(NSString *)name;

@end
