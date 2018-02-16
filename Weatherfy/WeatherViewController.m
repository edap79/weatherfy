//
//  WeatherViewController.m
//  Weatherfy
//
//  Created by Eduardo Toledo on 12/13/17.
//  Copyright © 2017 SoSafe. All rights reserved.
//

#import "WeatherViewController.h"
#import <Weatherfy-Swift.h>

@import MapKit;

@interface WeatherViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *averageLabel;
@property (weak, nonatomic) IBOutlet UILabel *varianceLabel;

@property (strong, nonatomic) DataSource *dataSource;
@end

@implementation WeatherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataSource = [[DataSource alloc] init];
    
    UITapGestureRecognizer *fingerTap = [[UITapGestureRecognizer alloc]
                                         initWithTarget:self action:@selector(handleMapFingerTap:)];
    fingerTap.numberOfTapsRequired = 1;
    fingerTap.numberOfTouchesRequired = 1;
    [self.mapView addGestureRecognizer:fingerTap];
    
    [self updateLabels:-1.0 variance:-1.0];
}

- (void)dealloc
{
    self.dataSource = NULL;
}

- (IBAction)onActionButtonPressed:(UIButton *)sender
{
    [self search];
}

- (void)updateLabels:(CGFloat)average variance:(CGFloat)variance
{
    self.averageLabel.text = [NSString stringWithFormat:@"%.2f", average];
    self.varianceLabel.text = [NSString stringWithFormat:@"%.2f", variance];
}

- (void)search
{
    [self.view endEditing:YES];
    
    MKLocalSearchRequest *localSearchRequest = [[MKLocalSearchRequest alloc] init];
    localSearchRequest.naturalLanguageQuery = [self.textField.text lowercaseString];
    localSearchRequest.region = self.mapView.region;
    
    MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:localSearchRequest];
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response,
                                             NSError * _Nullable error)
    {
        if (response)
        {
            bool move = NO;
            
            for (MKMapItem *mapItem in response.mapItems)
            {
                NSArray *result = [self.dataSource getRainDataWithTown:mapItem.name];
                CGFloat average = [[result objectAtIndex:0] doubleValue];
                CGFloat variance = [[result objectAtIndex:1] doubleValue];
                
                if (average != -1.0)
                {
                    [self moveMapToCoordinates:mapItem.placemark.coordinate];
                    [self updateLabels:average variance:variance];
                    move = YES;
                    break;
                }
            }
            
            if (!move)
                [self updateLabels:-1.0 variance:-1.0];
        }
    }];
}

- (void)moveMapToCoordinates:(CLLocationCoordinate2D)coordinates
{
    MKCoordinateSpan span = MKCoordinateSpanMake(0, 360/pow(2, 10) * self.mapView.frame.size.width/256);
    [self.mapView setRegion:MKCoordinateRegionMake(coordinates, span) animated:YES];
}

- (void)handleMapFingerTap:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    [self.view endEditing:YES];
}

# pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self search];
    
    return YES;
}

@end
