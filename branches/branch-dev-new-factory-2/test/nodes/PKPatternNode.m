//
//  PKNodePattern.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKPatternNode.h"

@implementation PKPatternNode

- (void)dealloc {
    self.string = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKPatternNode *that = (PKPatternNode *)[super copyWithZone:zone];
    that->_string = [_string retain];
    that->_options = _options;
    return that;
}


- (BOOL)isEqual:(id)obj {
    if (![super isEqual:obj]) {
        return NO;
    }
    
    PKPatternNode *that = (PKPatternNode *)obj;
    
    if (![_string isEqual:that->_string]) {
        return NO;
    }
    
    if (_options != that->_options) {
        return NO;
    }
    
    return YES;
}


- (NSUInteger)type {
    return PKNodeTypePattern;
}


- (NSString *)name {
    NSMutableString *optsString = [NSMutableString string];
    
    PKPatternOptions opts = _options;
    if (opts & PKPatternOptionsIgnoreCase) {
        [optsString appendString:@"i"];
    }
    if (opts & PKPatternOptionsMultiline) {
        [optsString appendString:@"m"];
    }
    if (opts & PKPatternOptionsComments) {
        [optsString appendString:@"x"];
    }
    if (opts & PKPatternOptionsDotAll) {
        [optsString appendString:@"s"];
    }
    if (opts & PKPatternOptionsUnicodeWordBoundaries) {
        [optsString appendString:@"w"];
    }
    
    return [NSString stringWithFormat:@"/%@/%@", _string, optsString];
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitPattern:self];
}

@end
