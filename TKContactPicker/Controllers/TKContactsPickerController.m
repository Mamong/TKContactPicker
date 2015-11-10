//
//  TKContactsMultiPickerController.m
//  TKContactsMultiPicker
//
//  Created by Jongtae Ahn on 12. 8. 31..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.
//  Altered by Marco       on 15.11.  4..
//  Copyright (c) 2015 ET Inc. All rights reserved.


#import "TKPeoplePickerNavigationController.h"
#import "TKContactsPickerController.h"
#import "TKNoContactViewController.h"
#import "NSString+TKUtilities.h"
#import "UIImage+TKUtilities.h"
#import "TKPhoneItem.h"


@interface TKContactsPickerController(){
    TKNoContactViewController *_noContactController;
}

- (IBAction)doneAction:(id)sender;
- (IBAction)dismissAction:(id)sender;

@end

@implementation TKContactsPickerController
@synthesize tableView = _tableView;
@synthesize delegate = _delegate;
@synthesize savedSearchTerm = _savedSearchTerm;
@synthesize savedScopeButtonIndex = _savedScopeButtonIndex;
@synthesize searchWasActive = _searchWasActive;
@synthesize searchBar = _searchBar;

#pragma mark -
#pragma mark Craete addressbook ref

- (void)reloadAddressBook
{
    // Create addressbook data model
    [_listContent removeAllObjects];
    NSMutableArray *contactsTemp = [NSMutableArray array];
    ABAddressBookRef addressBooks = [(TKPeoplePickerNavigationController*)self.navigationController addressBook];
    
    CFArrayRef allPeople;
    CFIndex peopleCount;
    if (_groups) {
        self.title = [_groups count]==1? [(TKGroup*)[_groups objectAtIndex:0] name]:@"Multi";
        CFMutableArrayRef allPeopleM = CFArrayCreateMutable(NULL, 10, NULL);
        peopleCount = 0;
        for (TKGroup *group in _groups) {
            if (group.membersCount>0) {
                ABRecordRef groupRecord = ABAddressBookGetGroupWithRecordID(addressBooks, (ABRecordID)group.recordID);
                CFArrayRef groupPeople = ABGroupCopyArrayOfAllMembers(groupRecord);
                CFArrayAppendArray(allPeopleM, groupPeople, CFRangeMake(0, group.membersCount));
                peopleCount += group.membersCount;
                CFRelease(groupPeople);
            }
        }
        allPeople = CFArrayCreateCopy(NULL, allPeopleM);
        CFRelease(allPeopleM);
    } else {
        self.title = NSLocalizedString(@"All Contacts", nil);
        allPeople = ABAddressBookCopyArrayOfAllPeople(addressBooks);
        peopleCount = ABAddressBookGetPersonCount(addressBooks);
    }
    
    for (NSInteger i = 0; i < peopleCount; i++)
    {
        ABRecordRef contactRecord = CFArrayGetValueAtIndex(allPeople, i);
        
        // Thanks Steph-Fongo!
        if (!contactRecord) continue;
        
        CFStringRef abName = ABRecordCopyValue(contactRecord, kABPersonFirstNameProperty);
        CFStringRef abLastName = ABRecordCopyValue(contactRecord, kABPersonLastNameProperty);
        CFStringRef abFullName = ABRecordCopyCompositeName(contactRecord);
        TKContact *contact = [[TKContact alloc] init];
        contact.tels = [NSMutableArray arrayWithCapacity:1];
        
        //联系人头像
        if(ABPersonHasImageData(contactRecord))
        {
            //            NSData * imageData = ( NSData *)ABPersonCopyImageData(record);
            NSData * imageData = (__bridge NSData *)ABPersonCopyImageDataWithFormat(contactRecord,kABPersonImageFormatThumbnail);
            UIImage * image = [[UIImage alloc] initWithData:imageData];
            contact.thumbnail = image;
        }
         //Save thumbnail image - performance decreasing
//         UIImage *personImage = nil;
//         if (contactRecord != nil && ABPersonHasImageData(contactRecord)) {
//         if ( &ABPersonCopyImageDataWithFormat != nil ) {
//         // iOS >= 4.1
//         CFDataRef contactThumbnailData = ABPersonCopyImageDataWithFormat(contactRecord, kABPersonImageFormatThumbnail);
//         personImage = [[UIImage imageWithData:(__bridge NSData*)contactThumbnailData] thumbnailImage:CGSizeMake(44, 44)];
//         CFRelease(contactThumbnailData);
//         CFDataRef contactImageData = ABPersonCopyImageDataWithFormat(contactRecord, kABPersonImageFormatOriginalSize);
//         CFRelease(contactImageData);
//         
//         } else {
//         // iOS < 4.1
//         CFDataRef contactImageData = ABPersonCopyImageData(contactRecord);
//         personImage = [[UIImage imageWithData:(__bridge NSData*)contactImageData] thumbnailImage:CGSizeMake(44, 44)];
//         CFRelease(contactImageData);
//         }
//         }
//         [addressBook setThumbnail:personImage];
        
        
        NSString *fullNameString = nil;
        NSString *firstString = (__bridge NSString *)abName;
        NSString *lastNameString = (__bridge NSString *)abLastName;
        
        if ((__bridge id)abFullName != nil) {
            fullNameString = (__bridge NSString *)abFullName;
        } else {
            if (abLastName != NULL&&abName != NULL)
            {
                fullNameString = [NSString stringWithFormat:@"%@ %@", firstString, lastNameString];
            }else if (abName != NULL){
                fullNameString = firstString;
            }else if (abLastName != NULL){
                fullNameString = lastNameString;
            }
        }
        
        contact.name = fullNameString;
        contact.recordID = (int)ABRecordGetRecordID(contactRecord);
        contact.rowSelected = NO;
        contact.lastName = (__bridge NSString*)abLastName;
        contact.firstName = (__bridge NSString*)abName;
        
        ABPropertyID multiProperties[] = {
            kABPersonPhoneProperty,
            kABPersonEmailProperty
        };
        NSInteger multiPropertiesTotal = sizeof(multiProperties) / sizeof(ABPropertyID);
        for (NSInteger j = 0; j < multiPropertiesTotal; j++) {
            ABPropertyID property = multiProperties[j];
            ABMultiValueRef valuesRef = ABRecordCopyValue(contactRecord, property);
            NSInteger valuesCount = 0;
            if (valuesRef != nil) valuesCount = ABMultiValueGetCount(valuesRef);
            
            if (valuesCount == 0) {
                if(valuesRef!= NULL) CFRelease(valuesRef);
                continue;
            }
            
            for (NSInteger k = 0; k < valuesCount; k++) {
                CFStringRef value = ABMultiValueCopyValueAtIndex(valuesRef, k);
                CFStringRef label = ABMultiValueCopyLabelAtIndex(valuesRef, k);
                switch (j) {
                    case 0: {// Phone number
                        NSString *_label =nil;
                        if (label==NULL) {
                            _label = @"Phone";
                        }else{
                            _label = (__bridge_transfer NSString*)ABAddressBookCopyLocalizedLabel(label);
                        }
                        if (!contact.name) {
                            if (value!=NULL) {
                                contact.name = (__bridge NSString*)value;
                            }else
                                contact.name = @"";
                        }
                        [contact.tels addObject:[NSDictionary dictionaryWithObjectsAndKeys:_label,@"label",
                                                  (__bridge NSString*)value,@"value",nil]];
  //@{@"label":_label,@"value":(__bridge NSString*)value}];
                        break;
                    }
                    case 1: {// Email
                        contact.email = (__bridge NSString*)value;
                        break;
                    }
                }
                if(value) CFRelease(value);
                if(label) CFRelease(label);
            }
            CFRelease(valuesRef);
        }
        
        [contactsTemp addObject:contact];
        //[contact release];
        
        if (abName) CFRelease(abName);
        if (abLastName) CFRelease(abLastName);
        if (abFullName) CFRelease(abFullName);
    }
    
    if (allPeople) CFRelease(allPeople);
    
    // Sort data
    UILocalizedIndexedCollation *theCollation = [UILocalizedIndexedCollation currentCollation];
//    NSInteger sectionTitlesCount = [[theCollation sectionTitles] count];
//    NSLog(@"%ld, %@", (long)sectionTitlesCount, [theCollation sectionTitles]);

    
    // Thanks Steph-Fongo!
    SEL sorter = ABPersonGetSortOrdering() == kABPersonSortByFirstName ? NSSelectorFromString(@"sorterFirstName") : NSSelectorFromString(@"sorterLastName");
    
    for (TKContact *contact in contactsTemp) {
        NSInteger sect = [theCollation sectionForObject:contact
                                collationStringSelector:sorter];
        contact.sectionNumber = sect;
    }
    
    NSInteger highSection = [[theCollation sectionTitles] count];
    NSMutableArray *sectionArrays = [NSMutableArray arrayWithCapacity:highSection];
    for (int i=0; i<=highSection; i++) {
        NSMutableArray *sectionArray = [NSMutableArray arrayWithCapacity:1];
        [sectionArrays addObject:sectionArray];
    }
    
    for (TKContact *contact in contactsTemp) {
        if ([self pickerStyle]==TKPeoplePickerNavigationControllerStyleAllPhones) {
            for (NSDictionary *tel in contact.tels) {
                if (((NSString*)[tel objectForKey:@"value"]).length>0) {
                    TKContact *item = [[TKContact alloc]init];
                    item.firstName = contact.firstName;
                    item.lastName = contact.lastName;
                    item.name = contact.name;
                    item.tel = [tel objectForKey:@"value"];
                    item.telLabel = [tel objectForKey:@"label"];
                    item.thumbnail = contact.thumbnail;
                    [(NSMutableArray *)[sectionArrays objectAtIndex:contact.sectionNumber] addObject:item];
                }
            }
        }else
            [(NSMutableArray *)[sectionArrays objectAtIndex:contact.sectionNumber] addObject:contact];
    }
    
    for (NSMutableArray *sectionArray in sectionArrays) {
        NSArray *sortedSection = [theCollation sortedArrayFromArray:sectionArray collationStringSelector:sorter];
        [_listContent addObject:sortedSection];
    }
    [self.tableView reloadData];
}



