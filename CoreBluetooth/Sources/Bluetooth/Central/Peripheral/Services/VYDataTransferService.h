//
//  VYDataTransferService.h
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/24/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

#import "VYService.h"

typedef void (^VYDataTransferServiceResponseBlock)(NSData *responseData, NSError *error);

@interface VYDataTransferService : VYService

- (void)sendRequestData:(NSData *)requestData completion:(VYDataTransferServiceResponseBlock)block;

@end
