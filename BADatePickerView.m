//
//  BADatePickerView.m
//  BADatePickerView
//
//  Created by ALLARD Benjamin on 16/08/16.
//

#import "BADatePickerView.h"


@implementation BADatePickerView
{
    //default date picker datasets to reset
    NSArray * dayPossibilities;
    NSArray * monthPossibilities;
    
    //current date picker datasets
    NSMutableArray * months;
    NSMutableArray * years;
    NSMutableArray * days;
    
    //index of columns of the picker view
    NSInteger indexOfDays;
    NSInteger indexOfMonths;
    NSInteger indexOfYears;
    
    //date tools
    NSDateComponents *startDateComponents;
    NSDateComponents *currentDateComponents;
    NSDateFormatter *dateFormatter ;
    BOOL thisYearSelected;
    
    NSDate * currentDateSelected;
    
    //determine which format is used by the region, and set the correct order for the pickerview columns
    NSMutableArray * dateStringFormat;
    NSMutableDictionary * monthNumber;
    
    
}
@synthesize periodicity = _periodicity;
@synthesize startDate = _startDate;

static NSInteger const NUMBER_OF_COLUMNS = 3;
- (instancetype)initWithCoder:(NSCoder *)coder
{
    
    
    self = [super initWithCoder:coder];
    if (self) {
        
        self.delegate = self;
        self.dataSource= self;
        
        // init all NSArray, NSMutableArray, ...
        dateFormatter = [[NSDateFormatter alloc] init];
        
        days = [[NSMutableArray alloc]init];
        months = [[NSMutableArray alloc]init];
        years = [[NSMutableArray alloc]init];
        
        dateStringFormat = [[NSMutableArray alloc]init];
        monthNumber = [[NSMutableDictionary alloc] init];
        
        //setAttributes of PickerView
        [self setShowsSelectionIndicator:YES];
        
        //initialize by default (without periodicity, startedDate as today, number of years 50)
        [self initializeWithNumberOfYears:50 startedDate:nil];
        
    }
    return self;
}

/**
 *  Determine which date format is use on the phone
 */
- (void)initDateFormat {
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterShortStyle];
    [df setTimeStyle:NSDateFormatterShortStyle];
    
    //spare all date elements
    NSArray * array = [[df dateFormat] componentsSeparatedByString:@"/"];
    
    dateStringFormat = [[NSMutableArray alloc]init];
    
    //adding date format element
    for (int i=0; i<3&&i<[array count]; i++) {
        NSString * string =[[NSString alloc]initWithString:[array[i] substringToIndex:1]];
        [dateStringFormat addObject:string];
    }
    
    
    for (int i=0;i<[[df monthSymbols]count];i++)
    {
        [monthNumber setValue:[NSNumber numberWithInt:i+1] forKey:[df monthSymbols][i] ];
    }
}

/**
 *  Clean days array to conserve only the day of the start date, when i have a periodicity and a startdate after today
 */
- (void)removeOthersDays {
    NSInteger startDateDay = [startDateComponents day];
    long i=0;
    while (i<[days count]) {
        if([[days objectAtIndex:i] integerValue]!=startDateDay)
        {
            [days removeObjectAtIndex:i];
        }
        else
        {
            i++;
        }
    }
}

/**
 *  Delete days before the started date
 */
- (void)removeDaysBeforeStartedDate {
    
    NSInteger startDateDay = [startDateComponents day];
    long i=0;
    while (i<[days count] && [days[i] integerValue]<startDateDay)
    {
        [days removeObjectAtIndex:i];
    }
}

/**
 * Initialiase the day possibilities in a array
 */
- (void)initializeDaysPossibilities
{
    //inits days
    dayPossibilities = [NSArray arrayWithObjects:[[NSNumber alloc] initWithInt:1], [[NSNumber alloc] initWithInt:5],[[NSNumber alloc] initWithInt:10],[[NSNumber alloc] initWithInt:15],[[NSNumber alloc] initWithInt:20], [[NSNumber alloc] initWithInt:25], [[NSNumber alloc] initWithInt:30], nil];
    
    days = [NSMutableArray arrayWithArray:dayPossibilities];
    
    //prepare picker to show the first date
    [self removeDaysBeforeStartedDate];
}

/**
 * Initialiase the months possibilities in a array
 */
- (void)initializeMonthsPossibilities
{
    //init months
    months = [[NSMutableArray alloc] init];
    
    //adding all months from the dateformatter at the array
    for(int month = 0; month < 12; month++)
    {
        [months addObject:[[dateFormatter monthSymbols]objectAtIndex: month]];
    }
    
    //settings monthsPossibilities
    monthPossibilities = [months copy];
}

