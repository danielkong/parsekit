//
//  PKBuiltInTypeSymbol.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKBuiltInTypeSymbol.h"

@implementation PKBuiltInTypeSymbol

+ (PKBuiltInTypeSymbol *)symbolWithName:(NSString *)name {
    return [[[self alloc] initWithName:name] autorelease];
}


- (id)initWithName:(NSString *)name {
    self = [super initWithName:name type:nil];
    if (self) {
        
    }
    return self;
}

@end
