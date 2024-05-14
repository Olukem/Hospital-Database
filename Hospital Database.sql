USE MASTER
GO


----- Create new database if it does not exist-----
IF NOT EXISTS (
SELECT [name]
FROM sys.databases
WHERE [name] = N'HospitalDB')
CREATE DATABASE HospitalDB;
GO


-----Use HospitalManagementSystem Database-----
USE HospitalDB;


------ script to drop all tables if they exist---------

IF OBJECT_ID('Patients', 'U') IS NOT NULL
    DROP TABLE Patients;

IF OBJECT_ID('PatientLogin', 'U') IS NOT NULL
    DROP TABLE PatientLogin;

IF OBJECT_ID('PatientStatus', 'U') IS NOT NULL
    DROP TABLE PatientStatus;

IF OBJECT_ID('Departments', 'U') IS NOT NULL
    DROP TABLE Departments;

IF OBJECT_ID('Doctors', 'U') IS NOT NULL
    DROP TABLE Doctors;

IF OBJECT_ID('DoctorAvailability', 'U') IS NOT NULL
    DROP TABLE DoctorAvailability;

IF OBJECT_ID('Appointments', 'U') IS NOT NULL
    DROP TABLE Appointments;

IF OBJECT_ID('ArchivedAppointments', 'U') IS NOT NULL
    DROP TABLE ArchivedAppointments;

IF OBJECT_ID('MedicalRecords', 'U') IS NOT NULL
    DROP TABLE MedicalRecords;

IF OBJECT_ID('Prescriptions', 'U') IS NOT NULL
    DROP TABLE Prescriptions;

IF OBJECT_ID('Feedback', 'U') IS NOT NULL
    DROP TABLE Feedback;


----------create table patients-----
CREATE TABLE Patients (
PatientID INT IDENTITY(1,1)  NOT NULL PRIMARY KEY ,
FullName NVARCHAR(100) NOT NULL,
Address NVARCHAR(100) NOT NULL,
DateOfBirth DATE NOT NULL CHECK (DateOfBirth <= GETDATE()),
Insurance NVARCHAR (50) NOT NULL,
Email NVARCHAR(100) UNIQUE NULL CHECK (Email LIKE '%@%.%' AND Email NOT LIKE '%@%@%'),
TelephoneNumber NVARCHAR(30) UNIQUE NULL
);



-----create patient login table-----
CREATE TABLE PatientLogin (
PatientLoginID INT IDENTITY(1,1) NOT NULL  PRIMARY KEY ,
PatientID INT NOT NULL,
Username NVARCHAR(50) NOT NULL ,
PasswordHash BINARY (100) NOT NULL,
Salt UNIQUEIDENTIFIER,
CONSTRAINT FK_PatientLogin_Patients FOREIGN KEY (PatientID) REFERENCES Patients (PatientID),
CONSTRAINT UK_PatientLogin_Username UNIQUE (Username)
);



-----create patient status table-----
CREATE TABLE PatientStatus (
StatusID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
PatientID INT NOT NULL,
RegDate DATE NOT NULL,
DateLeft DATE NULL, 
StatusDescription VARCHAR(100), --- Active, Inactive, Left
CONSTRAINT FK_PatientStatus_Patient FOREIGN KEY (PatientID) REFERENCES Patients (PatientID)
);



-----create department table-----
CREATE TABLE Departments (
DepartmentID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
DepartmentName NVARCHAR(100) NOT NULL,
Description NVARCHAR(MAX) NULL,
Location NVARCHAR(150) NULL
);



-----create Doctor's table-----
CREATE TABLE Doctors (
DoctorID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
DepartmentID INT,
FullName NVARCHAR(100) NOT NULL,
Email NVARCHAR(100) NULL CHECK(Email LIKE '%_@__%.__%'),
TelephoneNumber NVARCHAR(30) UNIQUE NULL,
Specialization NVARCHAR(100),
CONSTRAINT FK_Doctors_Departments FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);



---------create Doctor's Availability table-----
CREATE TABLE DoctorAvailability (
AvailabilityID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
DoctorID INT NOT NULL,
Days NVARCHAR(50) NOT NULL,
StartTime DATETIME NOT NULL,
EndTime DATETIME NOT NULL,
AvailabilityStatus NVARCHAR(50) NOT NULL, -- Available, Unavailable
CONSTRAINT fk_doctor FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID) ON DELETE CASCADE
);