#pragma mark -
#pragma mark Initialization

- (id)initWithGroups:(NSArray*)groups
{
    if (self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil]) {
        self.title = NSLocalizedString(@"All Contacts", nil);
        self.groups = groups;
        _selectedCount = 0;
        _listContent = [NSMutableArray new];
        _filteredListContent = [NSMutableArray new];
    }
    return self;
}

- (BOOL)allowMultiSelection
{
    if ([self.delegate respondsToSelector:@selector(tkContactsPickerControllerAllowMultiSelection:)]) {
        return [self.delegate tkContactsPickerControllerAllowMultiSelection:self];
    }
    return NO;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    //self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = YES;
    [self.navigationItem setLeftBarButtonItem:nil];
    [self.navigationItem setTitle:NSLocalizedString(@"All Contacts", nil)];
    
    if ([self allowMultiSelection]) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:
                                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)],
                                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissAction:)],
                                                   nil];
    }else{
       [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissAction:)]];
    }
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"TKContactAllPhonesCell" bundle:nil] forCellReuseIdentifier:@"ContactAllPhonesCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"TKContactListCell" bundle:nil] forCellReuseIdentifier:@"ContactListCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"TKContactAllPhonesMultiCell" bundle:nil] forCellReuseIdentifier:@"ContactAllPhonesMultiCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"TKContactListMultiCell" bundle:nil] forCellReuseIdentifier:@"ContactListMultiCell"];


    [self authenticateContact];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

