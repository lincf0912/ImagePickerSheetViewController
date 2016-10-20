//
//  UIImage+Addition.m
//  MiracleMessenger
//
//  Created by Anson on 14-5-27.
//  Copyright (c) 2014年 gzmiracle. All rights reserved.
//

#import "UIImage+Addition.h"
#import <Accelerate/Accelerate.h>

@implementation UIImage (Addition)

+ (UIImageOrientation)imgOrientationFromAssetOrientation:(ALAssetOrientation)assetOrientation {
    
    UIImageOrientation imgOrientation = UIImageOrientationRight;
    switch (assetOrientation) {
        case ALAssetOrientationDown:
            imgOrientation = UIImageOrientationDown;
            break;
            
        case ALAssetOrientationLeft:
            imgOrientation = UIImageOrientationLeft;
            break;
            
        case ALAssetOrientationRight:
            imgOrientation = UIImageOrientationRight;
            break;
            
        case ALAssetOrientationUp:
            imgOrientation = UIImageOrientationUp;
            break;
            
        case ALAssetOrientationUpMirrored:
            imgOrientation = UIImageOrientationUpMirrored;
            break;
            
        case ALAssetOrientationDownMirrored:
            imgOrientation = UIImageOrientationDownMirrored;
            break;
            
        case ALAssetOrientationLeftMirrored:
            imgOrientation = UIImageOrientationLeftMirrored;
            break;
            
        case ALAssetOrientationRightMirrored:
            imgOrientation = UIImageOrientationRightMirrored;
            break;
            
        default:
            break;
    }

    return imgOrientation;
    
}

- (UIImage *)fixOrientation {
    
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    UIImage *editImg = self;//[UIImage imageWithData:UIImagePNGRepresentation(self)];
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (editImg.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, editImg.size.width, editImg.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, editImg.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, editImg.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            
        default:
            break;
    }
    
    switch (editImg.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, editImg.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, editImg.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, editImg.size.width, editImg.size.height,
                                             CGImageGetBitsPerComponent(editImg.CGImage), 0,
                                             CGImageGetColorSpace(editImg.CGImage),
                                             CGImageGetBitmapInfo(editImg.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (editImg.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0, editImg.size.height, editImg.size.width), editImg.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0, editImg.size.width, editImg.size.height), editImg.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