-----create Appointment table-----
CREATE TABLE Appointments (
AppointmentID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
PatientID INT NOT NULL,
DoctorID INT NOT NULL,
DepartmentID INT NOT NULL,
PastAppointmentDate DATE NULL,
AppointmentDate DATE NOT NULL,
AppointmentTime TIME NOT NULL,
Status NVARCHAR(50), -- Scheduled, Completed, Cancelled
CONSTRAINT FK_Appointments_Patients FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
CONSTRAINT FK_Appointments_Doctor FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
CONSTRAINT FK_Appointments_Departments FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);



-----create ArchivedAppointment table-----
CREATE TABLE ArchivedAppointments (
AppointmentID INT  NOT NULL PRIMARY KEY,
PatientID INT NOT NULL,
DoctorID INT NOT NULL,
DepartmentID INT NOT NULL,
PastAppointmentDate DATE NULL,
AppointmentDate DATE NOT NULL,
AppointmentTime TIME NOT NULL,
Status NVARCHAR(50),
ArchivedDate DATETIME NOT NULL DEFAULT GETDATE(),
CONSTRAINT FK_ArchivedAppointments_Patients FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
CONSTRAINT FK_ArchivedAppointments_Doctor FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
CONSTRAINT FK_ArchivedAppointments_Departments FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);



-----create medical records table-----
CREATE TABLE MedicalRecords (
RecordID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
AppointmentID INT NOT NULL,
PatientID INT NOT NULL,
Diagnosis NVARCHAR(MAX) NULL, 
Allergies NVARCHAR(MAX) NULL, 
RecordDate DATE NOT NULL DEFAULT GETDATE(), 
CONSTRAINT FK_MedicalRecords_Patients FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
CONSTRAINT FK_MedicalRecords_Appointments FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID)
ON DELETE CASCADE,
);



-----create Prescription table-----
CREATE TABLE Prescriptions (
PrescriptionID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
AppointmentID INT NOT NULL,
PatientID INT NOT NULL,
PrescribedMedicine VARCHAR(100) NOT NULL,
Dosage NVARCHAR(100) NOT NULL, 
Frequency NVARCHAR(100) NOT NULL,
Duration NVARCHAR(100) NOT NULL, 
Notes NVARCHAR(MAX) NULL, 
PrescriptionDate DATE NOT NULL DEFAULT GETDATE(),
CONSTRAINT FK_Prescriptions_Patients FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
CONSTRAINT FK_Prescriptions_Appointments FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID)
ON DELETE CASCADE
);



-----create feedback table-----
CREATE TABLE Feedback (
FeedbackID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
AppointmentID INT NOT NULL, 
PatientID INT NOT NULL,
DoctorID INT NOT NULL, 
FeedbackText NVARCHAR(MAX) NOT NULL, 
Rating INT CHECK(Rating >= 1 AND Rating <= 5),
FeedbackDate DATE NOT NULL DEFAULT GETDATE(), 
CONSTRAINT FK_Feedback_Patients FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
CONSTRAINT FK_Feedback_Doctors FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID),
CONSTRAINT FK_Feedback_Appointments FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID)
ON DELETE CASCADE
);



----------------create procedure for new patient login---------------------
GO
CREATE OR ALTER PROCEDURE AddNewPatientLogin 
    @PatientID INT,
    @Username NVARCHAR(50), 
    @Password NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
	BEGIN TRANSACTION;
    DECLARE @Salt UNIQUEIDENTIFIER = NEWID(); 
    DECLARE @PasswordHash VARBINARY(64); 
    SET @PasswordHash = HASHBYTES('SHA2_512', @Password + CAST(@Salt AS NVARCHAR(36)));
    INSERT INTO PatientLogin (PatientID, Username, PasswordHash, Salt)
    VALUES (@PatientID, @Username, @PasswordHash, @Salt);    
	COMMIT TRANSACTION;
	END TRY
    BEGIN CATCH
	ROLLBACK TRANSACTION;
	THROW;
    END CATCH
END;



----------------------------------------Populating the Tables------------------------------------------

