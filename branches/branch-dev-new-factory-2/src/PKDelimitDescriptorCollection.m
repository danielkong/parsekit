//
//  PKDelimitDescriptorCollection.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/20/13.
//
//

#import "PKDelimitDescriptorCollection.h"
#import "PKDelimitDescriptor.h"

@interface PKDelimitDescriptorCollection ()
@property (nonatomic, retain) NSMutableDictionary *descTab;
@end

@implementation PKDelimitDescriptorCollection

- (id)init {
    self = [super init];
    if (self) {
        self.descTab = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self.descTab = nil;
    [super dealloc];
}


- (void)add:(PKDelimitDescriptor *)desc {
    NSParameterAssert(desc);

    NSString *key = desc.startMarker;
    NSAssert([key length], @"");

    NSMutableSet *existing = _descTab[key];
    if (!existing) {
        existing = [NSMutableSet set];
    }
    [existing addObject:desc];
}


- (void)remove:(PKDelimitDescriptor *)desc {
    NSParameterAssert(desc);
    
    NSString *key = desc.startMarker;
    NSAssert([key length], @"");
    
    NSMutableSet *existing = _descTab[key];
    NSAssert([existing containsObject:desc], @"");
    [existing removeObject:desc];
}

@end
