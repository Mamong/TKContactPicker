//
//  TKContactsMultiPickerController.h
//  TKContactsMultiPicker
//
//  Created by Jongtae Ahn on 12. 8. 31..
//  Copyright (c) 2012년 TABKO Inc. All rights reserved.
//
//  Altered by Marco       on 15. 11.2..
//  Copyright (c) 2015 ET Inc. All rights reserved.


#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <malloc/malloc.h>
#import "TKContact.h"
#import "TKGroup.h"
#import "TKGroupPickerController.h"
#import "TKContactDetailViewController.h"

@class TKContact, TKContactsPickerController;
@protocol TKContactsPickerControllerDelegate <NSObject>

- (void)tkContactsPickerController:(TKContactsPickerController *)peoplePicker
                           didSelectContact:(TKContact*)contact
                                     index:(NSInteger)index
                                  property:(ABPropertyID)property
                                identifier:(ABMultiValueIdentifier)identifier;

- (void)tkContactsPickerController:(TKContactsPickerController *)peoplePicker
                  didSelectContact:(TKContact*)contact;

- (void)tkContactsPickerController:(TKContactsPickerController *)peoplePicker
                 didSelectContacts:(NSArray*)contacts;

- (void)tkContactsPickerControllerDidCancel:(TKContactsPickerController*)picker;

- (BOOL)tkContactsPickerControllerAllowMultiSelection:(TKContactsPickerController *)picker;
- (BOOL)tkContactsPickerController:(TKContactsPickerController *)picker
              shouldContinueAfterSelectingContact:(TKContact*)contact;
@end


@interface TKContactsPickerController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate,TKGroupPickerControllerDelegate,TKContactDetailViewControllerDelegate>
{
	id _delegate;
    
@private
    NSArray *_groups;
    NSUInteger _selectedCount;
    NSMutableArray *_listContent;
	NSMutableArray *_filteredListContent;
    NSLayoutConstraint *bottomConstraint;
    ABAddressBookRef _addressBook;
}

@property (nonatomic, retain) id<TKContactsPickerControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) NSArray *groups;
@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic) NSInteger savedScopeButtonIndex;
@property (nonatomic) BOOL searchWasActive;
@property(nonatomic,retain)UISearchDisplayController *searchController;


- (id)initWithGroups:(NSArray*)groups;

@end
