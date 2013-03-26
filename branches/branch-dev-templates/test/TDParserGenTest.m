//
//  TDParserGenTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import "TDParserGenTest.h"
#import "PKParserFactory.h"
#import "PKAST.h"

@interface TDParserGenTest ()
@property (nonatomic, retain) PKParserFactory *factory;
@end

@implementation TDParserGenTest

- (void)setUp {
    self.factory = [PKParserFactory factory];
}


- (void)tearDown {
    self.factory = nil;
}


- (void)testFoo {
}

@end
