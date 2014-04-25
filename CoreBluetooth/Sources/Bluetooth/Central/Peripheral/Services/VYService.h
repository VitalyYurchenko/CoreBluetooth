//
//  VYService.h
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/24/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

typedef void (^VYServiceDiscoverCharacteristicsBlock)(NSError *error);

@interface VYService : NSObject

@property (nonatomic, readonly) CBService *CBService;

@property (nonatomic, readonly) NSMutableDictionary *characteristics;

+ (instancetype)serviceWithCBService:(CBService *)cbService;
- (instancetype)initWithCBService:(CBService *)cbService;

- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs completion:(VYServiceDiscoverCharacteristicsBlock)block;

- (void)configure;
- (void)unconfigure;

// Handling CBPeripheral callbacks.
- (void)didDiscoverCharacteristicsWithError:(NSError *)error;

@end
