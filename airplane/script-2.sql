IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'AirlineDB')
BEGIN
    CREATE DATABASE AirlineDB;
    PRINT 'Base de datos "AirlineDB" creada exitosamente.';
END
ELSE
BEGIN
    PRINT 'La base de datos "AirlineDB" ya existe.';
END
GO

USE AirlineDB;
GO

-- tabla country
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'country' AND type = 'U')
BEGIN
    CREATE TABLE country (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        country_name VARCHAR(100) UNIQUE NOT NULL,
        iso_code CHAR(3) NOT NULL
    );
    PRINT 'Tabla "country" creada exitosamente.';
END
GO

-- tabla city
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'city' AND type = 'U')
BEGIN
    CREATE TABLE city (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        city_name VARCHAR(100) NOT NULL,
        zip_code VARCHAR(10) NOT NULL,
        country_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (country_id) REFERENCES country(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "city" creada exitosamente.';
END
GO

-- tabla customer
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'customer' AND type = 'U')
BEGIN
    CREATE TABLE customer (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        date_of_birth DATE NOT NULL CHECK (date_of_birth < GETDATE())
    );
    PRINT 'Tabla "customer" creada exitosamente.';
END
GO

-- tabla frequent_flyer_card
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'frequent_flyer_card' AND type = 'U')
BEGIN
    CREATE TABLE frequent_flyer_card (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        ftc_number INT DEFAULT 0 CHECK (ftc_number >= 0),
        miles INT DEFAULT 0 CHECK (miles >= 0),
        meal_code VARCHAR(10),
        customer_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "frequent_flyer_card" creada exitosamente.';
END
GO

-- tabla nationality
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'nationality' AND type = 'U')
BEGIN
    CREATE TABLE nationality (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        name VARCHAR(100) NOT NULL
    );
    PRINT 'Tabla "nationality" creada exitosamente.';
END
GO

-- tabla passport
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'passport' AND type = 'U')
BEGIN
    CREATE TABLE passport (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        passport_number VARCHAR(50) NOT NULL UNIQUE,
        issue_date DATE NOT NULL,
        expiration_date DATE NOT NULL,
        customer_id UNIQUEIDENTIFIER NOT NULL,
        nationality_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE,
        FOREIGN KEY (nationality_id) REFERENCES nationality(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "passport" creada exitosamente.';
END
GO

-- Eliminar el trigger si ya existe
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'TRG_CheckExpirationDate')
BEGIN
    DROP TRIGGER TRG_CheckExpirationDate;
END
GO

-- Crear un TRIGGER para validar que expiration_date > issue_date
CREATE TRIGGER TRG_CheckExpirationDate
ON passport
FOR INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Verificar si algún registro no cumple con la condición
    IF EXISTS (SELECT 1 FROM inserted WHERE expiration_date <= issue_date)
    BEGIN
        -- Lanzar un error si expiration_date no es mayor que issue_date
        RAISERROR('La fecha de expiration_date debe ser mayor que issue_date.', 16, 1);
        -- Revertir la transacción
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

PRINT 'Trigger "TRG_CheckExpirationDate" creado exitosamente.';
GO

-- tabla identity_document
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'identity_document' AND type = 'U')
BEGIN
    CREATE TABLE identity_document (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        document_type VARCHAR(50) NOT NULL,
        document_number VARCHAR(50) NOT NULL UNIQUE,
        customer_id UNIQUEIDENTIFIER NOT NULL,
        nationality_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE,
        FOREIGN KEY (nationality_id) REFERENCES nationality(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "identity_document" creada exitosamente.';
END
GO

-- tabla airport
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'airport' AND type = 'U')
BEGIN
    CREATE TABLE airport (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        city_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (city_id) REFERENCES city(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "airport" creada exitosamente.';
END
GO

-- tabla plane_model
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'plane_model' AND type = 'U')
BEGIN
    CREATE TABLE plane_model (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        description VARCHAR(100) NOT NULL,
        graphic VARCHAR(255)
    );
    PRINT 'Tabla "plane_model" creada exitosamente.';
END
GO

-- tabla flight_number
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'flight_number' AND type = 'U')
BEGIN
    CREATE TABLE flight_number (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        departure_time DATETIME NOT NULL,
        description VARCHAR(255),
        type VARCHAR(50) NOT NULL,
        airline VARCHAR(50) NOT NULL,
        start_airport_id UNIQUEIDENTIFIER NOT NULL,
        goal_airport_id UNIQUEIDENTIFIER NOT NULL,
        plane_model_id UNIQUEIDENTIFIER,
        FOREIGN KEY (start_airport_id) REFERENCES airport(id) ON DELETE NO ACTION,
        FOREIGN KEY (goal_airport_id) REFERENCES airport(id) ON DELETE NO ACTION,
        FOREIGN KEY (plane_model_id) REFERENCES plane_model(id) ON DELETE SET NULL
    );
    PRINT 'Tabla "flight_number" creada exitosamente.';
END
GO

-- tabla category
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'category' AND type = 'U')
BEGIN
    CREATE TABLE category (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        name VARCHAR(50) NOT NULL,
        description VARCHAR(255)
    );
    PRINT 'Tabla "category" creada exitosamente.';
