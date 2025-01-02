USE AirbnbBristol
GO

CREATE SCHEMA Staging;
GO

--TABLE CREATION
-- Create Staging tables
CREATE TABLE Staging.Listings (
    id BIGINT,
    listing_url NVARCHAR(MAX),
    scrape_id BIGINT,
    last_scraped DATE,
    source NVARCHAR(50),
    name NVARCHAR(MAX),
    description NVARCHAR(MAX),
    neighborhood_overview NVARCHAR(MAX),
    picture_url NVARCHAR(MAX),
    host_id BIGINT,
    host_url NVARCHAR(MAX),
    host_name NVARCHAR(255),
    host_since DATE,
    host_location NVARCHAR(255),
    host_about NVARCHAR(MAX),
    host_response_time NVARCHAR(50),
    host_response_rate NVARCHAR(50),
    host_acceptance_rate NVARCHAR(50),
    host_is_superhost NVARCHAR(10),
    host_thumbnail_url NVARCHAR(MAX),
    host_picture_url NVARCHAR(MAX),
    host_neighbourhood NVARCHAR(255),
    host_listings_count INT,
    host_total_listings_count INT,
    host_verifications NVARCHAR(MAX),
    host_has_profile_pic NVARCHAR(10),
    host_identity_verified NVARCHAR(10),
    neighbourhood NVARCHAR(255),
    neighbourhood_cleansed NVARCHAR(255),
    neighbourhood_group_cleansed NVARCHAR(255),
    latitude DECIMAL(18,15),
    longitude DECIMAL(18,15),
    property_type NVARCHAR(50),
    room_type NVARCHAR(50),
    accommodates INT,
    bathrooms DECIMAL(5,1),
    bathrooms_text NVARCHAR(50),
    bedrooms DECIMAL,
    beds DECIMAL,
    amenities NVARCHAR(MAX),
    price DECIMAL,
    minimum_nights INT,
    maximum_nights INT,
    minimum_minimum_nights DECIMAL,
    maximum_minimum_nights DECIMAL,
    minimum_maximum_nights DECIMAL,
    maximum_maximum_nights DECIMAL,
    minimum_nights_avg_ntm DECIMAL(10,2),
    maximum_nights_avg_ntm DECIMAL(10,2),
    calendar_updated NVARCHAR(50),
    has_availability NVARCHAR(10),
    availability_30 INT,
    availability_60 INT,
    availability_90 INT,
    availability_365 INT,
    calendar_last_scraped DATE,
    number_of_reviews INT,
    number_of_reviews_ltm INT,
    number_of_reviews_l30d INT,
    first_review DATE,
    last_review DATE,
    review_scores_rating DECIMAL(5,2),
    review_scores_accuracy DECIMAL(5,2),
    review_scores_cleanliness DECIMAL(5,2),
    review_scores_checkin DECIMAL(5,2),
    review_scores_communication DECIMAL(5,2),
    review_scores_location DECIMAL(5,2),
    review_scores_value DECIMAL(5,2),
    license NVARCHAR(255),
    instant_bookable NVARCHAR(10),
    calculated_host_listings_count INT,
    calculated_host_listings_count_entire_homes INT,
    calculated_host_listings_count_private_rooms INT,
    calculated_host_listings_count_shared_rooms INT,
    reviews_per_month DECIMAL(5,2),
    quarter DATE
);

--dropping columns we dont need
ALTER TABLE Staging.Listings
DROP COLUMN description,
    neighborhood_overview,
    picture_url,
    host_url,
    host_about,
    host_thumbnail_url,
    host_picture_url,
    host_location,
    host_neighbourhood,
    host_verifications,
    neighbourhood,
    neighbourhood_group_cleansed,
    calendar_updated,
    minimum_minimum_nights,
    maximum_minimum_nights,
    minimum_maximum_nights,
    maximum_maximum_nights,
    minimum_nights_avg_ntm,
    maximum_nights_avg_ntm,
	bathrooms,
	bedrooms,
	license;

