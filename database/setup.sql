-- =====================================================================
-- Product Launch Management System (PLMS) - Database Setup Script
-- Course: Database Management Systems (DBMS Portfolio Project)
-- Author: Joyce Blessinah S (25BCE2979)
-- Database: MySQL
-- =====================================================================

DROP DATABASE IF EXISTS productlaunchms;
CREATE DATABASE productlaunchms;
USE productlaunchms;

-- ---------------------------------------------------------------------
-- 1. Table: PERSON
-- Stores all individuals related to the launch: employees, guests,
-- VIPs, media influencers, and dermatology experts.
-- ---------------------------------------------------------------------
CREATE TABLE PERSON (
    Person_ID INT PRIMARY KEY,
    First_Name VARCHAR(50) NOT NULL,
    Last_Name VARCHAR(50),
    Email VARCHAR(100) NOT NULL UNIQUE,
    Present_As VARCHAR(20) DEFAULT 'GUEST',
    Phone_No VARCHAR(20),
    Dietary_Restriction VARCHAR(50) DEFAULT 'None',
    CONSTRAINT Chk_Person_Role CHECK (
        Present_As IN ('EMPLOYEE', 'GUEST', 'VIP', 'MEDIA', 'INFLUENCER', 'SPEAKER')
    )
);

-- ---------------------------------------------------------------------
-- 2. Table: PRODUCT
-- Stores the skincare products launched during events.
-- Fully backward-compatible with Server.java API endpoints.
-- ---------------------------------------------------------------------
CREATE TABLE PRODUCT (
    Product_ID INT PRIMARY KEY,
    Skin_Type VARCHAR(30) NOT NULL,
    Category VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) DEFAULT 0.00,
    Shelf_Life INT DEFAULT 24, -- Shelf life in months
    Stock_Quantity INT DEFAULT 500,
    CONSTRAINT Chk_Product_SkinType CHECK (
        Skin_Type IN ('Oily', 'Dry', 'Normal', 'Combination', 'All')
    ),
    CONSTRAINT Chk_Product_Price CHECK (Price >= 0.00)
);

-- ---------------------------------------------------------------------
-- 3. Table: EVENT
-- Stores launch venues, dates, and locations.
-- ---------------------------------------------------------------------
CREATE TABLE EVENT (
    Event_ID INT PRIMARY KEY,
    Event_Name VARCHAR(100) NOT NULL,
    Event_Date DATE NOT NULL,
    Start_Time TIME DEFAULT '10:00:00',
    Building_Name VARCHAR(50),
    Street VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Pin_Code VARCHAR(10),
    Venue_Capacity INT DEFAULT 100,
    CONSTRAINT Chk_Venue_Capacity CHECK (Venue_Capacity > 0)
);

-- ---------------------------------------------------------------------
-- 4. Table: PRODUCT_LAUNCH (Junction: PRODUCT <-> EVENT)
-- Connects products to the specific launch event where they are debuted.
-- ---------------------------------------------------------------------
CREATE TABLE PRODUCT_LAUNCH (
    Launch_ID INT PRIMARY KEY AUTO_INCREMENT,
    Event_ID INT NOT NULL,
    Product_ID INT NOT NULL,
    Launch_Time TIME,
    Launch_Price DECIMAL(10,2),
    Exclusive_Offer VARCHAR(100),
    Units_Allocated INT DEFAULT 100,
    FOREIGN KEY (Event_ID) REFERENCES EVENT(Event_ID) ON DELETE CASCADE,
    FOREIGN KEY (Product_ID) REFERENCES PRODUCT(Product_ID) ON DELETE CASCADE,
    CONSTRAINT Uq_Event_Product UNIQUE (Event_ID, Product_ID)
);

