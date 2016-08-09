//
//  SubscribeTableViewController.m
//  Rate-iOS
//
//  Created by lidaye on 8/1/16.
//  Copyright © 2016 MuShare. All rights reserved.
//

#import "SubscriptionsTableViewController.h"
#import "InternetTool.h"
#import "UserTool.h"
#import <SVGKit/SVGKit.h>

@interface SubscriptionsTableViewController ()

@end

@implementation SubscriptionsTableViewController {
    AFHTTPSessionManager *manager;
    UserTool *user;
    DaoManager *dao;
    Subscribe *selectedSubscribe;
}

- (void)viewDidLoad {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    [super viewDidLoad];
    user = [[UserTool alloc] init];
    dao = [[DaoManager alloc] init];
    
    _fetchedResultsController = [dao.subscribeDao fetchedResultsControllerForAll];
    
}

- (void)viewWillAppear:(BOOL)animated {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    //subscribes = [dao.subscribeDao findAll];
    
    manager = [InternetTool getSessionManagerForJSON];
    
    //Prepare sids for updating.
    NSMutableArray *sids = [[NSMutableArray alloc] init];
    for(Subscribe *subscribe in [dao.subscribeDao findAll]) {
        [sids addObject:subscribe.sid];
    }
    
    [manager PUT:[InternetTool createUrl:@"api/user/subscribes"]
      parameters:@{
                   @"rev": [NSNumber numberWithInteger:user.subscribeRev],
                   @"sids": sids
                   }
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             InternetResponse *response = [[InternetResponse alloc] initWithResponseObject:responseObject];
             if([response statusOK]) {
                 NSObject *result = [response getResponseResult];
                 NSObject *data = [result valueForKey:@"data"];
                 //Update subscribe table when it is updated.
                 if([[result valueForKey:@"isUpdated"] boolValue]) {
                     for(NSObject *subscribeObject in [data valueForKey:@"createdOrUpdated"]) {
                         [dao.subscribeDao saveOrUpdateWithJSONObject:subscribeObject];
                     }
                     for(NSString *deletedSid in [data valueForKey:@"deletedSubcribes"]) {
                         [dao.subscribeDao deleteBySid:deletedSid];
                     }
                 }
                 
                 //Update rates of subscribe.
                 NSDictionary *rates = [data valueForKey:@"rates"];
                 for(NSString *sid in rates.allKeys) {
                     NSLog(@"%@ %@", sid, rates[sid]);
                     Subscribe *subscribe = [dao.subscribeDao getBySid:sid];
                     subscribe.rate = [NSNumber numberWithFloat:[rates[sid] floatValue]];
                 }
                 [dao saveContext];
                 
                 //Update current revision of subscribe.
                 user.subscribeRev = [[result valueForKey:@"current"] integerValue];
                 
                 //Refresh table view.
                 _fetchedResultsController = [dao.subscribeDao fetchedResultsControllerForAll];
                 [self.tableView reloadData];
             }
         }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             if(DEBUG) {
                 NSLog(@"Server error: %@", error.localizedDescription);
             }
             InternetResponse *response = [[InternetResponse alloc] initWithError:error];
             switch ([response errorCode]) {
                     
                 default:
                     if (DEBUG) {
                         NSLog(@"Error code is %d", [response errorCode]);
                     }
                     break;
             }
         }];
}

#pragma mark - UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return 0.01;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if (user.token == nil) {
        return 1;
    }
    return [_fetchedResultsController.sections[0] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    //If user is not login, show login button for him.
    if(user.token == nil) {
        return [tableView dequeueReusableCellWithIdentifier:@"subscriptionUnloginIdentifer"];
    }
    
    Subscribe *subscribe = [_fetchedResultsController objectAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"subscribeIdentifer"];

    UILabel *snameLabel = (UILabel *)[cell viewWithTag:1];
    SVGKFastImageView *fromImageView = (SVGKFastImageView *)[cell viewWithTag:2];
    SVGKFastImageView *toImageView = (SVGKFastImageView *)[cell viewWithTag:3];
    UILabel *currentRateLabel = (UILabel *)[cell viewWithTag:4];
    UILabel *thredholdLabel = (UILabel *)[cell viewWithTag:5];
    
    snameLabel.text = subscribe.sname;
    fromImageView.image = [SVGKImage imageNamed:[NSString stringWithFormat:@"%@.svg", subscribe.from.icon]];
    toImageView.image = [SVGKImage imageNamed:[NSString stringWithFormat:@"%@.svg", subscribe.to.icon]];
    currentRateLabel.text = [NSString stringWithFormat:@"%.3f", subscribe.rate.floatValue];
    thredholdLabel.text = [NSString stringWithFormat:@"%.3f", subscribe.threshold.floatValue];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    selectedSubscribe = [_fetchedResultsController objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"subscriptionSegue" sender:self];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if([segue.identifier isEqualToString:@"subscriptionSegue"]) {
        [segue.destinationViewController setValue:selectedSubscribe forKey:@"subscribe"];
    }
}

#pragma mark - Action
- (IBAction)addSubscribe:(id)sender {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if(user.token == nil) {
        //If user is unlogin, push to LoginViewController
        [self performSegueWithIdentifier:@"addSubscribeUnloginSegue" sender:self];
    } else {
        [self performSegueWithIdentifier:@"addSubscribeSegue" sender:self];
    }
}

@end
