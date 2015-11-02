//
//  MCContactDetailViewController.h
//  TKContactPicker
//
//  Created by marco on 10/27/15.
//  Copyright © 2015 ET Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TKContact.h"

@interface TKContactDetailViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>


@property(retain,nonatomic) IBOutlet UITableView *tableView;
@property(retain,nonatomic) TKContact *displayedContact;
//@property(retain,nonatomic) NSArray   *displayedProperties;


- (id)initWithContact:(TKContact*)contact;
@end
