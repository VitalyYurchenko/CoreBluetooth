//
//  VYCharacteristic.h
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/25/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

typedef void (^VYCharacteristicUpdateValueBlock)(NSData *value, NSError *error);
typedef void (^VYCharacteristicWriteValueBlock)(NSData *value, NSError *error);
typedef void (^VYCharacteristicUpdateNotificationStateBlock)(BOOL isNotifying, NSError *error);

@interface VYCharacteristic : NSObject

@property (nonatomic, readonly) CBCharacteristic *CBCharacteristic;

+ (instancetype)characteristicWithCBCharacteristic:(CBCharacteristic *)cbCharacteristic;
- (instancetype)initWithCBCharacteristic:(CBCharacteristic *)cbCharacteristic;

- (void)setUpdateValueBlock:(VYCharacteristicUpdateValueBlock)block;

- (void)readValueWithCompletion:(VYCharacteristicUpdateValueBlock)block;
- (void)writeValue:(NSData *)value completion:(VYCharacteristicWriteValueBlock)block;
- (void)setNotifyValue:(BOOL)enabled completion:(VYCharacteristicUpdateNotificationStateBlock)block;

// Handling CBPeripheral callbacks.
- (void)didUpdateValueWithError:(NSError *)error;
- (void)didWriteValueWithError:(NSError *)error;
- (void)didUpdateNotificationStateWithError:(NSError *)error;

@end