-- ---------------------------------------------------------------------
-- 5. Table: EVENT_REGISTRATION (Junction: PERSON <-> EVENT)
-- Tracks attendance, badge pass tier, and attendance status.
-- ---------------------------------------------------------------------
CREATE TABLE EVENT_REGISTRATION (
    Registration_ID INT PRIMARY KEY AUTO_INCREMENT,
    Person_ID INT NOT NULL,
    Event_ID INT NOT NULL,
    Registration_Date DATE NOT NULL,
    Pass_Type VARCHAR(20) DEFAULT 'STANDARD',
    Attendance_Status VARCHAR(20) DEFAULT 'REGISTERED',
    Seat_Number VARCHAR(10),
    FOREIGN KEY (Person_ID) REFERENCES PERSON(Person_ID) ON DELETE CASCADE,
    FOREIGN KEY (Event_ID) REFERENCES EVENT(Event_ID) ON DELETE CASCADE,
    CONSTRAINT Uq_Person_Event UNIQUE (Person_ID, Event_ID),
    CONSTRAINT Chk_Pass_Type CHECK (Pass_Type IN ('STANDARD', 'VIP', 'PRESS', 'STAFF')),
    CONSTRAINT Chk_Attendance_Status CHECK (
        Attendance_Status IN ('REGISTERED', 'ATTENDED', 'CANCELLED', 'NO_SHOW')
    )
);

-- ---------------------------------------------------------------------
-- 6. Table: FEEDBACK_REVIEW (Junction: PERSON <-> PRODUCT)
-- Captures product reviews, ratings, and tester testimonials.
-- ---------------------------------------------------------------------
CREATE TABLE FEEDBACK_REVIEW (
    Feedback_ID INT PRIMARY KEY AUTO_INCREMENT,
    Person_ID INT NOT NULL,
    Product_ID INT NOT NULL,
    Rating INT NOT NULL,
    Review_Title VARCHAR(100),
    Comments TEXT,
    Review_Date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Person_ID) REFERENCES PERSON(Person_ID) ON DELETE CASCADE,
    FOREIGN KEY (Product_ID) REFERENCES PRODUCT(Product_ID) ON DELETE CASCADE,
    CONSTRAINT Chk_Feedback_Rating CHECK (Rating BETWEEN 1 AND 5)
);

-- ---------------------------------------------------------------------
-- 7. Table: STAFF_ASSIGNMENT (Junction: PERSON (EMPLOYEE) <-> EVENT)
-- Assigns team members and staff to roles for each launch.
-- ---------------------------------------------------------------------
CREATE TABLE STAFF_ASSIGNMENT (
    Assignment_ID INT PRIMARY KEY AUTO_INCREMENT,
    Person_ID INT NOT NULL,
    Event_ID INT NOT NULL,
    Role_Title VARCHAR(50) NOT NULL,
    Shift_Start TIME,
    Shift_End TIME,
    FOREIGN KEY (Person_ID) REFERENCES PERSON(Person_ID) ON DELETE CASCADE,
    FOREIGN KEY (Event_ID) REFERENCES EVENT(Event_ID) ON DELETE CASCADE
);

-- =====================================================================
-- SAMPLE DATA INSERTIONS
-- =====================================================================

-- People: Employees, Guests, Media, VIPs
INSERT INTO PERSON (Person_ID, First_Name, Last_Name, Email, Present_As, Phone_No, Dietary_Restriction) VALUES
(1, 'Joyce', 'S', 'joyce.s@vit.ac.in', 'EMPLOYEE', '9876543210', 'None'),
(2, 'Rithika', 'Sherlin', 'rithika.s@vit.ac.in', 'EMPLOYEE', '9876543211', 'Vegetarian'),
(3, 'Arjun', 'Menon', 'arjun.m@gmail.com', 'GUEST', '9876543212', 'Vegan'),
(4, 'Dr. Anita', 'Rao', 'anita.derm@skinhealth.org', 'SPEAKER', '9876543213', 'Gluten-Free'),
(5, 'Vikram', 'Seth', 'vikram.seth@beautyvibe.in', 'INFLUENCER', '9876543214', 'None'),
(6, 'Meera', 'Nair', 'meera.nair@chennaichronicle.com', 'MEDIA', '9876543215', 'Vegetarian'),
(7, 'Siddharth', 'Varma', 'siddharth.v@gmail.com', 'VIP', '9876543216', 'None'),
(8, 'Pooja', 'Kulkarni', 'pooja.k@vit.ac.in', 'EMPLOYEE', '9876543217', 'Jain');

