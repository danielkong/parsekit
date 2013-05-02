//
//  PKSTreeAdaptor.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 5/1/13.
//
//

#import "PKSTreeAdaptor.h"
#import <ParseKit/PKAST.h>

@interface PKSTreeAdaptor ()
@property (nonatomic, retain) Class treeClass;
@end

@implementation PKSTreeAdaptor

+ (PKSTreeAdaptor *)treeAdaptor {
    return [self treeAdaptorWithTreeClass:[PKAST class]];
}


+ (PKSTreeAdaptor *)treeAdaptorWithTreeClass:(Class)cls {
    PKSTreeAdaptor *ator = [[[self alloc] initWithTreeClass:cls] autorelease];
    return ator;
}


- (id)initWithTreeClass:(Class)cls {
    self = [super init];
    if (self) {
        self.treeClass = cls;
    }
    return self;
}


- (void)dealloc {
    self.treeClass = nil;
    [super dealloc];
}


- (PKAST *)newTree {
    return [[_treeClass alloc] init];
}

@end