-(void)initializeMonthsPossibilitiesFrom:(NSDate *)startedDate untilFinishDate:(NSDate*)finishDate
{
    months = [[NSMutableArray alloc] init];
    NSDateComponents * startedDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:startedDate];
    
    NSDateComponents * finishDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:finishDate];
    
    for (int i  =[startedDateComps month]; i<[finishDateComps month]; i++)
    {
        if(i>12)
        {
            i=0;
        }
        [months addObject:[[dateFormatter monthSymbols]objectAtIndex: i]];
    }
    monthPossibilities = [months copy];
}

/**
 * Initialiase the years possibilities in a array
 */
- (void)initYearsPossibilitiesFrom:(NSDate *)startedDate untilFinishDate:(NSDate*)finishDate

{
    NSDateComponents * startedDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:startedDate];
    
    NSDateComponents * finishDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:finishDate];

    
    NSDateComponents *addComponents = [[NSDateComponents alloc] init];
    dateFormatter.dateFormat = @"yyyy";
    
    [years removeAllObjects];
    
    for (int nbYears = 0;nbYears+[startedDateComps year] <= [finishDateComps year];nbYears++)
    {
        addComponents.year = nbYears;
        [years addObject:[dateFormatter stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:addComponents toDate:startedDate options:0]]];
    }
}


/**
 * Initialiase the years possibilities in a array
 */
- (void)initYearsPossibilities
{
    //Adding years from started date to numberOfYearFromNow
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *addComponents = [[NSDateComponents alloc] init];
    dateFormatter.dateFormat = @"yyyy";
    
    [years removeAllObjects];
    
    for (int nbYears = 0;nbYears < [self numberOfYearFromNow];nbYears++)
    {
        addComponents.year = nbYears;
        [years addObject:[dateFormatter stringFromDate:[calendar dateByAddingComponents:addComponents toDate:self.startDate options:0]]];
    }
}

-(void)initializefromStartedDate:(NSDate *) startedDate toFinishDate:(NSDate *)finishDate
{
    //settings params
    if(!startedDate)
    {
        self.startDate = [NSDate date];
    }
    else{
        self.startDate = startedDate;
    }
    //initialize date format
    [self initDateFormat];
    [self setIndex];
    
    //init days
    [self initializeDaysPossibilities];
    
    //init months
    [self initializeMonthsPossibilitiesFrom:self.startDate untilFinishDate:finishDate];

    //init years
    [self initYearsPossibilitiesFrom:self.startDate untilFinishDate:finishDate];
}


-(void)initializeWithNumberOfYears:(NSInteger)numberOfYears startedDate:(NSDate *) startedDate
{
    //settings params
    if(!startedDate)
    {
        self.startDate = [NSDate date];
    }
    else{
        self.startDate = startedDate;
    }
    self.numberOfYearFromNow = numberOfYears;
    
    //initialize date format
    [self initDateFormat];
    [self setIndex];
    
    //init days
    [self initializeDaysPossibilities];
    
    //init months
    [self initializeMonthsPossibilities];
    [self removePreviousMonth:NO];
    
    //init years
    [self initYearsPossibilities];
}

-(void)initializeWithPeriodicity:(NSUInteger)periodicity numberOfYears:(NSInteger)numberOfYears startedDate:(NSDate *) startedDate
{
    //settings params
    if(!startedDate)
    {
        self.startDate = [NSDate date];
    }
    else{
        self.startDate = startedDate;
    }
    self.numberOfYearFromNow = numberOfYears;
    self.periodicity = periodicity;
    
    
    
    //initialize date format
    [self initDateFormat];
    [self setIndex];
    
    
    //init days
    [self initializeDaysPossibilities];
    [self removeOthersDays];
    
    
    //init months
    [self initializeMonthsPossibilities];
    [self removeUnrelevantMonthWithPeriodicity];
    //prepare pickerview of month : delete previous month
    [self removePreviousMonth:YES];
    
    
    //init years
    [self initYearsPossibilities];
    if([months count]==0)
    {
        [self selectNextYear];
        months = [NSMutableArray arrayWithArray:monthPossibilities];
    }
}


#pragma mark - UIPickerViewDataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return NUMBER_OF_COLUMNS;
}

// returns the number of rows in the component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger numberOfRows = [[self getArrayOfComponent:component] count];
    return numberOfRows;
}

#pragma mark - UIPickerViewDelegate

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString * label = @"";
    label = [NSString stringWithFormat:@"%@",[[self getArrayOfComponent:component] objectAtIndex:row]];
    return label;
}

//determine the width of the component for the pickerview
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    CGFloat componentWidth = 0;
    CGFloat pickerViewSizeWidth = pickerView.frame.size.width;
    
    if(component==indexOfDays)
    {
        //days = 1/4
        componentWidth = pickerViewSizeWidth/12*3;
    }
    else
    {
        if(component==indexOfMonths)
        {
            //months = 1/4-1/3 = 5/12
            componentWidth = pickerViewSizeWidth/12*5;
        }
        else
        {
            if(component==indexOfYears)
            {
                //year = 1/3
                componentWidth = pickerViewSizeWidth/12*4;
            }
        }
    }
    return componentWidth;
    
}

