//
//  VYPeripheral.h
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/16/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@interface VYPeripheral : NSObject <CBPeripheralDelegate>

@property (nonatomic, readonly) CBPeripheral *CBPeripheral;

@property (nonatomic, readonly) NSMutableDictionary *services;

+ (instancetype)peripheralWithCBPeripheral:(CBPeripheral *)cbPeripheral;
- (instancetype)initWithCBPeripheral:(CBPeripheral *)cbPeripheral;

- (void)sendRequestData:(NSData *)requestData completion:(void (^)(NSData *responseData, NSError *error))handler;

- (BOOL)isConnected;

// Handling CBCentralManager callbacks.
- (void)didConnect;
- (void)didFailToConnectWithError:(NSError *)error;
- (void)didDisconnectWithError:(NSError *)error;

@end
