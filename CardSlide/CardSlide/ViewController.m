//
//  ViewController.m
//  CardSlide
//
//  Created by Rahul Pant on 03/09/15.
//  Copyright (c) 2015 Rahul Pant. All rights reserved.
//

#import "ViewController.h"
#import "CardView.h"

//--------------------------------------------------------------------------------------------------------------------------------

typedef enum
{
    POSITION_TOP = 100,
    POSITION_FRONT,
    POSITION_BACK
} CardPosition;

typedef enum
{
    NO_VIEW_SLIDING,
    TOP_VIEW_SLIDE_DOWN,
    TOP_VIEW_SLIDE_UP,
    FRONT_VIEW_SLIDE_DOWN,
    FRONT_VIEW_SLIDE_UP
} SwipeViewSlideDirection;

typedef enum
{
    NO_SWIPE,
    SWIPE_UP,
    SWIPE_DOWN
} SwipeDirection;

//--------------------------------------------------------------------------------------------------------------------------------

#define VELOCITY_LIMIT                          170
#define ANIMATION_DURATION                      0.4
#define CONST_SHOW                              0
#define BORDER_PADDING                          50

//--------------------------------------------------------------------------------------------------------------------------------

@interface ViewController ()

@property (nonatomic) CardView                  *viewTop;
@property (nonatomic) CardView                  *viewFront;
@property (nonatomic) CardView                  *viewBack;
@property (nonatomic) NSMutableDictionary       *dictCardView;
@property (nonatomic) CGFloat                   startValue;
@property (nonatomic) NSArray                   *arrPageData;
@property (nonatomic) int                       pageIndex;
@property (nonatomic) SwipeViewSlideDirection   currentSwipeDirection;
@property (nonatomic) SwipeDirection            initialSwipeDirection;

@end

//--------------------------------------------------------------------------------------------------------------------------------

@implementation ViewController

- (void)loadView
{
    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor whiteColor];
    self.view = contentView;
    
    _dictCardView = [NSMutableDictionary dictionaryWithCapacity:3];
    _viewTop = [self addCardViewForPosition:POSITION_TOP color:[UIColor cyanColor]];
    _viewBack = [self addCardViewForPosition:POSITION_BACK color:[UIColor yellowColor]];
    _viewFront = [self addCardViewForPosition:POSITION_FRONT color:[UIColor greenColor]];
    
    _currentSwipeDirection = NO_VIEW_SLIDING;
    _initialSwipeDirection = NO_SWIPE;
}

- (CardView *)addCardViewForPosition:(CardPosition)position color:(UIColor *)color
{
    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"CardView"
                                                      owner:self
                                                    options:nil];
    
    CardView *cardView = [nibViews firstObject];
    [cardView setTranslatesAutoresizingMaskIntoConstraints:NO];
    cardView.backgroundColor = color;
    [cardView setTag:position];
    [self.view addSubview:cardView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:cardView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1
                                                           constant:-BORDER_PADDING]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:cardView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1
                                                           constant:-BORDER_PADDING]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:cardView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    NSLayoutConstraint *verticalConstraint = [NSLayoutConstraint constraintWithItem:cardView
                                                                          attribute:NSLayoutAttributeCenterY
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeCenterY
                                                                         multiplier:1.0
                                                                           constant:CONST_SHOW];
    [self.view addConstraint:verticalConstraint];
    [_dictCardView setObject:verticalConstraint forKey:[NSNumber numberWithInt:position]];
    return cardView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)]];
    
    _arrPageData = [[[[NSDateFormatter alloc] init] monthSymbols] copy];
    _pageIndex = 0;
    
    [self setDataInView:_viewFront forIndex:_pageIndex];
    [self setDataInView:_viewBack forIndex:_pageIndex+1];
}

//--------------------------------------------------------------------------------------------------------------------------------

