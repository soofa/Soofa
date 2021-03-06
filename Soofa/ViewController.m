//
//  ViewController.m
//  Soofa
//
//  Created by Robert Breznak on 8/6/15.
//  Copyright (c) 2015 Soofa. All rights reserved.
//

#import "ViewController.h"

#define MINIMUM_ZOOM_ARC 0.014 //approximately 1 miles (1 degree of arc ~= 69 miles)
#define ANNOTATION_REGION_PAD_FACTOR 1.15
#define MAX_DEGREES_ARC 360

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.showsUserLocation = YES;
    
    self.locationManager = [[CLLocationManager alloc] init];
    [[self locationManager] setDelegate:self];

    // we have to setup the location maanager with permission in later iOS versions
    if ([[self locationManager] respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [[self locationManager] requestWhenInUseAuthorization];
    }
    
    [[self locationManager] setDesiredAccuracy:kCLLocationAccuracyBest];
    [[self locationManager] startUpdatingLocation];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"https://s3.amazonaws.com/api.soofa.io/devices.geojson" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        NSArray *features = [responseObject objectForKey:@"features"];
        
        for(NSDictionary *feature in features) {
            MKPointAnnotation *benchAnnotation = [[MKPointAnnotation alloc]init];
            
            benchAnnotation.title = [[feature objectForKey:@"properties"] objectForKey:@"name"];
            benchAnnotation.subtitle = [[feature objectForKey:@"properties"] objectForKey:@"description"];
            
            NSArray *coordinates = [[feature objectForKey:@"geometry"] objectForKey:@"coordinates"];
            benchAnnotation.coordinate = CLLocationCoordinate2DMake([coordinates[0] doubleValue], [coordinates[1] doubleValue]);

            [self.mapView addAnnotation:benchAnnotation];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        // Try to dequeue an existing pin view first.
        MKAnnotationView *pinView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
        if (!pinView)
        {
            // If an existing pin view was not available, create one.
            pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotationView"];
            pinView.canShowCallout = YES;
            pinView.image = [UIImage imageNamed:@"bench-base-standalone-icon"];
            pinView.calloutOffset = CGPointMake(0, 0);
            
            // Add an image to the left callout.
            UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bench-base-standalone-icon"]];
            pinView.leftCalloutAccessoryView = iconView;
        } else {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    return nil;
}

@end