END
GO

-- tabla flight
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'flight' AND type = 'U')
BEGIN
    CREATE TABLE flight (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        boarding_time DATETIME NOT NULL,
        flight_date DATETIME NOT NULL,
        gate VARCHAR(50) NOT NULL,
        check_in_counter INT NOT NULL CHECK (check_in_counter > 0),
        flight_number_id UNIQUEIDENTIFIER NOT NULL,
        category_id UNIQUEIDENTIFIER,
        FOREIGN KEY (flight_number_id) REFERENCES flight_number(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE SET NULL
    );
    PRINT 'Tabla "flight" creada exitosamente.';
END
GO

-- tabla airplane
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'airplane' AND type = 'U')
BEGIN
    CREATE TABLE airplane (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        registration_number VARCHAR(50) NOT NULL UNIQUE,
        begin_of_operation DATE NOT NULL,
        status VARCHAR(20) DEFAULT 'Active' NOT NULL,
        plane_model_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (plane_model_id) REFERENCES plane_model(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "airplane" creada exitosamente.';
END
GO

-- tabla seat
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'seat' AND type = 'U')
BEGIN
    CREATE TABLE seat (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        size VARCHAR(10) NOT NULL,
        number INT NOT NULL CHECK (number > 0),
        location VARCHAR(50) NOT NULL,
        plane_model_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (plane_model_id) REFERENCES plane_model(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "seat" creada exitosamente.';
END
GO

-- tabla ticket
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'ticket' AND type = 'U')
BEGIN
    CREATE TABLE ticket (
        ticketing_code VARCHAR(50) PRIMARY KEY,
        number INT NOT NULL CHECK (number > 0),
        customer_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "ticket" creada exitosamente.';
END
GO

-- tabla coupon
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'coupon' AND type = 'U')
BEGIN
    CREATE TABLE coupon (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        date_of_redemption DATE,
        class CHAR(1) CHECK (class IN ('E', 'B', 'F')),
        standby BIT DEFAULT 0,
        meal_code VARCHAR(10),
        ticket_code VARCHAR(50),
        flight_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (ticket_code) REFERENCES ticket(ticketing_code) ON DELETE CASCADE,
        FOREIGN KEY (flight_id) REFERENCES flight(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "coupon" creada exitosamente.';
END
GO

-- tabla available_seat
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'available_seat' AND type = 'U')
BEGIN
    CREATE TABLE available_seat (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        flight_id UNIQUEIDENTIFIER NOT NULL,
        seat_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (flight_id) REFERENCES flight(id) ON DELETE CASCADE,
        FOREIGN KEY (seat_id) REFERENCES seat(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "available_seat" creada exitosamente.';
END
GO

-- tabla pieces_of_luggage
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'pieces_of_luggage' AND type = 'U')
BEGIN
    CREATE TABLE pieces_of_luggage (
        id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
        number INT CHECK (number > 0),
        weight FLOAT CHECK (weight > 0),
        coupon_id UNIQUEIDENTIFIER NOT NULL,
        FOREIGN KEY (coupon_id) REFERENCES coupon(id) ON DELETE CASCADE
    );
    PRINT 'Tabla "pieces_of_luggage" creada exitosamente.';
END
GO
