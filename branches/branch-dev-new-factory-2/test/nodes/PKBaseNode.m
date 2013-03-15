//
//  PKNode.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKBaseNode.h"

@interface PKBaseNode ()
@property (nonatomic, retain, readwrite) NSString *parserName;
@property (nonatomic, retain, readwrite) NSString *callbackName;
@end

@implementation PKBaseNode

+ (id)nodeWithToken:(PKToken *)tok {
    return [self nodeWithToken:tok parserName:nil];
}


+ (id)nodeWithToken:(PKToken *)tok parserName:(NSString *)pname {
    return [self nodeWithToken:tok parserName:pname callbackName:nil];
}


+ (id)nodeWithToken:(PKToken *)tok parserName:(NSString *)pname callbackName:(NSString *)cbname {
    return [[[self alloc] initWithToken:tok parserName:pname callbackName:cbname] autorelease];
}


- (id)initWithToken:(PKToken *)tok {
    self = [self initWithToken:tok parserName:nil];
    return self;
}


- (id)initWithToken:(PKToken *)tok parserName:(NSString *)pname {
    self = [self initWithToken:tok parserName:pname callbackName:nil];
    return self;
}


- (id)initWithToken:(PKToken *)tok parserName:(NSString *)pname callbackName:(NSString *)cbname {
    self = [super initWithToken:tok];
    if (self) {
        self.parserName = pname;
        self.callbackName = cbname;
    }
    return self;
}


- (void)dealloc {
    self.parserName = nil;
    self.callbackName = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKBaseNode *that = (PKBaseNode *)[super copyWithZone:zone];
    that->_parserName = [_parserName copyWithZone:zone];
    that->_callbackName = [_callbackName copyWithZone:zone];
    that->_discard = _discard;
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }

    PKBaseNode *that = (PKBaseNode *)obj;
    
    if (![_parserName isEqual:that->_parserName]) {
        return NO;
    }
    
    if (![_callbackName isEqual:that->_callbackName]) {
        return NO;
    }
    
    if (_discard != that->_discard) {
        return NO;
    }
    
    return YES;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    NSAssert2(0, @"%s is an abastract method. Must be overridden in %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}


- (NSString *)name {
    NSString *prefix = _parserName ? _parserName : @"";
    NSString *suffix = [super name];
    
    NSString *str = [NSString stringWithFormat:@"%@:%@", prefix, suffix];
    return str;
}

@end