----------------------------------Patients Table--------------------------------------------------------
INSERT INTO Patients (FullName, Address, DateOfBirth, Insurance, Email, TelephoneNumber)
VALUES 
('Angel Smith', '123 Elm Street, Springfield', '1980-05-15', 'HealthPlus', 'angel.smith@email.com', '07033567097'),
('Geo Ted', '456 Maple Avenue, Anytown', '1990-07-23', 'MediCare', 'geo.ted@email.com', '07284775010'),
('Michael John', '789 Oak Street, Smalltown', '1975-02-17', 'CareFirst', 'michael.john@email.com', '07624687855'),
('Emily Spare', '321 Pine Street, Oldtown', '1980-11-08', 'UnitedHealth', 'emily.spare@email.com', '07064835983'),
('Shake Brown', '654 Cedar Blvd, Newtown', '1970-08-30', 'Signal Insurance', 'shake.brown@email.com', '07769877267'),
('chu chuns', '987 Ash Road, Cooltown', '1995-04-12', 'Forall Insurance', 'chu.chuns@email.com', '07153854233'),
('Noah Sweet', '246 Birch Lane, Warmville', '1988-12-22', 'Solid Wealth', 'noah.sweet@email.com', '07098754354'),
('Ava Loore', '135 Willow Way, Beachtown', '1992-03-09', 'Sunset Insurance', 'ava.loore@email.com', '07997723443'),
('Mikky Taylor', '864 Elmwood Street, Rivertown', '1985-09-04', 'BlueCross', 'mikky.taylor@email.com', '07543324687'),
('Snow White', '975 Pineknoll Terrace, Lakecity', '1978-06-18', 'Alliance', 'snow.white@email.com', '07134557654'),
('Mash Twin', '432 Sandwood Road, Hilltown', '1993-01-15', 'HealthNet', 'mash.twin@email.com', '07707432685'),
('Rossie Tuna', '591 Greenwood Drive, Snowtown', '1989-05-21', 'WellPoint', 'rossie.tuna@email.com', '07553689423'),
('Cloie White', '213 Sunnyvale Court, Raincity', '1974-10-28', 'HealthPartners', 'cloie.white@email.com', '07614697543'),
('Jill Hills', '627 Maplewood Ave, Sunville', '1981-03-30', 'CareMore', 'jill.hills@email.com', '07457655599'),
('Lege Miami', '783 Oakdale Street, Mooncity', '1961-07-25', 'Amerigroup', 'lege.miami@email.com', '07222257881')

------------------retrieving all data from the patients table----------------------------------------
select * from Patients



--------------------------------------------PatientLogin-------------------------------------------------------
GO
EXEC AddNewPatientLogin @PatientID = 1, @Username = 'angelim0', @Password = 'password111!';
EXEC AddNewPatientLogin @PatientID = 2, @Username = 'geotedo4hi', @Password = 'password222!';
EXEC AddNewPatientLogin @PatientID = 3, @Username = 'milikij2na', @Password = 'password333!';
EXEC AddNewPatientLogin @PatientID = 4, @Username = 'emily0nikab8', @Password = 'password444!';
EXEC AddNewPatientLogin @PatientID = 5, @Username = 'browNisw1ll', @Password = 'password555!';
EXEC AddNewPatientLogin @PatientID = 6, @Username = 'chuchuna8', @Password = 'password666!';
EXEC AddNewPatientLogin @PatientID = 7, @Username = 'noahark3', @Password = 'password777!';
EXEC AddNewPatientLogin @PatientID = 8, @Username = 'avaMors0', @Password = 'password888!';
EXEC AddNewPatientLogin @PatientID = 9, @Username = 'mikokoTaylor2', @Password = 'password999!';
EXEC AddNewPatientLogin @PatientID = 10, @Username = 'snowie0Whit', @Password = 'password123!';
EXEC AddNewPatientLogin @PatientID = 11, @Username = 'masTwin0', @Password = 'password345!';
EXEC AddNewPatientLogin @PatientID = 12, @Username = 'Rosietunna5', @Password = 'password456!';
EXEC AddNewPatientLogin @PatientID = 13, @Username = 'cl13White', @Password = 'password567!';
EXEC AddNewPatientLogin @PatientID = 14, @Username = 'j1kkHills', @Password = 'password678!';
EXEC AddNewPatientLogin @PatientID = 15, @Username = 'legeMimi4', @Password = 'password789!';

-----------------retrieving all data from the PatientLogin table----------------------------------------
select * from PatientLogin