#pragma mark CardView Animation

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint loc = [recognizer locationInView:self.view];
    CGPoint velocity = [recognizer velocityInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        _startValue = loc.y;
        _initialSwipeDirection = NO_SWIPE;
        return;
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGFloat diff = _startValue - loc.y;
        _startValue = loc.y;
        
        if (_initialSwipeDirection == NO_SWIPE)
            _initialSwipeDirection = diff < 0 ? SWIPE_DOWN : SWIPE_UP;
        
        if (_initialSwipeDirection == SWIPE_DOWN && _pageIndex > 0)
        {
            _currentSwipeDirection = diff < 0 ? TOP_VIEW_SLIDE_DOWN : TOP_VIEW_SLIDE_UP;
            [self constraintForView:[_viewTop tag]].constant -= diff;
        }
        else if (_initialSwipeDirection == SWIPE_UP && _pageIndex < _arrPageData.count-1)
        {
            _currentSwipeDirection = diff < 0 ? FRONT_VIEW_SLIDE_DOWN : FRONT_VIEW_SLIDE_UP;
            CGFloat constraint = [self constraintForView:[_viewFront tag]].constant;
            constraint -= diff;
            
            if (constraint < 0) [self constraintForView:[_viewFront tag]].constant -= diff;
        }
        return;
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        if (velocity.y > VELOCITY_LIMIT && _pageIndex > 0)
        {
            if (_currentSwipeDirection == FRONT_VIEW_SLIDE_DOWN)
                [self moveViewsForReset:YES];
            else
                [self animateViewsForSlide:NO];
        }
        else if (velocity.y <= VELOCITY_LIMIT && velocity.y >= -VELOCITY_LIMIT)
        {
            [self moveViewsForReset:YES];
        }
        else if (velocity.y <-VELOCITY_LIMIT && _pageIndex < _arrPageData.count-1)
        {
            if (_currentSwipeDirection == TOP_VIEW_SLIDE_UP)
                [self moveViewsForReset:YES];
            else
                [self animateViewsForSlide:YES];
        }
    }
}

- (void)animateViewsForSlide:(BOOL)slideUp
{
    if (slideUp)
    {
        [self.view sendSubviewToBack:_viewTop];
        [_viewTop setHidden:YES];
        [self.view bringSubviewToFront:_viewFront];
        [self constraintForView:[_viewBack tag]].constant = CONST_SHOW;
        [self constraintForView:[_viewFront tag]].constant = -(_viewFront.frame.size.height + BORDER_PADDING);
        [self constraintForView:[_viewTop tag]].constant = CONST_SHOW;
    }
    else
    {
        [self.view bringSubviewToFront:_viewTop];
        [_viewBack setHidden:YES];
        [self.view sendSubviewToBack:_viewBack];
        [self constraintForView:[_viewBack tag]].constant = -(_viewBack.frame.size.height + BORDER_PADDING);
        [self constraintForView:[_viewFront tag]].constant = CONST_SHOW;
        [self constraintForView:[_viewTop tag]].constant = CONST_SHOW;
    }
    
    [UIView animateWithDuration:ANIMATION_DURATION
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         
                         CardView *viewTop = _viewTop;
                         CardView *viewFront = _viewFront;
                         CardView *viewBack = _viewBack;
                         
                         if (slideUp)
                         {
                             [_viewTop setHidden:NO];
                             _pageIndex++;
                             _viewTop = viewFront;
                             _viewFront = viewBack;
                             _viewBack = viewTop;
                         }
                         else
                         {
                             [_viewBack setHidden:NO];
                             _pageIndex--;
                             _viewTop = viewBack;
                             _viewFront = viewTop;
                             _viewBack = viewFront;
                         }
                         
                         [self.view bringSubviewToFront:_viewTop];
                         [self.view sendSubviewToBack:_viewBack];
                         [self setDataForCurrentIndex:slideUp];
                     }];
}

- (void)moveViewsForReset:(BOOL)animate
{
    [self constraintForView:[_viewBack tag]].constant = CONST_SHOW;
    [self constraintForView:[_viewFront tag]].constant = CONST_SHOW;
    [self constraintForView:[_viewTop tag]].constant = -(_viewFront.frame.size.height + BORDER_PADDING);
    
    [UIView animateWithDuration:animate ? ANIMATION_DURATION : 0
                     animations:^{
                         [self.view layoutIfNeeded];
                     }];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [_viewTop setHidden:YES];
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self moveViewsForReset:NO];
         [_viewTop setHidden:NO];
     }];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (NSLayoutConstraint *)constraintForView:(CardPosition)position
{
    return [_dictCardView objectForKey:[NSNumber numberWithInt:position]];
}

//--------------------------------------------------------------------------------------------------------------------------------

#pragma mark Data Handling

- (void)setDataForCurrentIndex:(BOOL)slideUp
{
    if ( _pageIndex <= 0 || _pageIndex >= _arrPageData.count-1) return;
    
    if (slideUp)
        [self setDataInView:_viewBack forIndex:_pageIndex+1];
    else
        [self setDataInView:_viewTop forIndex:_pageIndex-1];
}

- (void)setDataInView:(CardView *)cardView forIndex:(int)index
{
    UILabel *lab = [[cardView subviews] firstObject];
    [lab setText:_arrPageData[index]];
    NSLog(@"Data set for index %d", index);
}


@end