-- Check the format and content of columns to clean 
SELECT DISTINCT host_response_time
FROM Staging.Listings
WHERE host_response_time IS NOT NULL;

SELECT DISTINCT property_type
FROM Staging.Listings
ORDER BY property_type;

SELECT DISTINCT room_type
FROM Staging.Listings
ORDER BY room_type;

SELECT DISTINCT instant_bookable 
FROM Staging.Listings;

SELECT DISTINCT has_availability
FROM Staging.Listings;

SELECT DISTINCT bathrooms_text
FROM Staging.Listings
ORDER BY bathrooms_text;

-- Add columns for cleaned data
ALTER TABLE Staging.Listings ADD
    bathrooms_cleaned DECIMAL(4,1),
    is_shared_bathroom BIT,
    host_response_rate_cleaned DECIMAL(5,2),
    host_acceptance_rate_cleaned DECIMAL(5,2),
    is_test_listing BIT,
    host_is_superhost_bit BIT,
    instant_bookable_bit BIT,
    has_availability_bit BIT,
    amenities_cleaned NVARCHAR(MAX);

-- Update with cleaned values
UPDATE Staging.Listings
SET 
    -- Clean bathrooms
    bathrooms_cleaned = 
    CASE 
        WHEN bathrooms_text IS NULL THEN NULL
        WHEN bathrooms_text = '0 baths' THEN 0
        WHEN bathrooms_text = '0 shared baths' THEN 0
        WHEN bathrooms_text LIKE 'Half%' OR bathrooms_text LIKE '%half%' THEN 0.5
        WHEN bathrooms_text LIKE '%shared%' OR bathrooms_text LIKE '%private%' 
            THEN CAST(SUBSTRING(bathrooms_text, 1, PATINDEX('%[^0-9.]%', bathrooms_text + ' ') - 1) AS DECIMAL(4,1))
        ELSE CAST(SUBSTRING(bathrooms_text, 1, PATINDEX('%[^0-9.]%', bathrooms_text + ' ') - 1) AS DECIMAL(4,1))
    END,
    
    is_shared_bathroom = 
    CASE 
        WHEN bathrooms_text LIKE '%shared%' THEN 1
        WHEN bathrooms_text LIKE '%private%' THEN 0
        ELSE 0
   
    END;

    -- Clean percentage fields
    host_response_rate_cleaned = NULLIF(CAST(REPLACE(host_response_rate, '%', '') AS DECIMAL(5,2)), 0),
    host_acceptance_rate_cleaned = NULLIF(CAST(REPLACE(host_acceptance_rate, '%', '') AS DECIMAL(5,2)), 0),

    -- Convert text boolean fields to bit
    host_is_superhost_bit = CASE WHEN host_is_superhost = 't' THEN 1 ELSE 0 END,
    instant_bookable_bit = CASE WHEN instant_bookable = 't' THEN 1 ELSE 0 END,
    has_availability_bit = CASE WHEN has_availability = 't' THEN 1 ELSE 0 END,

    -- Flag test listings
    is_test_listing = CASE 
        WHEN name LIKE '%test%' 
        OR name LIKE '%Template%'
        OR price > 5000
        THEN 1 
        ELSE 0 
    END;

    amenities_cleaned = REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(amenities, '[', ''),
                                        ']', ''
                                    ),
                                    '"', ''
                                ),
                                '\u2013', '-'
                            ),
                            '\u2019', ''''),
                        '\\', ''
                    );

-- Verify the cleaning
SELECT 
    COUNT(*) as total_listings,
    COUNT(CASE WHEN is_test_listing = 1 THEN 1 END) as test_listings,
    COUNT(CASE WHEN bathrooms_cleaned IS NULL THEN 1 END) as null_bathrooms,
    AVG(bathrooms_cleaned) as avg_clean_bathrooms
FROM Staging.Listings;


--POPULATE PRODUCTION TABLE 
--create production table 
CREATE TABLE dbo.Listings (
    -- Essential identifiers/keys
    id BIGINT PRIMARY KEY,
    host_id BIGINT NOT NULL,
    
    -- Essential business/location data
    price DECIMAL(10,2) NOT NULL,
    neighbourhood_cleansed NVARCHAR(255) NOT NULL,
    quarter DATE NOT NULL,

    -- Everything else nullable
    name NVARCHAR(MAX),
    host_name NVARCHAR(255),
    host_since DATE,
    host_response_time NVARCHAR(50),
    host_response_rate DECIMAL(5,2),
    host_acceptance_rate DECIMAL(5,2),
    host_is_superhost BIT,
    host_listings_count INT,
    host_total_listings_count INT,
    latitude DECIMAL(18,15),
    longitude DECIMAL(18,15),
    property_type NVARCHAR(50),
    room_type NVARCHAR(50),
    accommodates INT,
    bathrooms DECIMAL(4,1),
    is_shared_bathroom BIT,
    beds DECIMAL(4,1),
    amenities NVARCHAR(MAX),
    minimum_nights INT,
    maximum_nights INT,
    has_availability BIT,
    availability_30 INT,
    availability_60 INT,
    availability_90 INT,
    availability_365 INT,
    number_of_reviews INT,
    number_of_reviews_ltm INT,
    number_of_reviews_l30d INT,
    first_review DATE,
    last_review DATE,
    review_scores_rating DECIMAL(5,2),
    review_scores_accuracy DECIMAL(5,2),
    review_scores_cleanliness DECIMAL(5,2),
    review_scores_checkin DECIMAL(5,2),
    review_scores_communication DECIMAL(5,2),
    review_scores_location DECIMAL(5,2),
    review_scores_value DECIMAL(5,2),
    instant_bookable BIT,
    created_date DATETIME DEFAULT GETDATE(),
    modified_date DATETIME DEFAULT GETDATE()
);

--insert data from staging table
INSERT INTO dbo.Listings (
   -- Essential NOT NULL columns
   id, host_id, price, neighbourhood_cleansed, quarter,
   
   -- All other columns
   name, host_name, host_since, host_response_time, 
   host_response_rate, host_acceptance_rate, host_is_superhost,
   host_listings_count, host_total_listings_count,
   latitude, longitude, property_type, room_type,
   accommodates, bathrooms, is_shared_bathroom, beds,
   amenities, minimum_nights, maximum_nights,
   has_availability, availability_30, availability_60,
   availability_90, availability_365, number_of_reviews,
   number_of_reviews_ltm, number_of_reviews_l30d,
   first_review, last_review, review_scores_rating,
   review_scores_accuracy, review_scores_cleanliness,
   review_scores_checkin, review_scores_communication,
   review_scores_location, review_scores_value,
   instant_bookable
)
SELECT 
   -- Essential NOT NULL columns
   id, host_id, price, neighbourhood_cleansed, quarter,
   
   -- All other columns
   name, host_name, host_since, host_response_time,
   host_response_rate_cleaned, host_acceptance_rate_cleaned, host_is_superhost_bit,
   host_listings_count, host_total_listings_count,
   latitude, longitude, property_type, room_type,
   accommodates, bathrooms_cleaned, is_shared_bathroom, beds,
   amenities_cleaned, minimum_nights, maximum_nights,
   has_availability_bit, availability_30, availability_60,
   availability_90, availability_365, number_of_reviews,
   number_of_reviews_ltm, number_of_reviews_l30d,
   first_review, last_review, review_scores_rating,
   review_scores_accuracy, review_scores_cleanliness,
   review_scores_checkin, review_scores_communication,
   review_scores_location, review_scores_value,
   instant_bookable_bit
FROM Staging.Listings
WHERE 
   id IS NOT NULL 
   AND host_id IS NOT NULL 
   AND price IS NOT NULL 
   AND neighbourhood_cleansed IS NOT NULL
   AND quarter IS NOT NULL
   AND is_test_listing = 0;  -- Exclude test listings

-- Verify the data transfer
SELECT COUNT(*) FROM dbo.Listings;

--CREATE AMENITY TABLES 
CREATE TABLE dbo.AmenityTypes (
   amenity_id INT IDENTITY(1,1) PRIMARY KEY,
   amenity_name NVARCHAR(500) UNIQUE
);

CREATE TABLE dbo.ListingAmenities (
    listing_id BIGINT,
    amenity_id INT,
    PRIMARY KEY (listing_id, amenity_id),
    FOREIGN KEY (listing_id) REFERENCES dbo.Listings(id),
    FOREIGN KEY (amenity_id) REFERENCES dbo.AmenityTypes(amenity_id)
);

-- Populate tables
INSERT INTO dbo.AmenityTypes (amenity_name)
SELECT DISTINCT TRIM(value) as clean_amenity
FROM dbo.Listings
CROSS APPLY STRING_SPLIT(amenities, ',')
WHERE TRIM(value) != ''
ORDER BY clean_amenity;

INSERT INTO dbo.ListingAmenities (listing_id, amenity_id)
SELECT DISTINCT 
    l.id,
    at.amenity_id
FROM dbo.Listings l
CROSS APPLY STRING_SPLIT(amenities, ',') a
JOIN dbo.AmenityTypes at ON TRIM(a.value) = at.amenity_name;

--verify the data
SELECT TOP 10 * FROM dbo.AmenityTypes;
SELECT COUNT(*) as total_amenity_types FROM dbo.AmenityTypes;
SELECT COUNT(*) as total_listing_amenities FROM dbo.ListingAmenities;





--CREATE STORE PROCEDURES FOR ANALYTICAL TASKS
--flexible neighborhood analysis
CREATE PROCEDURE dbo.sp_NeighborhoodMetrics
    @neighborhood NVARCHAR(255) = NULL,
    @min_price DECIMAL(10,2) = NULL,
    @max_price DECIMAL(10,2) = NULL
AS
BEGIN
    SELECT 
        neighbourhood_cleansed,
        COUNT(*) as total_listings,
        AVG(price) as avg_price,
        AVG(review_scores_rating) as avg_rating
    FROM dbo.Listings
    WHERE (@neighborhood IS NULL OR neighbourhood_cleansed = @neighborhood)
    AND (@min_price IS NULL OR price >= @min_price)
    AND (@max_price IS NULL OR price <= @max_price)
    GROUP BY neighbourhood_cleansed;
END;
--verify procedure
EXEC dbo.sp_NeighborhoodMetrics 
	@neighborhood = 'Clifton';
	@min_price = 50,
    @max_price = 200;

--seasonal analysis
CREATE PROCEDURE dbo.sp_SeasonalAnalysisByNeighborhood
    @neighborhood NVARCHAR(255)
AS
BEGIN
    SELECT 
        quarter,
        AVG(price) as avg_price,
        AVG(availability_30) as avg_availability,
        COUNT(*) as listing_count
    FROM dbo.Listings
    WHERE neighbourhood_cleansed = @neighborhood
    GROUP BY quarter
    ORDER BY quarter;
END;
--verify procedure
exec [dbo].[sp_SeasonalAnalysisByNeighborhood] 
	@neighborhood = 'Redland'

-- Property value calculator
CREATE PROCEDURE dbo.sp_PropertyValueEstimator
    @neighborhood NVARCHAR(255),
    @room_type NVARCHAR(50),
    @number_of_amenities INT
AS
BEGIN
    WITH AmenityCount AS (
        SELECT 
            listing_id,
            COUNT(*) as amenity_count
        FROM dbo.ListingAmenities
        GROUP BY listing_id
    )
    SELECT 
        AVG(l.price) as estimated_price,
        AVG(l.review_scores_rating) as avg_rating,
        COUNT(*) as similar_properties
    FROM dbo.Listings l
    JOIN AmenityCount ac ON l.id = ac.listing_id
    WHERE l.neighbourhood_cleansed = @neighborhood
    AND l.room_type = @room_type
    AND ac.amenity_count >= @number_of_amenities;
END;

--verify procedure 
exec dbo.sp_PropertyValueEstimator
	@neighborhood = 'Lockleaze',
	@room_type = 'Entire home/apt',
	@number_of_amenities = 20;


--ANALYTICAL VIEWS 
--Revenue optimization
CREATE VIEW dbo.vw_RevenueOptimization AS
SELECT 
    neighbourhood_cleansed,
    quarter,
    AVG(price) as avg_price,
    1 - (AVG(CAST(availability_30 AS FLOAT))/30) as occupancy_rate,
    AVG(price) * (1 - (AVG(CAST(availability_30 AS FLOAT))/30)) * 30 as estimated_monthly_revenue
FROM dbo.Listings

--Price Analysis by Neighborhood 
CREATE OR ALTER VIEW dbo.vw_NeighborhoodPriceAnalysis AS
SELECT 
    neighbourhood_cleansed,
    COUNT(*) as total_listings,
    AVG(price) as avg_price,
    MIN(price) as min_price,
    MAX(price) as max_price,
    VAR(price) as price_variance,
    STDEV(price) as price_std_dev,
    STDEV(price) / NULLIF(AVG(price), 0) as coefficient_of_variation,  -- Added CV
    AVG(review_scores_rating) as avg_rating,
    COUNT(DISTINCT host_id) as unique_hosts
FROM dbo.Listings
GROUP BY neighbourhood_cleansed;

--Host Analysis
CREATE VIEW dbo.vw_HostInsights AS
SELECT 
    host_id,
    host_name,
    COUNT(*) as total_listings,
    AVG(price) as avg_listing_price,
    (
        SELECT STRING_AGG(x.pt, ',')
        FROM (SELECT DISTINCT property_type as pt 
              FROM dbo.Listings l2 
              WHERE l2.host_id = l.host_id) x
    ) as property_types,
    (
        SELECT STRING_AGG(x.n, ',')
        FROM (SELECT DISTINCT neighbourhood_cleansed as n 
              FROM dbo.Listings l2 
              WHERE l2.host_id = l.host_id) x
    ) as neighbourhoods,
    AVG(review_scores_rating) as avg_rating,
    SUM(number_of_reviews) as total_reviews,
    MAX(host_since) as host_since,
    COUNT(CASE WHEN review_scores_rating >= 4.5 THEN 1 END) as high_rated_listings
FROM dbo.Listings l
GROUP BY host_id, host_name;

-- Amenity Impact Analysis
CREATE VIEW dbo.vw_AmenityImpact AS
SELECT 
   at.amenity_name,
   COUNT(DISTINCT la.listing_id) as listings_count,
   AVG(l.price) as avg_price,
   AVG(l.review_scores_rating) as avg_rating,
   AVG(l.review_scores_value) as avg_value_rating,
   MIN(l.price) as min_price,
   MAX(l.price) as max_price,
   COUNT(DISTINCT l.neighbourhood_cleansed) as neighbourhoods_present
FROM dbo.AmenityTypes at
JOIN dbo.ListingAmenities la ON at.amenity_id = la.amenity_id
JOIN dbo.Listings l ON la.listing_id = l.id
GROUP BY at.amenity_name
HAVING COUNT(DISTINCT la.listing_id) > 5;

-- Seasonal Trends
CREATE VIEW dbo.vw_SeasonalTrends AS
SELECT 
   quarter,
   COUNT(*) as active_listings,
   AVG(availability_30) as avg_30day_availability,
   AVG(availability_60) as avg_60day_availability,
   AVG(availability_90) as avg_90day_availability,
   AVG(price) as avg_price,
   AVG(review_scores_rating) as avg_rating,
   COUNT(DISTINCT host_id) as active_hosts,
   AVG(number_of_reviews_l30d) as avg_recent_bookings
FROM dbo.Listings
GROUP BY quarter;