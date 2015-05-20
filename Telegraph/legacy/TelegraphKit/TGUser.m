#import "TGUser.h"

#import "TGStringUtils.h"
#import "TGPhoneUtils.h"

#import "NSObject+TGLock.h"

#import "TGNotificationPrivacyAccountSetting.h"
#import "TGDatabase.h"

@interface TGUser ()
{
    bool _contactIdInitialized;
    bool _formattedPhoneInitialized;
    
    TG_SYNCHRONIZED_DEFINE(_cachedValues);
}

@property (nonatomic, strong) NSString *cachedFormattedNumber;

@end

@implementation TGUser

- (id)copyWithZone:(NSZone *)__unused zone
{
    TGUser *user = [[TGUser alloc] init];
    
    user.uid = _uid;
    user.phoneNumber = _phoneNumber;
    user.phoneNumberHash = _phoneNumberHash;
    user.firstName = _firstName;
    user.lastName = _lastName;
    user.userName = _userName;
    user.phonebookFirstName = _phonebookFirstName;
    user.phonebookLastName = _phonebookLastName;
    user.sex = _sex;
    user.photoUrlSmall = _photoUrlSmall;
    user.photoUrlMedium = _photoUrlMedium;
    user.photoUrlBig = _photoUrlBig;
    user.presence = _presence;
    user.customProperties = _customProperties;
    user.contactId = _contactId;
    user->_contactIdInitialized = _contactIdInitialized;
    user->_formattedPhoneInitialized = _formattedPhoneInitialized;
    user.cachedFormattedNumber = _cachedFormattedNumber;
    
    return user;
}

- (bool)hasAnyName
{
    return _firstName.length != 0 || _lastName.length != 0 || _phonebookFirstName.length != 0 || _phonebookLastName.length != 0;
}

//qi.zhang modify
- (TGUserNations)nation
{
    if (_nation == TGUserNationUnknown) {
        NSString *name = [[self checkedLastName] stringByAppendingString:[self checkedFirstName]];
        BOOL zh = NO;
        for (NSUInteger i=0; i<name.length; i++) {
            int a = [name characterAtIndex:i];
            if (a > 0x4e00 && a < 0x9fff) {
                zh = YES;
                break;
            }
        }
        _nation = zh?TGUserNationChinese:TGUserNationOther;
    }
    return _nation;
}

- (NSString *)firstName
{
    if (self.nation == TGUserNationChinese) {
        return [self checkedLastName];
    }else{
        return [self checkedFirstName];
    }
}

- (NSString *)lastName
{
    if (self.nation == TGUserNationChinese) {
        return [self checkedFirstName];
    }else{
        return [self checkedLastName];
    }
}

- (NSString *)checkedFirstName
{
    _checkedFirstName = (_phonebookFirstName.length != 0 || _phonebookLastName.length != 0) ? _phonebookFirstName : ((_firstName.length != 0 || _lastName.length != 0) ? _firstName : (_phoneNumber.length == 0 ? @"Name Hidden" : [self formattedPhoneNumber]));
    return _checkedFirstName;
}

- (NSString *)checkedLastName
{
    _checkedLastName = (_phonebookFirstName.length != 0 || _phonebookLastName.length != 0) ? _phonebookLastName : ((_firstName.length != 0 || _lastName.length != 0) ? _lastName : nil);
    return _checkedLastName;
}
//

- (NSString *)realFirstName
{
    return _firstName;
}

- (NSString *)realLastName
{
    return _lastName;
}

- (NSString *)displayName
{
    NSString *firstName = self.firstName;
    NSString *lastName = self.lastName;
    
    if (firstName != nil && firstName.length != 0 && lastName != nil && lastName.length != 0)
    {
        if (TGIsKorean())
            return [[NSString alloc] initWithFormat:@"%@ %@", lastName, firstName];
        else
            return [[NSString alloc] initWithFormat:@"%@ %@", firstName, lastName];
    }
    else if (firstName != nil && firstName.length != 0)
        return firstName;
    else if (lastName != nil && lastName.length != 0)
        return lastName;
    
    return @"";
}

- (NSString *)displayRealName
{
    NSString *firstName = self.realFirstName;
    NSString *lastName = self.realLastName;
    
    if (firstName != nil && firstName.length != 0 && lastName != nil && lastName.length != 0)
        return [[NSString alloc] initWithFormat:@"%@ %@", firstName, lastName];
    else if (firstName != nil && firstName.length != 0)
        return firstName;
    else if (lastName != nil && lastName.length != 0)
        return lastName;
    
    return @"";
}

