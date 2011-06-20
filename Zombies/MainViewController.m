//
//  MainViewController.m
//  AccelerometerWithSettings
//
//  Created by Ankit Tyagi on 6/9/11.
//  Copyright 2011 Ankit Tyagi. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController

@synthesize x, y, speedRatio, scoreLabel, score, mainChar, 
    enemyList, timeLeftLabel, timeLeft, timeIsUp, youWin, delegate;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)viewCollides:(UIView *)view1 withView:(UIView *)view2 {
    if(CGRectIntersectsRect(view1.frame, view2.frame))
    {
        return YES;
    }
    return NO;
}

- (void)moveEnemy {
    @synchronized(self) {
        for (Enemy *iteratedEnemy in enemyList) {
            if (iteratedEnemy.myDirection == UP) [iteratedEnemy moveEnemyUp];
            else if (iteratedEnemy.myDirection == DOWN) [iteratedEnemy moveEnemyDown];
            else if (iteratedEnemy.myDirection == LEFT) [iteratedEnemy moveEnemyLeft];
            else [iteratedEnemy moveEnemyRight];
        }
    }
    if (!timeIsUp) {
        [NSTimer scheduledTimerWithTimeInterval:.04 
                                         target:self 
                                       selector:@selector(moveEnemy) 
                                       userInfo:nil 
                                        repeats:NO]; 
    }
    else {
        for (Enemy *iteratedEnemy in enemyList) {
            [iteratedEnemy removeFromSuperview];
        }
    }
}

- (void)runTimeRemaining {
    @synchronized(self) {
        timeLeft = timeLeft - 1;
        timeLeftLabel.text = [[NSString alloc] initWithFormat:@"%d", timeLeft];
    }
    if (timeLeft > 0) {
        [NSTimer scheduledTimerWithTimeInterval:1 
                                         target:self 
                                       selector:@selector(runTimeRemaining) 
                                       userInfo:nil 
                                        repeats:NO];
    }
    else {
        timeIsUp = YES;
    }
}

- (void)backgroundMoveEnemy {
    [self performSelectorOnMainThread:@selector(moveEnemy) 
                           withObject:nil 
                        waitUntilDone:NO]; 
}

- (void)backgroundDoTimeRemaining {
    [self performSelectorOnMainThread:@selector(runTimeRemaining) 
                           withObject:nil 
                        waitUntilDone:NO];
}

- (CGPoint)moveToThisLocation:(CGPoint)location {
    if (mainChar.center.x < 0) 
        location.x = 319;
    else if (mainChar.center.x > 320)
        location.x = 1;
    else if (mainChar.center.y < 0)
        location.y = 479;
    else if (mainChar.center.y > 480)
        location.y = 1;
    else {
        location.x = location.x + speedRatio * x;
        location.y = location.y - speedRatio * y;
    }
    
    return location;
}


- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    if (!timeIsUp) {
        //Sets accelerometer data
        x = acceleration.x;
        y = acceleration.y;
        
        //Sets speed from FlipsideViewController
        NSUserDefaults *speedDefaults = [NSUserDefaults standardUserDefaults];
        if ([speedDefaults floatForKey:@"intSpeed"] != 0.0f) 
            speedRatio = [speedDefaults floatForKey:@"intSpeed"];
        else 
            speedRatio = 10.0f;
        
        //Start animation
        [UIView beginAnimations:nil context:NULL];
        
        //Moves main character and sets it to the new location
        mainChar.center = [self moveToThisLocation:mainChar.center];
        
        [UIView commitAnimations];
        
        @synchronized(self) {
            //Collision check
            for (Enemy *iteratedEnemy in enemyList) {
                if ([self viewCollides:mainChar withView:iteratedEnemy]) {
                    score = score + 1;
                    [iteratedEnemy removeFromSuperview];
                    
                    CGPoint currentPos = iteratedEnemy.center;
                    
                    if (iteratedEnemy.myDirection == UP) {
                        iteratedEnemy.myDirection = LEFT;
                        currentPos = CGPointMake(300, (arc4random() % 300 + 20));
                    }
                    else if (iteratedEnemy.myDirection == LEFT) {
                        iteratedEnemy.myDirection = DOWN;
                        currentPos = CGPointMake((arc4random() % 300) + 20, 10);
                    }
                    else if (iteratedEnemy.myDirection == DOWN) {
                        iteratedEnemy.myDirection = RIGHT;
                        currentPos = CGPointMake(10, (arc4random() % 300 + 20));
                    }
                    else { 
                        iteratedEnemy.myDirection = UP;
                        currentPos = CGPointMake((arc4random() % 300) + 20, 460);
                    }
                    
                    iteratedEnemy.center = currentPos;
                    [self.view addSubview:iteratedEnemy];
                }
            }
        }
        
        scoreLabel.text = [[NSString alloc] initWithFormat:@"Score: %d", score];
        
    }
    else {
        [mainChar removeFromSuperview];
        youWin.hidden = NO;
        UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
        accel.delegate = nil;
        //Sleep for 10 seconds
        [NSThread sleepForTimeInterval:10];
        //Give up view
        [self.delegate mainViewDidFinish:self];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
    accel.delegate = self;
    accel.updateInterval = 1.0f/30.0f;
    
    enemyList = [[NSMutableArray alloc] init];
    for (int i = 0; i < 7; i++)
    {
        Enemy *newEnemy = [[Enemy alloc] initWithImage:[UIImage imageNamed:@"person.png"]];
        newEnemy.center = CGPointMake((arc4random() % 300) + 20, 419);
        newEnemy.myDirection = UP;
        newEnemy.directionChanged = NO;
        [enemyList addObject:newEnemy];
        [self.view addSubview:newEnemy];
    }
    
    [NSThread detachNewThreadSelector:@selector(backgroundMoveEnemy) 
                             toTarget:self 
                           withObject:nil];
    
    [NSThread detachNewThreadSelector:@selector(backgroundDoTimeRemaining) 
                             toTarget:self 
                           withObject:nil];
    
    score = 0;
    timeLeft = 30;
    timeIsUp = NO;
    
    standardPosition = mainChar.center;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    mainChar.center = standardPosition;
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}



@end