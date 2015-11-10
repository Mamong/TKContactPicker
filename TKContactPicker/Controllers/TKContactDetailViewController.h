//
//  MCContactDetailViewController.h
//  TKContactPicker
//
//  Created by marco on 10/27/15.
//  Copyright © 2015 ET Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "TKContact.h"


@class TKContactDetailViewController;
@protocol TKContactDetailViewControllerDelegate <NSObject>

- (void)tkContactDetailViewController:(TKContactDetailViewController *)peoplePicker
                   didSelectPerson:(TKContact*)person
                                index:(NSInteger)index
                          property:(ABPropertyID)property
                        identifier:(ABMultiValueIdentifier)identifier;

@end

@interface TKContactDetailViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, assign) ABAddressBookRef addressBook;
@property(weak,nonatomic)id<TKContactDetailViewControllerDelegate> delegate;
@property(retain,nonatomic) IBOutlet UITableView *tableView;
@property(retain,nonatomic) TKContact *displayedContact;
//@property(retain,nonatomic) NSArray   *displayedProperties;


- (id)initWithContact:(TKContact*)contact;
@end
