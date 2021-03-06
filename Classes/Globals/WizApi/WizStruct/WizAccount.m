//
//  WizAccount.m
//  Wiz
//
//  Created by 朝 董 on 12-6-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "WizAccount.h"
#import "WizAccountManager.h"
#define KeyOfUserId                 @"userId"
#define KeyOfPassword               @"password"
#define KeyOfKbguids                @"KeyOfKbguids"
@implementation WizAccount
@synthesize userId;
@synthesize password;
@synthesize groups;
- (void) dealloc
{
    [userId release];
    [password release];
    [groups release];
    [super dealloc];
}

- (WizAccount*) initWithUserId:(NSString*)userId_  password:(NSString*)password_  kgguids:(NSArray*)kbguids_
{
    self = [super init];
    if (self) {
        self.userId = userId_;
        self.password = password_;
        if (!kbguids_) {
            self.groups = [NSArray array];
        }
        else {
            self.groups = kbguids_;
        }
    }
    return self;
}

- (WizAccount*) initAccountFromDic:(NSDictionary*)dic
{
    self = [super init];
    if(self)
    {
        self.userId = [dic valueForKey:KeyOfUserId];
        self.password = [dic valueForKey:KeyOfPassword];
        NSArray* array = [dic valueForKey:KeyOfKbguids];
        if (array == nil) {
            self.groups = [NSArray array];
        }
        else {
            self.groups = array;
        }
    }
    return self;
}

- (NSDictionary*) accountDictionaryData
{
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithCapacity:3];
    [dic setObject:self.userId forKey:KeyOfUserId];
    [dic setObject:self.password forKey:KeyOfPassword];
    [dic setObject:self.groups forKey:KeyOfKbguids];
    return dic;
}
- (BOOL) isEqualToAccountDictionaryData:(NSDictionary*)data
{
    NSString* userIDD = [data valueForKey:KeyOfUserId];
    if (!userIDD) {
        return NO;
    }
    if ([userIDD isEqualToString:self.userId]) {
        return YES;
    }
    return NO;
}
@end
