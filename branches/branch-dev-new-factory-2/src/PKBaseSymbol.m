//
//  PKBaseSymbol.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKBaseSymbol.h"

@interface PKBaseSymbol ()
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) id <PKType>type;
@end

@implementation PKBaseSymbol

- (id)initWithName:(NSString *)name type:(id <PKType>)type {
    self = [super init];
    if (self) {
        self.name = name;
        self.type = type;
    }
    return self;
}


- (void)dealloc {
    self.name = nil;
    self.type = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:%@>", _name, _type];
}

@end
