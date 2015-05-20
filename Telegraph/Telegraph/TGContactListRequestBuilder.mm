#import "TGContactListRequestBuilder.h"

#import "TGTelegraph.h"
#import "TGUser.h"

#import "TGDatabase.h"

#import "TGSchema.h"

#import "TGUserDataRequestBuilder.h"

#import "TGUser+Telegraph.h"

#import "ActionStage.h"
#import "SGraphObjectNode.h"

#import "TGAppDelegate.h"

#include <vector>

static NSDictionary *_cachedPhonebookForMainThread = nil;

static int _contactListVersion = 0;
static int _phonebookVersion = 0;

@interface TGContactListRequestBuilder ()

@end

@implementation TGContactListRequestBuilder

+ (NSString *)genericPath
{
    return @"/tg/contactlist/@";
}

+ (void)dispatchNewContactList
{
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        _contactListVersion++;
        NSDictionary *newCachedList = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_contactListVersion], @"version", [TGDatabaseInstance() loadContactUsers], @"contacts", nil];
        
        [ActionStageInstance() dispatchResource:@"/tg/contactlist" resource:[[SGraphObjectNode alloc] initWithObject:newCachedList]];
    }];
}

+ (void)dispatchNewPhonebook
{
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        _phonebookVersion++;
        
        NSDictionary *newPhonebook = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_phonebookVersion], @"version", [TGDatabaseInstance() loadPhonebookContacts], @"phonebook", nil];
        dispatch_async(dispatch_get_main_queue(), ^
        {
            _cachedPhonebookForMainThread = newPhonebook;
        });
        [ActionStageInstance() dispatchResource:@"/tg/phonebook" resource:[[SGraphObjectNode alloc] initWithObject:newPhonebook]];
    }];
}

+ (NSDictionary *)cachedPhonebook
{
    return _cachedPhonebookForMainThread;
}

+ (NSDictionary *)synchronousContactList
{
    NSDictionary *newCachedList = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_contactListVersion], @"version", [TGDatabaseInstance() loadContactUsers], @"contacts", nil];
    return newCachedList;
}

+ (void)clearCache
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        _cachedPhonebookForMainThread = nil;
    });
}

- (void)execute:(NSDictionary *)__unused options
{
    if ([self.path hasSuffix:@"phonebook)"])
    {
        NSDictionary *newPhonebook = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_phonebookVersion], @"version", [TGDatabaseInstance() loadPhonebookContacts], @"phonebook", nil];
        
        [ActionStageInstance() nodeRetrieved:self.path node:[[SGraphObjectNode alloc] initWithObject:newPhonebook]];
    }
    else
    {   
        NSArray *contactList = [TGDatabaseInstance() loadContactUsers];
        NSDictionary *newCachedList = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_contactListVersion], @"version", contactList, @"contacts", nil];
        
        [ActionStageInstance() nodeRetrieved:self.path node:[[SGraphObjectNode alloc] initWithObject:newCachedList]];
    }
}

@end