- (NSString *)displayFirstName
{
    NSString *firstName = self.firstName;
    if (firstName.length != 0)
        return firstName;
    
    return self.lastName;
}

- (NSString *)compactName
{
    NSString *firstName = self.firstName;
    NSString *lastName = self.lastName;
    
    if (firstName != nil && firstName.length != 0 && lastName != nil && lastName.length != 0)
        return [[NSString alloc] initWithFormat:@"%@.%@", [firstName substringToIndex:1], lastName];
    else if (firstName != nil && firstName.length != 0)
        return firstName;
    else if (lastName != nil && lastName.length != 0)
        return lastName;
    
    return @"";
}

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    TG_SYNCHRONIZED_BEGIN(_cachedValues);
    _phoneNumber = phoneNumber;
    _contactIdInitialized = false;
    _formattedPhoneInitialized = false;
    TG_SYNCHRONIZED_END(_cachedValues);
}

- (int)contactId
{
    if (!_contactIdInitialized)
    {
        int contactId = 0;
        if (_phoneNumber != nil && _phoneNumber.length != 0)
            contactId = phoneMatchHash(_phoneNumber);
        
        TG_SYNCHRONIZED_BEGIN(_cachedValues);
        _contactId = contactId;
        _contactIdInitialized = true;
        TG_SYNCHRONIZED_END(_cachedValues);
    }
    
    return _contactId;
}

- (NSString *)formattedPhoneNumber
{
    if (_formattedPhoneInitialized)
        return _cachedFormattedNumber;
    else
    {
        NSString *cachedFormattedNumber = nil;
        if (_phoneNumber.length != 0)
            cachedFormattedNumber = [TGPhoneUtils formatPhone:_phoneNumber forceInternational:true];
        
        TG_SYNCHRONIZED_BEGIN(_cachedValues);
        _cachedFormattedNumber = cachedFormattedNumber;
        _formattedPhoneInitialized = true;
        TG_SYNCHRONIZED_END(_cachedValues);
        
        return cachedFormattedNumber;
    }
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[TGUser class]] && [self isEqualToUser:object];
}

- (bool)isEqualToUser:(TGUser *)anotherUser
{
    if (anotherUser.uid == _uid &&
        ((anotherUser.realFirstName == nil && _firstName == nil) || [anotherUser.realFirstName isEqualToString:_firstName]) &&
        ((anotherUser.realLastName == nil && _lastName == nil) || [anotherUser.realLastName isEqualToString:_lastName]) &&
        anotherUser.sex == _sex &&
        ((anotherUser.phonebookFirstName == nil && _phonebookFirstName == nil) || [anotherUser.phonebookFirstName isEqualToString:_phonebookFirstName]) &&
        ((anotherUser.phonebookLastName == nil && _phonebookLastName == nil) || [anotherUser.phonebookLastName isEqualToString:_phonebookLastName]) &&
        ((anotherUser.phoneNumber == nil && _phoneNumber == nil) || [anotherUser.phoneNumber isEqualToString:_phoneNumber]) &&
        anotherUser.phoneNumberHash == _phoneNumberHash &&
        ((anotherUser.photoUrlSmall == nil && _photoUrlSmall == nil) || [anotherUser.photoUrlSmall isEqualToString:_photoUrlSmall]) &&
        ((anotherUser.photoUrlMedium == nil && _photoUrlMedium == nil) || [anotherUser.photoUrlMedium isEqualToString:_photoUrlMedium]) &&
        ((anotherUser.photoUrlBig == nil && _photoUrlBig == nil) || [anotherUser.photoUrlBig isEqualToString:_photoUrlBig]) &&
        anotherUser.presence.online == _presence.online && anotherUser.presence.lastSeen == _presence.lastSeen && TGStringCompare(_userName, anotherUser.userName))
    {
        return true;
    }
    return false;
}