---------------------------------------Patient Status---------------------------------------
INSERT INTO PatientStatus (PatientID, RegDate, DateLeft, StatusDescription)
VALUES
(1, '2023-01-10', NULL, 'Active'),
(2, '2023-01-15', '2023-03-01', 'Inactive'),
(3, '2023-02-01', NULL, 'Active'),
(4, '2023-02-20', '2023-03-15', 'Inactive'),
(5, '2023-03-05', NULL, 'Active'),
(6, '2023-03-12', NULL, 'Active'),
(7, '2023-03-18', '2023-03-25', 'Left'),
(8, '2023-04-01', NULL, 'Active'),
(9, '2023-04-10', NULL, 'Active'),
(10, '2023-04-15', '2023-04-22', 'Left'),
(11, '2023-05-01', NULL, 'Active'),
(12, '2023-05-15', NULL, 'Active'),
(13, '2023-06-01', NULL, 'Active'),
(14, '2023-06-15', '2023-07-01', 'Inactive'),
(15, '2023-07-01', NULL, 'Active')

-----------------retrieving all data from the PatientStatus table----------------------------------------
select * from PatientStatus



------------------------------------------Department table----------------------------------------
INSERT INTO Departments (DepartmentName, Description, Location)
VALUES
('Cardiology', 'This department provides medical care to patients with heart conditions.', 'Building A - Floor 2'),
('Pediatrics', 'Dedicated to the medical care of infants, children, and adolescents.', 'Building B - Floor 3'),
('Oncology', 'Focuses on the diagnosis and treatment of cancer.', 'Building C - Floor 4'),
('Neurology', 'Deals with disorders of the nervous system.', 'Building D - Floor 5'),
('Orthopedics', 'Focuses on the care of the musculoskeletal system.', 'Building A - Floor 6'),
('Emergency', 'Provides immediate care for acute illnesses and injuries.', 'Ground Floor - Building E'),
('Obstetrics and Gynecology', 'Diagnosis and treatment of diseases of the female reproductive organs.', 'Building B - Floor 7'),
('Dermatology', 'Specializes in conditions related to the skin.', 'Building C - Floor 8'),
('Psychiatry', 'Deals with the diagnosis, prevention, and treatment of mental disorders.', 'Building D - Floor 9'),
('Radiology', 'Uses imaging techniques to diagnose and treat diseases.', 'Building A - Floor 1'),
('Anesthesiology', 'Provides anesthesia services to patients undergoing surgery and other procedures.', 'Building B - Ground Floor'),
('Ophthalmology', 'Focuses on the treatment of disorders and diseases of the eye.', 'Building C - Floor 2'),
('Urology', 'Deals with diseases of the urinary tract and the male reproductive system.', 'Building D - Floor 3'),
('Endocrinology', 'Deals with the diagnosis and treatment of diseases related to hormones.', 'Building A - Floor 4'),
('Gastroenterology', 'Focuses on diseases affecting the gastrointestinal tract.', 'Building B - Floor 5');

-----------------retrieving all data from the Departments table----------------------------------------
select * from Departments;



----------------------------Doctors---------------------------------------
INSERT INTO Doctors (DepartmentID, FullName, Email, TelephoneNumber, Specialization)
VALUES
(1, 'Dr. Lily Ash', 'lily.ash@email.com', '07675378901', 'Cardiologist'),
(2, 'Dr. Winter Childs', 'winter.childs@email.com', '07824681555', 'Pediatrician'),
(3, 'Dr. Muko Oak', 'muko.oak@email.com', '07945256803', 'Oncologist'),
(4, 'Dr. Sack Jove', 'sac.jove@email.com', '07175903844', 'Neurologist'),
(5, 'Dr. Erico Billy', 'erico.billy@email.com', '07666444986', 'Orthopedic Surgeon'),
(6, 'Dr. Dan Lush', 'dan.lush@email.com', '07129856223', 'ER Doctor'),
(7, 'Dr. Mary Patern', 'mary.patern@email.com', '07842853665', 'Obstetrician/Gynecologist'),
(8, 'Dr. Zubby Sky', 'zubby.sky@email.com', '07111568700', 'Dermatologist'),
(9, 'Dr. Mallam Wind', 'mallam.wind@email.com', '07444678341', 'Psychiatrist'),
(10, 'Dr. Sun Ray', 'sun.ray@email.com', '07467321987', 'Radiologist'),
(11, 'Dr. Adam Eve', 'adam.eve@email.com', '07763598607', 'Anesthesiologist'),
(12, 'Dr. Zaron Zip', 'zaron.zip@email.com', '07645892345', 'Ophthalmologist'),
(13, 'Dr. Milani Pop', 'milani.pop@email.com', '07548997145', 'Urologist'),
(14, 'Dr. Tara Glossy', 'tara.glossy@email.com', '07076543278', 'Endocrinologist'),
(15, 'Dr. Mattie Lipsy', 'mattie.lipsy@email.com', '07167833219', 'Gastroenterologist');