-- Products: Skincare catalog
INSERT INTO PRODUCT (Product_ID, Skin_Type, Category, Price, Shelf_Life, Stock_Quantity) VALUES
(301, 'Oily', 'Neem & Salicylic Gel Wash', 299.00, 24, 750),
(302, 'Dry', 'Hydrating Hyaluronic Cleanser', 349.00, 24, 600),
(303, 'All', 'Gentle Cica Foaming Wash', 399.00, 18, 500),
(304, 'Combination', 'Vitamin C Brightening Wash', 279.00, 12, 800),
(305, 'Normal', 'Tea Tree Charcoal Cleanser', 325.00, 24, 450),
(306, 'Oily', 'Niacinamide 10% Blemish Serum', 499.00, 24, 400),
(307, 'Dry', 'Ceramide Barrier Relief Cream', 449.00, 18, 350),
(308, 'All', 'Broad Spectrum SPF 50 Gel Sunscreen', 399.00, 24, 900);

-- Events: Launch galas and expos
INSERT INTO EVENT (Event_ID, Event_Name, Event_Date, Start_Time, Building_Name, Street, City, State, Pin_Code, Venue_Capacity) VALUES
(201, 'Grand Skincare Premiere Gala', '2026-08-10', '18:00:00', 'Grand Ballroom', 'MG Road', 'Chennai', 'Tamil Nadu', '600001', 500),
(202, 'Glow & Radiance Skincare Expo', '2026-08-11', '10:00:00', 'Skincare Expo Hall', 'Anna Salai', 'Chennai', 'Tamil Nadu', '600002', 300),
(203, 'South India Beauty Innovation Summit', '2026-09-05', '09:30:00', 'Convention Center', 'Residency Road', 'Bengaluru', 'Karnataka', '560025', 800);

-- Product Launches: Products scheduled for events
INSERT INTO PRODUCT_LAUNCH (Event_ID, Product_ID, Launch_Time, Launch_Price, Exclusive_Offer, Units_Allocated) VALUES
(201, 301, '18:30:00', 249.00, 'Launch Night 15% Discount + Free Travel Pouch', 200),
(201, 302, '19:00:00', 299.00, 'Buy 1 Get Hydrating Mist Free', 200),
(201, 303, '19:30:00', 349.00, 'Exclusive VIP Goodie Bag Inclusion', 150),
(202, 304, '11:00:00', 239.00, 'Expo Special Bundle Deal', 250),
(202, 305, '12:00:00', 280.00, 'Live Sampling & 20% Off Coupon', 200),
(203, 306, '10:30:00', 429.00, 'Keynote Launch Special', 300),
(203, 307, '11:15:00', 389.00, 'Dermatologist Recommended Starter Pack', 250),
(203, 308, '12:00:00', 349.00, 'Early Bird Free Sun Hat Combo', 400);

-- Event Registrations: Attendee passes
INSERT INTO EVENT_REGISTRATION (Person_ID, Event_ID, Registration_Date, Pass_Type, Attendance_Status, Seat_Number) VALUES
(1, 201, '2026-07-15', 'STAFF', 'ATTENDED', 'STAFF-01'),
(2, 201, '2026-07-15', 'STAFF', 'ATTENDED', 'STAFF-02'),
(3, 201, '2026-07-20', 'STANDARD', 'ATTENDED', 'A-14'),
(4, 201, '2026-07-18', 'VIP', 'ATTENDED', 'VIP-01'),
(5, 201, '2026-07-22', 'PRESS', 'ATTENDED', 'PRESS-03'),
(6, 201, '2026-07-25', 'PRESS', 'ATTENDED', 'PRESS-04'),
(7, 201, '2026-07-28', 'VIP', 'ATTENDED', 'VIP-02'),
(3, 202, '2026-07-29', 'STANDARD', 'REGISTERED', 'B-22'),
(5, 202, '2026-07-30', 'VIP', 'REGISTERED', 'VIP-05'),
(8, 202, '2026-07-16', 'STAFF', 'REGISTERED', 'STAFF-05');

