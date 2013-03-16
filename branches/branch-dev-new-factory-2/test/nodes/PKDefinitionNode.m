//
//  PKNodeDefinition.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import "PKDefinitionNode.h"

@implementation PKDefinitionNode

- (NSUInteger)type {
    return PKNodeTypeDefinition;
}


- (NSString *)name {
    NSString *str = [NSString stringWithFormat:@"$%@", self.parserName];
    return str;
}


- (void)visit:(id <PKNodeVisitor>)v; {
    [v visitDefinition:self];
}


//- (NSString *)fullTreeDescription:(NSDictionary *)symbolTab {
//    NSString *name = [self name];
//
//    if (![self.children count]) {
//        return name;
//    }
//    
//    NSMutableString *ms = [NSMutableString string];
//    
//    if (![self isNil]) {
//        [ms appendFormat:@"(%@", name];
//    }
//    
//    for (PKAST *child in self.children) {
//        NSAssert(child != self, @"");
//        [ms appendFormat:@" %@", [child fullTreeDescription:symbolTab]];
//    }
//    
//    if (![self isNil]) {
//        [ms appendString:@")"];
//    }
//    
//    return [[ms copy] autorelease];
//}

@end