-----------------retrieving all data from Doctors table----------------------------------------
select * from Doctors;



----------------------------DoctorAvailability---------------------------------------
INSERT INTO DoctorAvailability (DoctorID, Days, StartTime, EndTime, AvailabilityStatus)
VALUES
(1, 'Mon,Wed,Fri', '08:00:00', '16:00:00', 'Available'),
(2, 'Tue,Thu', '09:00:00', '17:00:00', 'Available'),
(3, 'Mon,Wed,Fri', '10:00:00', '18:00:00', 'Available'),
(4, 'Tue,Thu', '08:00:00', '16:00:00', 'Available'),
(5, 'Mon,Wed,Fri', '07:00:00', '15:00:00', 'Available'),
(6, 'Mon,Tue,Wed,Thu,Fri', '09:00:00', '17:00:00', 'Available'),
(7, 'Tue,Thu', '10:00:00', '18:00:00', 'Available'),
(8, 'Wed,Fri', '08:00:00', '16:00:00', 'Available'),
(9, 'Mon,Wed', '07:00:00', '15:00:00', 'Available'),
(10, 'Tue,Thu,Fri', '10:00:00', '18:00:00', 'Available'),
(11, 'Mon,Wed,Fri', '09:00:00', '17:00:00', 'Available'),
(12, 'Tue,Thu', '08:00:00', '16:00:00', 'Available'),
(13, 'Mon,Wed,Fri', '07:00:00', '15:00:00', 'Available'),
(14, 'Tue,Thu', '10:00:00', '18:00:00', 'Available'),
(15, 'Mon,Tue,Wed,Thu,Fri', '09:00:00', '17:00:00', 'Available');

-----------------retrieving all data from DoctorAvailability table----------------------------------------
select * from DoctorAvailability;



----------------------------------------------Appointments table---------------------------------------------
INSERT INTO Appointments (PatientID, DoctorID, DepartmentID, PastAppointmentDate, AppointmentDate, AppointmentTime, Status)
VALUES
(1, 1, 1, NULL,'2023-12-01', '09:00', 'Pending'),
(2, 2, 2, '2022-12-29', '2023-08-02', '10:00', 'Completed'),
(3, 3, 3,  '2023-05-03','2024-01-02', '11:00', 'Cancelled'),
(4, 4, 4, '2023-01-24','2023-08-04', '09:00', 'Pending'),
(5, 5, 5, NULL,'2023-08-05', '10:00', 'Completed'),
(6, 6, 6, NULL,'2024-04-04', '11:00', 'Pending'),
(7, 7, 7, NULL, '2023-08-07', '09:00', 'Cancelled'),
(8, 8, 8, '2023-02-18', '2023-08-08', '10:00', 'Completed'),
(9, 9, 9, NULL,'2023-08-09', '11:00', 'Cancelled'),
(10, 10, 10, '2023-06-01','2023-08-10', '09:00', 'Pending'),
(11, 11, 11, '2023-04-12','2024-08-11', '10:00', 'Completed'),
(12, 12, 12, '2023-06-28' ,'2023-08-12', '11:00','Cancelled'),
(13, 13, 13,NULL, '2024-03-01', '09:00', 'Pending'),
(14, 14, 14,NULL, '2023-08-15', '11:00', 'Completed'),
(15, 15, 15,NULL,  '2023-08-15', '11:00', 'Completed');

-----------------retrieving all data from Appointments table----------------------------------------
select * from Appointments;



---------------ArchivedAppointments-----------------
INSERT INTO ArchivedAppointments (AppointmentID, PatientID, DoctorID, DepartmentID, PastAppointmentDate, 
    AppointmentDate,  AppointmentTime, Status, ArchivedDate
)
SELECT 
    AppointmentID, PatientID, DoctorID, DepartmentID, PastAppointmentDate, AppointmentDate, 
    AppointmentTime, Status, GETDATE() AS ArchivedDate
