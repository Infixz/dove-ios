#import "TGDialogListCompanion.h"

@implementation TGDialogListCompanion

@synthesize dialogListController = _dialogListController;

@synthesize showListEditingControl = _showListEditingControl;
@synthesize forwardMode = _forwardMode;

@synthesize unreadCount = _unreadCount;
@synthesize unreadCountForGroup = _unreadCountForGroup;
@synthesize unreadCountForSingle = _unreadCountForSingle;

- (bool)showSecretInForwardMode
{
    return true;
}

- (id<TGDialogListCellAssetsSource>)dialogListCellAssetsSource
{
    return nil;
}

- (void)dialogListReady
{
    
}

- (void)clearData
{
    
}

- (void)loadItems
{
}

- (void)loadMoreItems
{
    
}

- (void)composeMessage
{
    
}

- (void)navigateToBroadcastLists
{
}

- (void)navigateToNewGroup
{
}

- (void)conversationSelected:(TGConversation *)__unused conversation
{
}

- (void)deleteItem:(TGConversation *)__unused conversation animated:(bool)__unused animated;
{
}

- (void)clearItem:(TGConversation *)__unused conversation animated:(bool)__unused animated
{
}

- (void)beginSearch:(NSString *)__unused queryString inMessages:(bool)__unused inMessages
{
    
}

- (void)searchResultSelectedUser:(TGUser *)__unused user
{
    
}

- (void)searchResultSelectedConversation:(TGConversation *)__unused conversation
{
    
}

- (void)searchResultSelectedConversation:(TGConversation *)__unused conversation atMessageId:(int)__unused messageId
{
    
}

- (void)searchResultSelectedMessage:(TGMessage *)__unused message
{
    
}

- (bool)shouldDisplayEmptyListPlaceholder
{
    return true;
}

- (void)wakeUp
{
    
}

- (void)resetLocalization
{
    
}

- (bool)isConversationOpened:(int64_t)__unused conversationId
{
    return false;
}

@end