- (void)authenticateContact
{
    _addressBook = [(TKPeoplePickerNavigationController*)self.navigationController addressBook];
    switch (ABAddressBookGetAuthorizationStatus()) {
        case kABAuthorizationStatusNotDetermined: {
            [self accessContactAuthenticated:NO];
            ABAddressBookRequestAccessWithCompletion(_addressBook, ^(bool granted, CFErrorRef error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        [self accessContactAuthenticated:YES];
                    }
                });
            });
        } break;
        case kABAuthorizationStatusAuthorized: {
            [self accessContactAuthenticated:YES];
        } break;
        case kABAuthorizationStatusDenied: {
            [self accessContactAuthenticated:NO];
        } break;
        case kABAuthorizationStatusRestricted: {
            [self accessContactAuthenticated:NO];
        } break;

        default: {
        } break;
    }
}

- (void)accessContactAuthenticated:(BOOL)authenticated
{
    if (authenticated) {
       self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Groups", nil) style:UIBarButtonItemStylePlain target:self action:@selector(showGroups:)];
        [_noContactController.view removeFromSuperview];
        
        UIEdgeInsets insets = self.tableView.contentInset;
        insets.top += 44;
        self.tableView.contentInset = insets;
        self.tableView.hidden = NO;

        _searchBar = [[UISearchBar alloc]initWithFrame:CGRectZero];
        _searchBar.delegate = self;
        [self.view addSubview:_searchBar];
        
        _searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = @{@"s":_searchBar,@"t":_tableView,
                                @"topLayoutGuide":self.topLayoutGuide,
                                };
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[s]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][s]" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[t]" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[t]|" options:0 metrics:nil views:views]];
        bottomConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        [self.view addConstraint:bottomConstraint];
        
        _searchController = [[UISearchDisplayController alloc]initWithSearchBar:_searchBar contentsController:self];
        _searchController.delegate = self;
        _searchController.searchResultsDataSource = self;
        _searchController.searchResultsDelegate = self;
        if (self.savedSearchTerm)
        {
            [self.searchDisplayController setActive:self.searchWasActive];
            [self.searchDisplayController.searchBar setText:_savedSearchTerm];
            
            self.savedSearchTerm = nil;
        }
        
        self.searchDisplayController.searchResultsTableView.scrollEnabled = YES;
        self.searchDisplayController.searchBar.showsCancelButton = NO;
        [self reloadAddressBook];

    }else{
        self.tableView.hidden = YES;
        self.navigationItem.leftBarButtonItem = nil;
        _noContactController = [[TKNoContactViewController alloc] initWithNibName:NSStringFromClass([TKNoContactViewController class]) bundle:nil];
        [self.view addSubview:_noContactController.view];
    }
}