-- Staff Assignments: Operational duties
INSERT INTO STAFF_ASSIGNMENT (Person_ID, Event_ID, Role_Title, Shift_Start, Shift_End) VALUES
(1, 201, 'Event Director & Product Presenter', '16:00:00', '22:00:00'),
(2, 201, 'VIP Guest & Media Coordinator', '16:30:00', '22:00:00'),
(8, 201, 'Registration Desk Supervisor', '17:00:00', '21:00:00'),
(1, 202, 'Keynote Speaker & Brand Lead', '09:00:00', '15:00:00'),
(8, 202, 'Product Demonstration Manager', '09:30:00', '16:00:00');

-- Feedback & Reviews: Product impressions
INSERT INTO FEEDBACK_REVIEW (Person_ID, Product_ID, Rating, Review_Title, Comments) VALUES
(4, 303, 5, 'Exceptional for Sensitive Skin', 'Gentle Cica Foaming Wash has proven calming and non-stripping in clinical trials.'),
(5, 301, 5, 'Clearer skin in days!', 'Neem & Salicylic wash worked wonders on t-zone oiliness during the launch trial.'),
(3, 302, 4, 'Very Hydrating', 'Skin felt supple after washing. Great mild scent and silky texture.'),
(7, 306, 5, 'Dermatology-Grade Quality', 'Niacinamide serum absorbed instantly without any tacky residue. Highly impressed.');

-- =====================================================================
-- ANALYTICAL VIEWS FOR REPORTING & QUERIES
-- =====================================================================

-- View 1: Complete Product Launch Schedule (Event + Product + Launch Pricing)
CREATE OR REPLACE VIEW vw_ProductLaunchSchedule AS
SELECT 
    e.Event_ID,
    e.Event_Name,
    e.Event_Date,
    e.City,
    p.Product_ID,
    p.Category AS Product_Name,
    p.Skin_Type,
    p.Price AS Regular_Price,
    pl.Launch_Time,
    pl.Launch_Price,
    pl.Exclusive_Offer
FROM EVENT e
JOIN PRODUCT_LAUNCH pl ON e.Event_ID = pl.Event_ID
JOIN PRODUCT p ON pl.Product_ID = p.Product_ID;

-- View 2: Event Attendance & Guest Roster
CREATE OR REPLACE VIEW vw_EventAttendeeRoster AS
SELECT 
    e.Event_ID,
    e.Event_Name,
    e.Event_Date,
    p.Person_ID,
    CONCAT(p.First_Name, ' ', COALESCE(p.Last_Name, '')) AS Full_Name,
    p.Email,
    p.Present_As,
    er.Pass_Type,
    er.Attendance_Status,
    er.Seat_Number,
    p.Dietary_Restriction
FROM EVENT e
JOIN EVENT_REGISTRATION er ON e.Event_ID = er.Event_ID
JOIN PERSON p ON er.Person_ID = p.Person_ID;

-- View 3: Skincare Feedback and Average Rating Dashboard
CREATE OR REPLACE VIEW vw_ProductRatingSummary AS
SELECT 
    p.Product_ID,
    p.Category AS Product_Name,
    p.Skin_Type,
    p.Price,
    COUNT(f.Feedback_ID) AS Total_Reviews,
    ROUND(AVG(f.Rating), 2) AS Average_Rating
FROM PRODUCT p
LEFT JOIN FEEDBACK_REVIEW f ON p.Product_ID = f.Product_ID
GROUP BY p.Product_ID, p.Category, p.Skin_Type, p.Price;