FROM Appointments;

-----------------retrieving all data from ArchivedAppointments table----------------------------------------
select * from ArchivedAppointments;



-------------------------------Medicalrecord------------------------------
INSERT INTO MedicalRecords (AppointmentID, PatientID, Diagnosis, Allergies, RecordDate)
VALUES
(1, 1, 'Hypertension', 'None', '2023-08-01'),
(2, 2, 'Diabetes Mellitus', 'Penicillin', '2023-08-02'),
(3, 3, 'Asthma', 'Aspirin', '2023-08-03'),
(4, 4, 'Cancer', 'None', '2023-08-04'),
(5, 5, 'Gastroenteritis', 'Ibuprofen', '2023-08-05'),
(6, 6, 'Acute Bronchitis', 'None', '2023-08-06'),
(7, 7, 'Upper Respiratory Tract Infection', 'Latex', '2023-08-07'),
(8, 8, 'Urinary Tract Infection', 'Sulfa Drugs', '2023-08-08'),
(9, 9, 'Conjunctivitis', 'None', '2023-08-09'),
(10, 10, 'Otitis Media', 'Peanuts', '2023-08-10'),
(11, 11, 'Sinusitis', 'None', '2023-08-11'),
(12, 12, 'Strep Throat', 'Dairy', '2023-08-12'),
(13, 13, 'Influenza', 'Eggs', '2023-08-13'),
(14, 14, 'Gastroesophageal Reflux Disease', 'Gluten', '2023-08-15'),
(15, 15, 'Cancer', 'Iodine', '2023-03-01');

-----------------retrieving all data from MedicalRecords table----------------------------------------
select * from MedicalRecords;



--------------------------Prescription table--------------------------
INSERT INTO Prescriptions (AppointmentID, PatientID, PrescribedMedicine, Dosage, Frequency, Duration, Notes, PrescriptionDate)
VALUES
(1, 1, 'Lisinopril', '10mg', 'Once daily', '30 days', 'For hypertension', '2023-08-01'),
(2, 2, 'Metformin', '500mg', 'Twice daily', '30 days', 'For diabetes', '2023-08-02'),
(3, 3, 'Albuterol', '2 puffs', 'Every 4-6 hours as needed', '30 days', 'For asthma', '2023-08-03'),
(4, 4, 'Amoxicillin', '500mg', 'Three times daily', '7 days', 'For bacterial infection', '2023-08-04'),
(5, 5, 'Omeprazole', '20mg', 'Once daily', '14 days', 'For gastroenteritis', '2023-08-05'),
(6, 6, 'Azithromycin', '250mg', 'Once daily', '5 days', 'For bronchitis', '2023-08-06'),
(7, 7, 'Cetirizine', '10mg', 'Once daily', '14 days', 'For allergies', '2023-08-07'),
(8, 8, 'Ciprofloxacin', '250mg', 'Twice daily', '7 days', 'For UTI', '2023-08-08'),
(9, 9, 'Moxifloxacin', '0.5%', 'Four times daily', '7 days', 'For conjunctivitis', '2023-08-09'),
(10, 10, 'Amoxicillin', '500mg', 'Three times daily', '7 days', 'For ear infection', '2023-08-10'),
(11, 11, 'Fluticasone propionate', '2 sprays each nostril daily','Every 8 hours', '30 days', 'For sinusitis', '2023-08-11'),
(12, 12, 'Penicillin', '500mg', 'Four times daily', '10 days', 'For strep throat', '2023-08-12'),
(13, 13, 'Oseltamivir', '75mg', 'Twice daily', '5 days', 'For influenza', '2023-08-13'), 
(14, 14, 'Esomeprazole', '40mg', 'Once daily', '30 days', 'For GERD', '2023-08-15'),
(15, 15, 'Tolvaptan', '15 mg', 'Once daily', '90 days', 'To slow kidney function decline', '2023-03-01');

-----------------retrieving all data from Prescriptions table----------------------------------------
select * from Prescriptions;