// configure contact name
- (void)configureCell:(UITableViewCell *)cell forContact:(TKContact*)contact {

    UILabel *contactNameLabel = (UILabel *)[cell viewWithTag:101];
    
    if ([[contact.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        contactNameLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];
        NSString *stringToHightlight =
        contact.lastName.length>0 ? contact.lastName : contact.name;
        NSRange rangeToHightlight = [contact.name rangeOfString:stringToHightlight];
        NSMutableAttributedString *attributedString = [
                                                       [NSMutableAttributedString alloc] initWithString:contact.name];
        
        [attributedString beginEditing];
        [attributedString addAttribute:NSFontAttributeName
                                 value:[UIFont boldSystemFontOfSize:18]
                                 range:rangeToHightlight];
        [attributedString endEditing];
        contactNameLabel.attributedText = attributedString;
    }else{
        contactNameLabel.font = [UIFont italicSystemFontOfSize:cell.textLabel.font.pointSize];
        contactNameLabel.text = @"No Name";
    }
}

- (TKPeoplePickerNavigationControllerStyle)pickerStyle
{
    TKPeoplePickerNavigationControllerStyle style = ((TKPeoplePickerNavigationController*)self.navigationController).pickerStyle;
    return style;
}


#pragma mark -
#pragma mark UITableViewDataSource & UITableViewDelegate

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    } else {
        return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
//        return [[NSArray arrayWithObject:UITableViewIndexSearch] arrayByAddingObjectsFromArray:
//                [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles]];
   }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 0;
    } else {
        return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
//        if (title == UITableViewIndexSearch) {
//            [tableView scrollRectToVisible:self.searchDisplayController.searchBar.frame animated:NO];
//            return -1;
//        } else {
//            return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index-1];
//       }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
	} else {
        return [_listContent count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    } else {
        return [[_listContent objectAtIndex:section] count] ? [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section] : nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 0;
    return [[_listContent objectAtIndex:section] count] ? tableView.sectionHeaderHeight : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 44;
    }else
        return 67;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [_filteredListContent count];
    } else {
        return [[_listContent objectAtIndex:section] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCustomCellID = nil;
    TKPeoplePickerNavigationControllerStyle style = ((TKPeoplePickerNavigationController*)self.navigationController).pickerStyle;
    if ([self allowMultiSelection]) {
        if ( style== TKPeoplePickerNavigationControllerStyleAllPhones) {
            kCustomCellID = @"ContactAllPhonesMultiCell";
        }else if (style == TKPeoplePickerNavigationControllerStyleNormal){
            kCustomCellID = @"ContactListMultiCell";
        }
    }else
    {
        if ( style== TKPeoplePickerNavigationControllerStyleAllPhones) {
            kCustomCellID = @"ContactAllPhonesCell";
        }else if (style == TKPeoplePickerNavigationControllerStyleNormal){
            kCustomCellID = @"ContactListCell";
        }

    }
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCustomCellID];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCustomCellID];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	TKContact *contact = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView){
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        contact = (TKContact *)[_filteredListContent objectAtIndex:indexPath.row];
        cell.textLabel.tag = 101;
    }
	else
    {
        contact = (TKContact *)[[_listContent objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

        if ([self allowMultiSelection]) {
            //UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            //[button setFrame:CGRectMake(30.0, 0.0, 28, 28)];
            UIButton *button = (UIButton *)[cell viewWithTag:104];
            [button setBackgroundImage:[UIImage imageNamed:@"icon-checkbox-unselected-25x25"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"icon-checkbox-selected-green-25x25"] forState:UIControlStateSelected];
            [button addTarget:self action:@selector(checkButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
            [button setSelected:contact.rowSelected];
            //cell.accessoryView = button;
            
        }else{
            cell.textLabel.tag = 101;
            //cell.detailTextLabel.tag = 102;
        }
        
        if (style == TKPeoplePickerNavigationControllerStyleAllPhones) {
            UILabel *mobilePhoneNumberLabel = (UILabel *)[cell viewWithTag:102];
            mobilePhoneNumberLabel.text = contact.tel;
        }
        
        UIImageView *contactImage = (UIImageView *)[cell viewWithTag:103];
        if(contact.thumbnail) {
            contactImage.image = contact.thumbnail;
        }else{
            contactImage.image = [UIImage imageNamed:@"icon-avatar-60x60"];
        }
        contactImage.layer.masksToBounds = YES;
        contactImage.layer.cornerRadius = 20;

    }
    [self configureCell:cell forContact:contact];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		[self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:YES];
        TKContactDetailViewController *detailViewController = [[TKContactDetailViewController alloc]initWithContact:[_filteredListContent objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:detailViewController animated:YES];

	}
	else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

        if ([self allowMultiSelection]) {
            [self multipleContactTappedForRowWithIndexPath:indexPath];
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(tkContactsPickerController:shouldContinueAfterSelectingContact:)]) {
            if ([self.delegate tkContactsPickerController:self shouldContinueAfterSelectingContact:[[_listContent objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]]) {
                TKContactDetailViewController *detailViewController = [[TKContactDetailViewController alloc]initWithContact:[[_listContent objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
                detailViewController.addressBook = _addressBook;
                detailViewController.delegate = self;
                [self.navigationController pushViewController:detailViewController animated:YES];
                return;
            }
        }
        if ([self.delegate respondsToSelector:@selector(tkContactsPickerController:didSelectContact:)]){
            [self.delegate tkContactsPickerController:self didSelectContact:[[_listContent objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });

    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	TKContact *contact = nil;

	if (tableView == self.searchDisplayController.searchResultsTableView)
		contact = (TKContact*)[_filteredListContent objectAtIndex:indexPath.row];
	else
        contact = (TKContact*)[[_listContent objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

    TKContactDetailViewController *detailViewController = [[TKContactDetailViewController alloc]initWithContact:contact];
    detailViewController.addressBook = _addressBook;
    detailViewController.delegate = self;
    [self.navigationController pushViewController:detailViewController animated:YES];
}



- (void)checkButtonTapped:(id)sender event:(id)event
{
	NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.tableView];
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
	
	if (indexPath != nil)
	{
		[self multipleContactTappedForRowWithIndexPath:indexPath];
	}
}

- (void)multipleContactTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    TKContact *contact = (TKContact*)[[_listContent objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    BOOL checked = !contact.rowSelected;
    contact.rowSelected = checked;
    
    // Enabled rightButtonItem
    if (checked) _selectedCount++;
    else _selectedCount--;
//    if (_selectedCount > 0)
//        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)]];
//    else
//        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissAction:)]];
    
    UITableViewCell *cell =[self.tableView cellForRowAtIndexPath:indexPath];
    UIButton *button = (UIButton *)[cell viewWithTag:104];
    [button setSelected:checked];
}

#pragma mark -
#pragma mark Save action
- (void)showGroups:(id)sender
{
    TKGroupPickerController *groupContactController = [[TKGroupPickerController alloc] initWithNibName:NSStringFromClass([TKGroupPickerController class]) bundle:nil];
    groupContactController.addressbook =  [(TKPeoplePickerNavigationController*)self.navigationController addressBook];
    groupContactController.delegate = self;
    UINavigationController *navGroupController = [[UINavigationController alloc]initWithRootViewController:groupContactController];
    [self.navigationController presentViewController:navGroupController animated:YES completion:nil];
}


- (IBAction)dismissAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(tkContactsPickerControllerDidCancel:)])
        [self.delegate tkContactsPickerControllerDidCancel:self];
}

- (IBAction)doneAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(tkContactsPickerController:didSelectContacts:)]) {
        NSMutableArray *objects = [NSMutableArray new];
        for (NSArray *section in _listContent) {
            for (TKContact *contact in section)
            {
                if (contact.rowSelected)
                    [objects addObject:contact];
            }
        }
        [self.delegate tkContactsPickerController:self didSelectContacts:objects];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)_searchBar
{
	[self.searchDisplayController.searchBar setShowsCancelButton:YES];

}

- (void)searchBarCancelButtonClicked:(UISearchBar *)_searchBar
{
	[self.searchDisplayController setActive:NO animated:YES];
	[self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark -
#pragma mark ContentFiltering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	[_filteredListContent removeAllObjects];
    NSMutableArray *tempArr = [NSMutableArray arrayWithCapacity:1];
    for (NSArray *section in _listContent) {
        for (TKContact *contact in section)
        {
//            NSComparisonResult result = [contact.name compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
//            if (result == NSOrderedSame)
//            {
//                [tempArr addObject:contact];
//            }
            if (contact.name&&[contact.name rangeOfString:searchText].location!=NSNotFound) {
                [tempArr addObject:contact];
            }
        }
    }

        for (NSArray *section in _listContent) {
            for (TKContact *contact in section)
            {
                for (NSDictionary *dic in contact.tels) {
                    NSString *tel = [[dic objectForKey:@"value"]telephoneWithReformat];
                    if(tel&&[tel rangeOfString:searchText].location!= NSNotFound) {
                        [tempArr addObject:contact];
                        break;
                    }
                }
            }
        }
    [_filteredListContent addObjectsFromArray:tempArr];
}

#pragma mark -
#pragma mark UISearchDisplayControllerDelegate

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [tableView setContentInset:UIEdgeInsetsZero];
    [tableView setScrollIndicatorInsets:UIEdgeInsetsZero];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSString *keyword = [searchString stringByReplacingOccurrencesOfString:@" " withString:@""];
    [self filterContentForSearchText:keyword scope:
	 [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    NSString *keyword = [[self.searchDisplayController.searchBar text] stringByReplacingOccurrencesOfString:@" " withString:@""];
    [self filterContentForSearchText:keyword scope:
	 [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    return YES;
}

#pragma mark -
#pragma mark TKContactDetailViewController Delegate method
- (void)tkContactDetailViewController:(TKContactDetailViewController *)peoplePicker
                      didSelectPerson:(TKContact*)person
                                index:(NSInteger)index
                             property:(ABPropertyID)property
                           identifier:(ABMultiValueIdentifier)identifier
{
    if ([self.delegate respondsToSelector:@selector(tkContactsPickerController:didSelectContact:index:property:identifier:)]) {
        [self.delegate tkContactsPickerController:self didSelectContact:person index:index property:property identifier:identifier];
    }
}

#pragma mark -
#pragma mark TKGroupPickerController Delegate method
- (void)tkGroupPickerController:(TKGroupPickerController *)picker didSelectGroups:(NSArray *)groups
{
    _groups = groups;
    [self reloadAddressBook];
}



#pragma mark -
#pragma mark Keyboard notification
- (void)keyboardWillShow:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    
    NSValue *animationCurveObject =[userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    NSValue *animationDurationObject =[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    NSValue *keyboardEndRectObject =[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    
    NSUInteger animationCurve = 0;
    
    double animationDuration = 0.0f;
    
    CGRect keyboardEndRect = CGRectMake(0,0, 0, 0);
    
    [animationCurveObject getValue:&animationCurve];
    
    [animationDurationObject getValue:&animationDuration];
    
    [keyboardEndRectObject getValue:&keyboardEndRect];
    
    [UIView beginAnimations:@"changeTableViewContentInset"
     
                    context:NULL];
    
    [UIView setAnimationDuration:animationDuration];
    
    [UIView setAnimationCurve:(UIViewAnimationCurve)animationCurve];
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate]window];
    
    CGRect intersectionOfKeyboardRectAndWindowRect = CGRectIntersection(window.frame, keyboardEndRect);
    
    CGFloat bottomInset = intersectionOfKeyboardRectAndWindowRect.size.height;
    
    bottomConstraint.constant = bottomInset;
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification*)notification
{

    
    NSDictionary *userInfo = [notification userInfo];
    
    NSValue *animationCurveObject =[userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    NSValue *animationDurationObject = [userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    NSValue *keyboardEndRectObject =[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    
    NSUInteger animationCurve = 0;
    double animationDuration =0.0f;
    
    CGRect keyboardEndRect = CGRectMake(0,0, 0, 0);
    
    [animationCurveObject getValue:&animationCurve];
    
    [animationDurationObject getValue:&animationDuration];
    
    [keyboardEndRectObject getValue:&keyboardEndRect];
    
    [UIView beginAnimations:@"changeTableViewContentInset"context:NULL];
    
    [UIView setAnimationDuration:animationDuration];
    
    [UIView setAnimationCurve:(UIViewAnimationCurve)animationCurve];
    bottomConstraint.constant = 0;
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}



@end