//
//  TCKeyboardAvoidingScrollView.h
//  TwinCodersLibrary
//
//  Created by Guillermo Gutiérrez on 05/09/12.
//  Copyright (c) 2012 TwinCoders S.L. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCKeyboardAvoidingScrollView : UIScrollView
- (BOOL)focusNextTextField;
- (void)scrollToActiveTextField;
@end