CREATE DATABASE IF NOT EXISTS productlaunchms;
USE productlaunchms;
CREATE TABLE PERSON (
    Person_ID INT PRIMARY KEY,
    First_Name VARCHAR(50),
    Last_Name VARCHAR(50),
    Email VARCHAR(100) UNIQUE,
    Present_As VARCHAR(20) DEFAULT 'GUEST',
    Phone_No VARCHAR(20),
    Dietary_Restriction VARCHAR(50)
);

CREATE TABLE PRODUCT (
    Product_ID INT PRIMARY KEY,
    Skin_Type VARCHAR(30),
    Category VARCHAR(100),
    Price DECIMAL(10,2) DEFAULT 0.00,
    Shelf_Life INT,
    CONSTRAINT Chk_Product_SkinType CHECK (Skin_Type IN ('Oily', 'Dry', 'Normal', 'Combination', 'All'))
);

CREATE TABLE EVENT (
    Event_ID INT PRIMARY KEY,
    Event_Date DATE NOT NULL,
    Building_Name VARCHAR(50),
    Street VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Pin_Code VARCHAR(10),
    Venue_Capacity INT DEFAULT 100
);

INSERT INTO PERSON VALUES
(1, 'Joyce', 'S', 'joyce.s@vit.ac.in', 'EMPLOYEE', '9876543210', 'None'),
(2, 'Rithika', 'Sherlin', 'rithika.s@vit.ac.in', 'EMPLOYEE', '9876543211', 'Vegetarian'),
(3, 'Arjun', 'Menon', 'arjun.m@gmail.com', 'GUEST', '9876543212', 'Vegan');

INSERT INTO PRODUCT (Product_ID, Skin_Type, Category, Price) VALUES
(301, 'Oily', 'Neem & Salicylic Gel Wash', 299.00),
(302, 'Dry', 'Hydrating Hyaluronic Cleanser', 349.00),
(303, 'All', 'Gentle Cica Foaming Wash', 399.00),
(304, 'Combination', 'Vitamin C Brightening Wash', 279.00),
(305, 'Normal', 'Tea Tree Charcoal Cleanser', 325.00);

INSERT INTO EVENT VALUES
(201, '2026-08-10', 'Grand Ballroom', 'MG Road', 'Chennai', 'Tamil Nadu', '600001', 500),
(202, '2026-08-11', 'Skincare Expo Hall', 'MG Road', 'Chennai', 'Tamil Nadu', '600001', 300);