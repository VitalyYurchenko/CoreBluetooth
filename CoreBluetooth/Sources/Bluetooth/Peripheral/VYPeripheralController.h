//
//  VYPeripheralController.h
//  CoreBluetooth
//
//  Created by Vitaly Yurchenko on 4/14/14.
//  Copyright (c) 2014 Vitaly Yurchenko. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@interface VYPeripheralController : NSObject <CBPeripheralManagerDelegate>

@property (nonatomic, readonly) CBPeripheralManager *peripheralManager;

@end
