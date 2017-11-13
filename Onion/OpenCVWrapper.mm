//
//  OpenCVWrapper.m
//  Onion
//
//  Created by Robby on 11/13/17.
//  Copyright © 2017 Robby Kraft. All rights reserved.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

// Compare two images by getting the L2 error (square-root of sum of squared error).
double getSimilarity( const Mat A, const Mat B ) {
	if ( A.rows > 0 && A.rows == B.rows && A.cols > 0 && A.cols == B.cols ) {
		// Calculate the L2 relative error between images.
		double errorL2 = norm( A, B, CV_L2 );
		// Convert to a reasonable scale, since L2 error is summed across all pixels of the image.
		double similarity = errorL2 / (double)( A.rows * A.cols );
		return similarity;
	}
	else {
		//Images have a different size
		return 100000000.0;  // Return a bad value
	}
}

@implementation OpenCVWrapper

-(cv::Mat)cvMatFromUIImage:(UIImage *)image
{
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
	CGFloat cols = image.size.width;
	CGFloat rows = image.size.height;
	
	cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
	
	CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
													cols,                       // Width of bitmap
													rows,                       // Height of bitmap
													8,                          // Bits per component
													cvMat.step[0],              // Bytes per row
													colorSpace,                 // Colorspace
													kCGImageAlphaNoneSkipLast |
													kCGBitmapByteOrderDefault); // Bitmap info flags
	
	CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
	CGContextRelease(contextRef);
	
	return cvMat;
}
-(cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
	CGFloat cols = image.size.width;
	CGFloat rows = image.size.height;
	
	cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
	
	CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
													cols,                       // Width of bitmap
													rows,                       // Height of bitmap
													8,                          // Bits per component
													cvMat.step[0],              // Bytes per row
													colorSpace,                 // Colorspace
													kCGImageAlphaNoneSkipLast |
													kCGBitmapByteOrderDefault); // Bitmap info flags
	
	CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
	CGContextRelease(contextRef);
	
	return cvMat;
}
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
	NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
	CGColorSpaceRef colorSpace;
	
	if (cvMat.elemSize() == 1) {
		colorSpace = CGColorSpaceCreateDeviceGray();
	} else {
		colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	
	// Creating CGImage from cv::Mat
	CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
										cvMat.rows,                                 //height
										8,                                          //bits per component
										8 * cvMat.elemSize(),                       //bits per pixel
										cvMat.step[0],                            //bytesPerRow
										colorSpace,                                 //colorspace
										kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
										provider,                                   //CGDataProviderRef
										NULL,                                       //decode
										false,                                      //should interpolate
										kCGRenderingIntentDefault                   //intent
										);
	
	
	// Getting UIImage from CGImage
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	
	return finalImage;
}

-(UIImage *) makeGray: (UIImage *) image {
	// Convert UIImage to cv::Mat
	Mat inputImage = [self cvMatFromUIImage:image];
	// If input image has only one channel, then return image.
	if (inputImage.channels() == 1) return image;
	// Convert the default OpenCV's BGR format to GrayScale.
	Mat gray;
	cvtColor(inputImage, gray, CV_BGR2GRAY);
	// Convert the GrayScale OpenCV Mat to UIImage and return it.
	return [self UIImageFromCVMat:gray];
}


-(UIImage *) differenceBetween:(UIImage*)image1 and:(UIImage*)image2{
	Mat input1 = [self cvMatFromUIImage:image1];
	Mat input2 = [self cvMatFromUIImage:image2];
	Mat difference;
	absdiff(input1, input2, difference);
	return [self UIImageFromCVMat:difference];
}


-(UIImage*) imageToCVAndBack:(UIImage*)image{
	Mat input = [self cvMatFromUIImage:image];
	return [self UIImageFromCVMat:input];
}


@end