// Make action when a specific row is selected
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    
    /**
     *  When I have a periodicity :
     *      - The day is fix
     *      - The months are shown in function of the periodicity and it's possible to select only from the first periodicity (the months before and the current month are deleted of the choice)
     
     *  When I haven't a periodicity :
     *      - I could choose a day inside the range of days preset before
     *      - I remove choice after the 28
     */
    
    BOOL dayChanged = NO;
    BOOL monthChanged = NO;
    BOOL yearChanged = NO;
    BOOL nextMonth = NO;
    
    BOOL isThisMonthSelected =[months[[self selectedRowInComponent:indexOfMonths]] isEqualToString:[dateFormatter monthSymbols][[startDateComponents month]-1]];
    thisYearSelected = [years[[self selectedRowInComponent:indexOfYears]] integerValue]==[startDateComponents year];
    
    NSInteger currentDaySelected = [days[[self selectedRowInComponent:indexOfDays]] integerValue];
    NSInteger currentYear = [years[[self selectedRowInComponent:indexOfYears]] integerValue];
    NSString * currentMonthSelectedString = months[[self selectedRowInComponent:indexOfMonths]] ;
    NSInteger  currentMonth = [self getMonthNumberFromMonthString:currentMonthSelectedString];
    
    //manage day only if no periodicity
    
    
    if(thisYearSelected)
    {
        monthChanged = YES;
        if(self.periodicity==0)
        {
            [self removePreviousMonth:NO];
        }
        else
        {
            [self removePreviousMonth:YES];
        }
    }
    else
    {
        monthChanged = YES;
        months = [NSMutableArray arrayWithArray:monthPossibilities];
    }
    
    if(monthChanged)
    {
        [self reloadComponent:indexOfMonths];
        [self selectThisMonth:currentMonthSelectedString];
    }
    
    if(yearChanged)
    {
        [self selectThisYear:currentYear];
    }
    
    
    isThisMonthSelected =[months[[self selectedRowInComponent:indexOfMonths]] isEqualToString:[dateFormatter monthSymbols][[startDateComponents month]-1]];
    
    currentMonthSelectedString = months[[self selectedRowInComponent:indexOfMonths]] ;
    currentMonth = [self getMonthNumberFromMonthString:currentMonthSelectedString];
    
    
    if(self.periodicity==0)
    {
        dayChanged = YES;
        days = [NSMutableArray arrayWithArray:dayPossibilities];
        
        //if selected month is february
        if([currentMonthSelectedString isEqualToString:[self getFebruaryMonthString]] )
        {
            if( [startDateComponents day]<26)
            {
                //if we are before teh 26, we deleted previous day and last possibly due date
                //todo make it generic and remove days after 28 or 29, not only the last choice
                [days removeLastObject];
            }
            else
            {
                //we go on th next month
                monthChanged = YES;
                nextMonth = YES;
            }
        }
        
        
        
        //if this month and this year remove previous day
        if(isThisMonthSelected && thisYearSelected && !nextMonth)
        {
            dayChanged = YES;
            [self removeDaysBeforeStartedDate];
        }
        
    }
    else
    {
        dayChanged = YES;
    }
    
    //reload component changed
    if(dayChanged)
    {
        [self reloadComponent:indexOfDays];
        [self selectThisDay:currentDaySelected];
    }
    
    currentDaySelected = [days[[self selectedRowInComponent:indexOfDays]] integerValue];
    
    //create date from each row selected inside the differents components
    currentDateComponents = [[NSDateComponents alloc] init];
    [currentDateComponents setDay:currentDaySelected];
    [currentDateComponents setMonth:currentMonth];
    [currentDateComponents setYear:currentYear];
    currentDateSelected = [[NSCalendar currentCalendar] dateFromComponents:currentDateComponents];
    
    if ( [[self baDatePickerViewDelegate] respondsToSelector:@selector(pickerView:dateValueChanged:)] ) {
        [[self baDatePickerViewDelegate] pickerView:pickerView dateValueChanged:currentDateSelected];
    }
    
}



#pragma mark - utils for delegate
-(void)selectNextYear
{
    if([years count]!=0 && [years count]>[self selectedRowInComponent:indexOfYears])
    {
        //NSInteger nextYear = years[1];
        BOOL yearFound = NO;
        int i=0;
        NSInteger nextYear = [years[i+1] integerValue];
        
        while(!yearFound && i< [years count] && [years[i] integerValue] <= nextYear)
        {
            if([years[i] integerValue] == nextYear)
            {
                [self selectRow:i inComponent:indexOfYears animated:NO];
                yearFound = YES;
            }
            i++;
        }
        
    }
}