----------------Feedback table--------------------
INSERT INTO Feedback (AppointmentID, PatientID, DoctorID, FeedbackText, Rating, FeedbackDate)
VALUES
(1, 1, 1, 'Exceptional care and thorough explanation of treatment plan.', 5, '2023-08-01'),
(2, 2, 2, 'Very patient and understanding, highly recommend.', 5, '2023-08-02'),
(3, 3, 3, 'The wait time was longer than expected, but the service was good.', 4, '2023-08-03'),
(4, 4, 4, 'Professional and friendly, made me feel at ease.', 5, '2023-08-04'),
(5, 5, 5, 'Needed more clarity on the medication prescribed.', 3, '2023-08-05'),
(6, 6, 6, 'Excellent bedside manner and medical knowledge.', 5, '2023-08-06'),
(7, 7, 7, 'The appointment felt rushed.', 3, '2023-08-07'),
(8, 8, 8, 'Answered all my questions, very thorough.', 5, '2023-08-08'),
(9, 9, 9, 'Great experience, would definitely come back.', 5, '2023-08-09'),
(10, 10, 10, 'Not very punctual, had to wait a long time.', 2, '2023-08-10'),
(11, 11, 11, 'Friendly staff and clean facility.', 4, '2023-08-11'),
(12, 12, 12, 'Could improve on communication.', 3, '2023-08-12'),
(13, 13, 13, 'Felt very cared for, excellent service.', 5, '2023-08-13'),
(14, 14, 14, 'Very satisfied with the treatment received.', 5, '2023-08-15'),
(15, 15, 15, 'Excellent follow-up and care plan. Very satisfied with the treatment received.', 5, '2023-03-02');

-----------------retrieving all data from Feedback table----------------------------------------
select * from Feedback;



----------------Question 2:Add the constraint to check that the appointment date is not in the past.-----------------------------
ALTER TABLE Appointments
WITH NOCHECK
ADD CONSTRAINT CHK_AppointmentDate_NotPast CHECK (AppointmentDate >= CAST(GETDATE() AS DATE));

-------- testing the constraint ------
INSERT INTO Appointments (PatientID, DoctorID, DepartmentID, PastAppointmentDate, AppointmentDate, AppointmentTime, Status)
VALUES (4, 4, 4, '2023-01-24','2021-08-04', '09:00', 'Pending');



-------------Question 3 List all the patients with older than 40 and have Cancer in diagnosis.----------------------
SELECT DISTINCT p.PatientID, p.FullName, p.DateOfBirth, p.Address, p.Insurance, p.Email, p.TelephoneNumber
FROM Patients p
JOIN MedicalRecords mr ON p.PatientID = mr.PatientID
WHERE mr.Diagnosis LIKE '%Cancer%'
AND DATEDIFF(year, p.DateOfBirth, GETDATE()) > 40;



-------------Question 4a  Procedure to Search by Medicine name---------------
GO
CREATE PROCEDURE SearchByMedicineName
    @MedicineName VARCHAR(100)
AS
BEGIN
    SELECT 
        pr.PrescriptionID, pr.PrescribedMedicine, pr.PrescriptionDate, p.FullName AS PatientName, d.FullName AS DoctorName, dep.DepartmentName
    FROM Prescriptions pr
    INNER JOIN Appointments a ON pr.AppointmentID = a.AppointmentID
    INNER JOIN Patients p ON a.PatientID = p.PatientID
    INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
    INNER JOIN Departments dep ON d.DepartmentID = dep.DepartmentID
    WHERE pr.PrescribedMedicine LIKE '%' + @MedicineName + '%'
    ORDER BY pr.PrescriptionDate DESC;
END;
GO

-------- executing the Stored Procedure to search for  'Amoxicillin'------

EXEC SearchByMedicineName @MedicineName = 'Amoxicillin';



-------------Question 4b  Procedure to GetPatientDiagnosisAndAllergiesForToday ------------------------------
GO
CREATE OR ALTER PROCEDURE GetPatientDiagnosisAndAllergiesForToday
    @Today DATE
AS
BEGIN
    SELECT p.PatientID, p.FullName AS PatientName, a.AppointmentDate, mr.Diagnosis, mr.Allergies
    FROM Appointments a
        INNER JOIN Patients p ON a.PatientID = p.PatientID
        INNER JOIN MedicalRecords mr ON a.AppointmentID = mr.AppointmentID
    WHERE CONVERT(DATE, a.AppointmentDate) = @Today;
END;
GO

-------- executing the Stored Procedure to get patient diagnosis and allergies for today------
EXEC GetPatientDiagnosisAndAllergiesForToday @Today = '2024-04-04';




