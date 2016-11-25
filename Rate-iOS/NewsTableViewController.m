//
//  NewsTableViewController.m
//  Rate-iOS
//
//  Created by 李大爷的电脑 on 25/11/2016.
//  Copyright © 2016 MuShare. All rights reserved.
//

#import "NewsTableViewController.h"
#import "InternetTool.h"

@interface NewsTableViewController ()

@end

@implementation NewsTableViewController {
    AFHTTPSessionManager *manager;
    NSArray *contents;
}

- (void)viewDidLoad {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    [super viewDidLoad];
    manager = [InternetTool getNewsSessionManager];
    
    [manager GET:BaiduNewsApi
      parameters:@{
                   @"title": @"货币",
                   @"channelId": @"5572a109b3cdc86cf39001e0"
                   }
        progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             NSObject *data = [NSJSONSerialization JSONObjectWithData:responseObject
                                                              options:NSJSONReadingAllowFragments
                                                                error:nil];
             NSObject *pagebean = [[data valueForKey:@"showapi_res_body"] valueForKey:@"pagebean"];
             contents = [pagebean valueForKey:@"contentlist"];
             [self.tableView reloadData];
         }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSObject *data = [NSJSONSerialization JSONObjectWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]
                                                              options:NSJSONReadingAllowFragments
                                                                error:nil];
             if (DEBUG) {
                 NSLog(@"Error with data: %@", data);
             }
         }];
}


#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return 0.1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return contents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newsIdentifier"
                                                            forIndexPath:indexPath];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:1];
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:2];
    UILabel *sourceLabel = (UILabel *)[cell viewWithTag:3];
    NSObject *content = [contents objectAtIndex:indexPath.row];
    titleLabel.text = [content valueForKey:@"title"];
    timeLabel.text = [content valueForKey:@"pubDate"];
    sourceLabel.text = [content valueForKey:@"source"];
    return cell;
}

@end
