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
@end

@implementation PKBaseSymbol

+ (id)symbolWithName:(NSString *)name {
    return [self symbolWithName:name type:nil];
}


+ (id)symbolWithName:(NSString *)name type:(id <PKType>)type {
    return [[[self alloc] initWithName:name type:type] autorelease];
}


- (id)initWithName:(NSString *)name {
    self = [self initWithName:name type:nil];
    return self;
}


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
    self.def = nil;
    self.scope = nil;
    [super dealloc];
}


- (NSString *)description {
    NSString *str = nil;

    if (_type) {
        str = [NSString stringWithFormat:@"<%@:%@>", _name, _type];
    } else {
        str = _name;
    }
    
    return str;
}

@end