-----------------------Question 4c  Procedure to Update the details for an existing doctor-----------------------
GO
CREATE OR ALTER PROCEDURE UpdateDoctorDetails
    @DoctorID INT,
    @FullName VARCHAR(100),
    @Email VARCHAR(100),
    @TelephoneNumber VARCHAR(30),
    @Specialization VARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Doctors WHERE DoctorID = @DoctorID)
    BEGIN
        UPDATE Doctors
        SET FullName = @FullName, Email = @Email, TelephoneNumber = @TelephoneNumber, Specialization = @Specialization
        WHERE DoctorID = @DoctorID;
    END
    ELSE
    BEGIN
        PRINT 'Doctor not found.';
    END
END;
GO

-------- executing the Stored Procedure update doctors details------
EXEC UpdateDoctorDetails 
    @DoctorID = 8,
    @FullName = 'Dr. Sam Dome',
    @Email = 'sam.dome@email.com',
    @TelephoneNumber = '07027487287',
    @Specialization = 'General pratitioner';


-------------checking the updated details
SELECT DoctorID, FullName, Email, TelephoneNumber, Specialization
FROM Doctors
WHERE DoctorID = 8; 



-------------------Question 4d Procedure to delete the appointment who status is completed----------------------
GO
CREATE PROCEDURE DeleteCompletedAppointments
AS
BEGIN
    DELETE FROM ArchivedAppointments
    WHERE Status = 'Completed';
END;
GO

-------- executing the Stored Procedure to delete completed appointments------
EXEC DeleteCompletedAppointments;

-------retrieving all from appointment to if completed appointments have been deleted
select * from ArchivedAppointments

-----------Transaction handling-----------------
BEGIN TRY
    BEGIN TRANSACTION;
        DELETE FROM ArchivedAppointments
        WHERE Status = 'Completed';
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
END CATCH;



------------------Question 5  Views to display the Doctors Appointment Details-------------------
GO
CREATE OR ALTER VIEW DoctorAppointmentsDetails AS
SELECT a.AppointmentID, a.AppointmentDate, a.AppointmentTime, d.FullName AS DoctorName,
d.Specialization, dept.DepartmentName, f.FeedbackText, f.Rating
FROM Appointments a
INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
INNER JOIN Departments dept ON d.DepartmentID = dept.DepartmentID
LEFT JOIN Feedback f ON a.AppointmentID = f.AppointmentID
GO

-------- retrieving view DoctorAppointmentsDetails------
SELECT * FROM DoctorAppointmentsDetails
ORDER BY AppointmentDate DESC, AppointmentTime DESC;



--------------------Question 6 Trigger to update Appointment Status-----------------------
GO
CREATE OR ALTER TRIGGER UpdateAppointmentAvailability
ON Appointments
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Status)
    BEGIN
        UPDATE a
        SET a.Status = 'Available'
        FROM Appointments a
        JOIN inserted i ON a.AppointmentID = i.AppointmentID
        WHERE i.Status = 'Cancelled';
    END
END;
GO

-------- testing Trigger UpdateAppointmentAvailability------

UPDATE Appointments
SET Status = 'Cancelled'
WHERE AppointmentID = 12 ;



SELECT a.*, d.FullName AS DoctorName, p.FullName AS PatientName
FROM Appointments a
INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
INNER JOIN Patients p ON a.PatientID = p.PatientID
WHERE a.AppointmentID = 12;



-------Question 7 returning CompletedGastroenterologistAppointments----------------
SELECT COUNT(a.AppointmentID) AS CompletedGastroenterologistAppointments
FROM Appointments a
JOIN Doctors d ON a.DoctorID = d.DoctorID
WHERE d.Specialization = 'Gastroenterologist'
 AND a.Status = 'Completed';


 -------------------------------------------------------------------------------------------
 --PERFORMING FULL BACKUP and RESTORE DATABASE
 ---------------------------------------------------------------------------------------------
BACKUP DATABASE [HospitalDB]
TO DISK = 'C:\\Users\\ooluw\\Desktop\\SHOJUPE_@00747127\\HospitalDB.bak'
GO


 USE [master]
 RESTORE DATABASE  [HospitalDB] FROM
 DISK = 'C:\\Users\\ooluw\\Desktop\\SHOJUPE_@00747127\\HospitalDB.bak'
 GO