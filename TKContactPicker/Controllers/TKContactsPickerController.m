//
//  TKContactsMultiPickerController.m
//  TKContactsMultiPicker
//
//  Created by Jongtae Ahn on 12. 8. 31..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.
//

#import "TKPeoplePickerController.h"
#import "TKContactsPickerController.h"
#import "NSString+TKUtilities.h"
#import "UIImage+TKUtilities.h"
#import "TKContactDetailViewController.h"

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
    NSMutableArray *contactsTemp = [NSMutableArray array];
    ABAddressBookRef addressBooks = [(TKPeoplePickerController*)self.navigationController addressBook];
    
    CFArrayRef allPeople;
    CFIndex peopleCount;
    if (_group) {
        self.title = _group.name;
        ABRecordRef groupRecord = ABAddressBookGetGroupWithRecordID(addressBooks, (ABRecordID)_group.recordID);
        allPeople = ABGroupCopyArrayOfAllMembers(groupRecord);
        peopleCount = (CFIndex)_group.membersCount;
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
        
        /*
         Save thumbnail image - performance decreasing
         UIImage *personImage = nil;
         if (person != nil && ABPersonHasImageData(person)) {
         if ( &ABPersonCopyImageDataWithFormat != nil ) {
         // iOS >= 4.1
         CFDataRef contactThumbnailData = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
         personImage = [[UIImage imageWithData:(NSData*)contactThumbnailData] thumbnailImage:CGSizeMake(44, 44)];
         CFRelease(contactThumbnailData);
         CFDataRef contactImageData = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatOriginalSize);
         CFRelease(contactImageData);
         
         } else {
         // iOS < 4.1
         CFDataRef contactImageData = ABPersonCopyImageData(person);
         personImage = [[UIImage imageWithData:(NSData*)contactImageData] thumbnailImage:CGSizeMake(44, 44)];
         CFRelease(contactImageData);
         }
         }
         [addressBook setThumbnail:personImage];
         */
        
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

- (id)initWithGroup:(TKGroup*)group
{
    if (self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil]) {
        self.group = group;
        _selectedCount = 0;
        _listContent = [NSMutableArray new];
        _filteredListContent = [NSMutableArray new];
    }
    return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    //self.edgesForExtendedLayout = UIRectEdgeAll;
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.navigationItem setLeftBarButtonItem:nil];
    [self.navigationItem setTitle:NSLocalizedString(@"Contacts", nil)];
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissAction:)]];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];

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
    _addressBook = [(TKPeoplePickerController*)self.navigationController addressBook];
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
       self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Groups", nil) style:UIBarButtonItemStyleDone target:self action:@selector(showGroups:)];
        [_noContactController.view removeFromSuperview];
 
        self.tableView.hidden = NO;

        _searchBar = [[UISearchBar alloc]initWithFrame:CGRectZero];
        _searchBar.delegate = self;
        [self.view addSubview:_searchBar];
        
        _searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = @{@"s":_searchBar,@"t":_tableView,
                                @"topLayoutGuide":self.topLayoutGuide,
                                @"bottomLayoutGuide":self.bottomLayoutGuide
                                };
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[s]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][s][t]" options:0 metrics:nil views:views]];
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
	static NSString *kCustomCellID = @"TKPeoplePickerControllerCell";
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
    }
	else
        contact = (TKContact *)[[_listContent objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if ([[contact.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
        cell.textLabel.text = contact.name;
    } else {
        cell.textLabel.font = [UIFont italicSystemFontOfSize:cell.textLabel.font.pointSize];
        cell.textLabel.text = @"No Name";
    }
		
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
        TKContactDetailViewController *detailViewController = [[TKContactDetailViewController alloc]initWithContact:[[_listContent objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:detailViewController animated:YES];
	}
}


- (void)checkButtonTapped:(id)sender event:(id)event
{
	NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.tableView];
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
	
	if (indexPath != nil)
	{
		[self tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
	}
}

#pragma mark -
#pragma mark Save action
- (void)showGroups:(id)sender
{
    TKGroupPickerController *groupContactController = [[TKGroupPickerController alloc] initWithNibName:NSStringFromClass([TKGroupPickerController class]) bundle:nil];
    groupContactController.addressbook =  [(TKPeoplePickerController*)self.navigationController addressBook];
    groupContactController.delegate = self;
    UINavigationController *navGroupController = [[UINavigationController alloc]initWithRootViewController:groupContactController];
    [self.navigationController presentViewController:navGroupController animated:YES completion:nil];
}


- (IBAction)dismissAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(tkContactsPickerControllerDidCancel:)])
        [self.delegate tkContactsPickerControllerDidCancel:self];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)_searchBar
{
	[self.searchDisplayController.searchBar setShowsCancelButton:YES];

}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{

}

- (void)searchBarCancelButtonClicked:(UISearchBar *)_searchBar
{
	[self.searchDisplayController setActive:NO animated:YES];
	[self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
	//[self.searchDisplayController setActive:NO animated:YES];
	//[self.tableView reloadData];
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

//- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
//{
//    CGRect frame = self.searchBar.frame;
//    frame.origin.y = 20;
//    [UIView beginAnimations:@"changeSearchBarFrame"context:NULL];
//    [UIView setAnimationDuration:0.1];
//    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
//    self.searchBar.frame = frame;
//    [UIView commitAnimations];
//}
//
//- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
//{
//    CGRect frame = self.searchBar.frame;
//    frame.origin.y = 64;
//    [UIView beginAnimations:@"changeSearchBarFrame"context:NULL];
//    [UIView setAnimationDuration:0.1];
//    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
//    self.searchBar.frame = frame;
//    [UIView commitAnimations];
//}

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