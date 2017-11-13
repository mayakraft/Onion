//
//  OpenCVWrapper.h
//  Onion
//
//  Created by Robby on 11/13/17.
//  Copyright © 2017 Robby Kraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

- (UIImage *) makeGray: (UIImage *) image;

@property (nonatomic) UIImage* storedImage;
-(UIImage *) differenceWithStoredImage:(UIImage*)image;


-(UIImage *) differenceBetween:(UIImage*)image1 and:(UIImage*)image2;

// test OpenCV - UIImage conversion
-(UIImage*) imageToCVAndBack:(UIImage*)image;

@end
