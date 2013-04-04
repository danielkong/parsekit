//
//  PKDelimitDescriptor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/20/13.
//
//

#import "PKDelimitDescriptor.h"

@implementation PKDelimitDescriptor

+ (PKDelimitDescriptor *)descriptorWithStartMarker:(NSString *)start endMarker:(NSString *)end characterSet:(NSCharacterSet *)cs tokenKind:(NSInteger)kind {
    PKDelimitDescriptor *desc = [[[[self class] alloc] init] autorelease];
    desc.startMarker = start;
    desc.endMarker = end;
    desc.characterSet = cs;
    desc.tokenKind = kind;
    return desc;
}


- (void)dealloc {
    self.startMarker = nil;
    self.endMarker = nil;
    self.characterSet = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKDelimitDescriptor *desc = NSAllocateObject([self class], 0, zone);
    desc->_startMarker = [_startMarker retain];
    desc->_endMarker = [_endMarker retain];
    desc->_characterSet = [_characterSet retain];
    desc->_tokenKind = _tokenKind;
    return desc;
}


- (BOOL)isEqual:(id)obj {
    if (![obj isMemberOfClass:[self class]]) {
        return NO;
    }
    
    PKDelimitDescriptor *desc = (PKDelimitDescriptor *)obj;

    if (![_startMarker isEqualToString:desc->_startMarker]) {
        return NO;
    }

    if (![_endMarker isEqualToString:desc->_endMarker]) {
        return NO;
    }

    if (![_characterSet isEqualTo:desc->_characterSet]) {
        return NO;
    }
    
    if (_tokenKind != desc->_tokenKind) {
        return NO;
    }
    
    return YES;
}


- (NSString *)description {
    NSString *fmt = nil;
#if defined(__LP64__)
    fmt = @"<%@ %p %@ %@ %ld>";
#else
    fmt = @"<%@ %p %@ %@ %d>";
#endif
    return [NSString stringWithFormat:fmt, [self class], self, _startMarker, _endMarker, _tokenKind];
}


@end