-(void)selectThisYear:(NSInteger)thisYear
{
    BOOL yearFound = NO;
    int i=0;
    while(i< [years count] && [years[i] integerValue] <= thisYear)
    {
        if([years[i] integerValue] == thisYear)
        {
            [self selectRow:i inComponent:indexOfYears animated:NO];
            yearFound = YES;
        }
        i++;
    }
    if(!yearFound)
    {
        [self selectRow:0 inComponent:indexOfYears animated:NO];
    }
}

-(void)selectThisMonth:(NSString *)thisMonth
{
    BOOL monthFound = NO;
    int i = 0;
    while (i<[months count] && !monthFound) {
        if([months[i]isEqualToString:thisMonth])
        {
            [self selectRow:i inComponent:indexOfMonths animated:NO];
            monthFound = YES;
        }
        i++;
    }
    if(!monthFound)
    {
        [self selectRow:0 inComponent:indexOfMonths animated:NO];
    }
}

-(void)selectThisDay:(NSInteger)thisDay
{
    BOOL dayFound = NO;
    int i=0;
    while(i< [days count] && [days[i] integerValue] <= thisDay)
    {
        if([days[i] integerValue] == thisDay)
        {
            [self selectRow:i inComponent:indexOfDays animated:NO];
            dayFound = YES;
        }
        i++;
    }
    if(!dayFound)
    {
        [self selectRow:0 inComponent:indexOfDays animated:NO];
    }
}


#pragma mark - Utils for locale change

-(NSArray *)getArrayOfComponent:(NSInteger)component
{
    NSArray * array = nil;
    if(component>=0 && component<[dateStringFormat count])
    {
        NSString * dateFormatElement = dateStringFormat[component];
        if ([dateFormatElement isEqualToString:@"d"]) {
            array = days;
        }
        else
        {
            if([dateFormatElement isEqualToString:@"M"])
            {
                array = months;
            }
            else
            {
                array = years;
            }
            
        }
        
    }
    return array;
    
}

-(void)setIndex
{
    
    for (NSInteger i=0; i<[dateStringFormat count];i++) {
        if ([dateStringFormat[i] isEqualToString:@"d"])
        {
            indexOfDays=i;
        }
        else
        {
            if ([dateStringFormat[i] isEqualToString:@"M"])
            {
                indexOfMonths = i;
            }
            else
            {
                indexOfYears = i;
            }
        }
    }
}

-(NSString *)getFebruaryMonthString
{
    return [dateFormatter monthSymbols][1];
}
-(NSInteger)getMonthNumberFromMonthString:(NSString *) monthString
{
    return [[monthNumber objectForKey:monthString] integerValue];
}


/**
 * remove month that are not corresponding with the periodicity
 */
-(void)removeUnrelevantMonthWithPeriodicity
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self.startDate];
    
    if(self.periodicity != 0)
    {
        NSInteger currentMonth = [components month];
        long i = currentMonth;
        //what to do when month = 12 ?
        NSInteger monthInFunctionOfPeriodicity = currentMonth+1;
        
        while(monthInFunctionOfPeriodicity!= currentMonth+12)
        {
            if(i>=[months count])
            {
                i=0;
            }

            if(((monthInFunctionOfPeriodicity - currentMonth) % self.periodicity)!=0)
            {
                [months removeObjectAtIndex:i];
            }
            else
            {
                i++;
            }
            
            monthInFunctionOfPeriodicity ++;
        }
    }
    
    monthPossibilities = [months copy];
    
}

-(void)removePreviousMonth:(BOOL)alsoCurrentMonth
{
    BOOL monthFound=NO;
    
    //determine current month and compare with
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self.startDate];
    NSInteger currentMonth = [components month];
    
    int i = 0;
    while (!monthFound && i<[months count]&&[self getMonthNumberFromMonthString:months[i]]<=currentMonth) {
        if([self getMonthNumberFromMonthString:months[i]]==currentMonth)
        {
            monthFound=YES;
            if(alsoCurrentMonth)
            {
                [months removeObjectAtIndex:i];
            }
        }
        else{
            [months removeObjectAtIndex:i];
        }
        
    }
    
    
}

#pragma mark - setters / getters

/**
 * Set periodicity in number of month
 */
-(void)setPeriodicity:(NSUInteger)periodicity
{
    if( periodicity !=0)
    {
        _periodicity = periodicity;
    }
}

-(NSUInteger)periodicity
{
    return _periodicity;
}

-(void)setStartDate:(NSDate *)startDate
{
    _startDate = startDate;
    startDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[self startDate]];
}

-(NSDate* )startDate
{
    return _startDate;
}


@end
