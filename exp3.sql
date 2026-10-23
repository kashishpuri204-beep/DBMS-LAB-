-- Experiment 3: Employee-Department-Project schema and basic SQL queries
-- MySQL 8. Run this file first. Experiments 4-6 use this database and schema.

CREATE DATABASE IF NOT EXISTS dbms_lab;
USE dbms_lab;

CREATE TABLE Department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(30) NOT NULL,
    location VARCHAR(30)
);

INSERT INTO Department VALUES
(1,'HR','Kanpur'),
(2,'IT','Lucknow'),
(3,'Finance','Delhi'),
(4,'Marketing','Mumbai'),
(5,'Operations','Pune');

CREATE TABLE Employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(40) NOT NULL,
    salary INT,
    hire_date DATE,
    dept_id INT,
    CONSTRAINT fk_employee_department FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

INSERT INTO Employee VALUES
(101,'Aarav Sharma',45000,'2019-03-15',1),
(102,'Priya Verma',52000,'2018-07-01',1),
(103,'Rohit Gupta',38000,'2021-01-10',1),
(104,'Sneha Singh',41000,'2020-09-25',1),
(105,'Kabir Mehta',48000,'2017-11-05',1),
(106,'Ananya Iyer',85000,'2016-02-14',2),
(107,'Vikram Rao',92000,'2015-06-30',2),
(108,'Neha Kapoor',78000,'2019-08-19',2),
(109,'Arjun Nair',67000,'2020-12-01',2),
(110,'Ishita Joshi',72000,'2018-04-22',2),
(111,'Manish Yadav',60000,'2022-05-11',2),
(112,'Pooja Mishra',65000,'2017-01-17',3),
(113,'Rahul Tiwari',71000,'2016-10-09',3),
(114,'Divya Pandey',58000,'2019-06-06',3),
(115,'Sanjay Dubey',62000,'2018-02-28',3),
(116,'Meera Agarwal',55000,'2021-07-13',3),
(117,'Karan Malhotra',49000,'2020-03-03',4),
(118,'Simran Kaur',53000,'2019-11-21',4),
(119,'Aditya Chauhan',46000,'2022-01-05',4),
(120,'Tanvi Desai',57000,'2018-09-12',4),
(121,'Nikhil Bansal',44000,'2021-04-18',4),
(122,'Riya Saxena',51000,'2017-08-08',4),
(123,'Harsh Vardhan',39000,'2022-02-20',5),
(124,'Kavya Reddy',43000,'2020-06-15',5),
(125,'Yash Pathak',47000,'2019-01-29',5),
(126,'Shreya Bose',50000,'2018-12-12',5),
(127,'Deepak Chopra',36000,'2023-03-01',5),
(128,'Anjali Menon',42000,'2021-09-09',5),
(129,'Mohit Khanna',56000,'2017-05-25',5),
(130,'Swati Jain',40000,'2022-10-10',5);

CREATE TABLE Project (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(40) NOT NULL,
    dept_id INT,
    budget INT,
    CONSTRAINT fk_project_department FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

INSERT INTO Project VALUES
(1,'Payroll System',1,300000),
(2,'Recruitment Portal',1,250000),
(3,'ERP Migration',2,900000),
(4,'Mobile App',2,700000),
(5,'Budget Automation',3,400000),
(6,'Ad Campaign 2025',4,500000),
(7,'Market Survey',4,200000),
(8,'Supply Chain Tracker',5,600000);

CREATE TABLE Works_On (
    emp_id INT,
    proj_id INT,
    hours INT,
    PRIMARY KEY (emp_id, proj_id),
    CONSTRAINT fk_work_employee FOREIGN KEY (emp_id) REFERENCES Employee(emp_id),
    CONSTRAINT fk_work_project FOREIGN KEY (proj_id) REFERENCES Project(proj_id)
);

INSERT INTO Works_On VALUES
(101,1,120),(102,1,150),(102,2,80),(103,2,100),(104,2,90),(105,1,60),
(106,3,200),(107,3,220),(107,4,100),(108,4,180),(109,3,140),(110,4,160),
(111,3,90),(112,5,130),(113,5,170),(114,5,110),(115,5,95),(116,5,80),
(117,6,140),(118,6,160),(119,7,70),(120,6,125),(121,7,85),(122,7,100),
(123,8,90),(124,8,110),(125,8,130),(126,8,150),(127,8,60),(129,8,175);

-- Selection
SELECT * FROM Employee WHERE salary > 60000;