- (int)differenceFromUser:(TGUser *)anotherUser
{
    int difference = 0;
    
    if (_uid != anotherUser.uid)
        difference |= TGUserFieldUid;
    
    if ((_phoneNumber == nil) != (anotherUser.phoneNumber == nil) || (_phoneNumber != nil && ![_phoneNumber isEqualToString:anotherUser.phoneNumber]))
        difference |= TGUserFieldPhoneNumber;
    
    if (_phoneNumberHash != anotherUser.phoneNumberHash)
        difference |= TGUserFieldPhoneNumberHash;
    
    if ((_firstName == nil) != (anotherUser.realFirstName == nil) || (_firstName != nil && ![_firstName isEqualToString:anotherUser.realFirstName]))
        difference |= TGUserFieldFirstName;
    
    if ((_lastName == nil) != (anotherUser.realLastName == nil) || (_lastName != nil && ![_lastName isEqualToString:anotherUser.realLastName]))
        difference |= TGUserFieldLastName;
    
    if (!TGStringCompare(_userName, anotherUser.userName))
        difference |= TGUserFieldUsername;
    
    if ((_phonebookFirstName == nil) != (anotherUser.phonebookFirstName == nil) || (_phonebookFirstName != nil && ![_phonebookFirstName isEqualToString:anotherUser.phonebookFirstName]))
        difference |= TGUserFieldPhonebookFirstName;
    
    if ((_phonebookLastName == nil) != (anotherUser.phonebookLastName == nil) || (_phonebookLastName != nil && ![_phonebookLastName isEqualToString:anotherUser.phonebookLastName]))
        difference |= TGUserFieldPhonebookLastName;
    
    if (_sex != anotherUser.sex)
        difference |= TGUserFieldSex;
    
    if ((_photoUrlSmall == nil) != (anotherUser.photoUrlSmall == nil) || (_photoUrlSmall != nil && ![_photoUrlSmall isEqualToString:anotherUser.photoUrlSmall]))
        difference |= TGUserFieldPhotoUrlSmall;
    
    if ((_photoUrlMedium == nil) != (anotherUser.photoUrlMedium == nil) || (_photoUrlMedium != nil && ![_photoUrlMedium isEqualToString:anotherUser.photoUrlMedium]))
        difference |= TGUserFieldPhotoUrlMedium;
    
    if ((_photoUrlBig == nil) != (anotherUser.photoUrlBig == nil) || (_photoUrlBig != nil && ![_photoUrlBig isEqualToString:anotherUser.photoUrlBig]))
        difference |= TGUserFieldPhotoUrlBig;
    
    if (_presence.lastSeen != anotherUser.presence.lastSeen)
        difference |= TGUserFieldPresenceLastSeen;
    
    if (_presence.online != anotherUser.presence.online)
        difference |= TGUserFieldPresenceOnline;
    
    return difference;
}

+ (TGUserPresence)approximatePresenceFromPresence:(TGUserPresence)presence currentTime:(NSTimeInterval)currentTime
{
    if (presence.lastSeen <= 0)
        return presence;
    
    if (presence.lastSeen >= (int)(currentTime - 60 * 60 * 24 * 4))
        return (TGUserPresence){.online = false, .lastSeen = TGUserPresenceValueLately, .temporaryLastSeen = 0};
    else if (presence.lastSeen >= (int)(currentTime - 60 * 60 * 24 * 4))
        return (TGUserPresence){.online = false, .lastSeen = TGUserPresenceValueWithinAWeek, .temporaryLastSeen = 0};
    else if (presence.lastSeen >= (int)(currentTime - 60 * 60 * 24 * 31))
        return (TGUserPresence){.online = false, .lastSeen = TGUserPresenceValueWithinAMonth, .temporaryLastSeen = 0};
    
    return (TGUserPresence){.online = false, .lastSeen = TGUserPresenceValueALongTimeAgo, .temporaryLastSeen = 0};
}

- (TGUser *)applyPrivacyRules:(TGNotificationPrivacyAccountSetting *)privacyRules currentTime:(NSTimeInterval)currentTime
{
    if (privacyRules == nil)
        return self;
    
    bool approximatePresenceRequired = false;
    
    switch (privacyRules.lastSeenPrimarySetting)
    {
        case TGPrivacySettingsLastSeenPrimarySettingEverybody:
            if ([privacyRules.neverShareWithUserIds containsObject:@(_uid)])
                approximatePresenceRequired = true;
            break;
        case TGPrivacySettingsLastSeenPrimarySettingContacts:
            if ([TGDatabaseInstance() uidIsRemoteContact:_uid])
            {
                if ([privacyRules.neverShareWithUserIds containsObject:@(_uid)])
                    approximatePresenceRequired = true;
            }
            else
            {
                if (![privacyRules.alwaysShareWithUserIds containsObject:@(_uid)])
                    approximatePresenceRequired = true;
            }
            break;
        case TGPrivacySettingsLastSeenPrimarySettingNobody:
            if (![privacyRules.alwaysShareWithUserIds containsObject:@(_uid)])
                approximatePresenceRequired = true;
            break;
    }
    
    if (approximatePresenceRequired)
    {
        TGUser *user = [self copy];
        user.presence = [TGUser approximatePresenceFromPresence:self.presence currentTime:currentTime];
        return user;
    }
    
    return self;
}

@end
