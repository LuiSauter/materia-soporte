-- Task: script 3
-- generar indices que no son para los atributos que no sean solo para primary keys
-- reindexar la base de datos

-- Verificar si la base de datos ya existe
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

-- Índices adicionales para optimización de consultas
CREATE INDEX IDX_City_Country ON city(country_id);
CREATE INDEX IDX_Airport_City ON airport(city_id);
CREATE INDEX IDX_Flight_FlightNumber ON flight(flight_number_id);
CREATE INDEX IDX_AvailableSeat_Seat ON available_seat(seat_id);
CREATE INDEX IDX_Passport_Customer ON passport(customer_id);
CREATE INDEX IDX_IdentityDocument_Customer ON identity_document(customer_id);
CREATE INDEX IDX_Coupon_Ticket ON coupon(ticket_code);


-- reindexar toda la base de datos.
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'usp_ReindexDatabase' AND type = 'P')
BEGIN
    DROP PROCEDURE usp_ReindexDatabase;
END
GO

CREATE PROCEDURE usp_ReindexDatabase
AS
BEGIN
    DECLARE @TableName NVARCHAR(255);
    DECLARE @SQL NVARCHAR(MAX);

    DECLARE TableCursor CURSOR FOR
    SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) AS TableName
    FROM sys.tables;

    OPEN TableCursor;

    FETCH NEXT FROM TableCursor INTO @TableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Imprime el nombre de la tabla que se está reindexando
        PRINT 'Reindexando tabla: ' + @TableName;

        SET @SQL = 'ALTER INDEX ALL ON ' + @TableName + ' REBUILD';
        EXEC(@SQL);

        FETCH NEXT FROM TableCursor INTO @TableName;
    END;

    CLOSE TableCursor;
    DEALLOCATE TableCursor;
END
GO

EXEC usp_ReindexDatabase;

-- poblar base de datos, fuente: GitHub Copilot
BEGIN TRY
    -- Iniciar la transacción
    BEGIN TRANSACTION;

    -- Insertar países
    IF NOT EXISTS (SELECT * FROM country WHERE country_name = 'Bolivia')
    BEGIN
        INSERT INTO country (country_name, iso_code) VALUES ('Bolivia', 'BO');
    END

    IF NOT EXISTS (SELECT * FROM country WHERE country_name = 'Argentina')
    BEGIN
        INSERT INTO country (country_name, iso_code) VALUES ('Argentina', 'AR');
    END

    IF NOT EXISTS (SELECT * FROM country WHERE country_name = 'Brasil')
    BEGIN
        INSERT INTO country (country_name, iso_code) VALUES ('Brasil', 'BR');
    END

    IF NOT EXISTS (SELECT * FROM country WHERE country_name = 'Chile')
    BEGIN
        INSERT INTO country (country_name, iso_code) VALUES ('Chile', 'CL');
    END

    IF NOT EXISTS (SELECT * FROM country WHERE country_name = 'Perú')
    BEGIN
        INSERT INTO country (country_name, iso_code) VALUES ('Perú', 'PE');
    END

    -- Insertar ciudades de Bolivia
    IF NOT EXISTS (SELECT * FROM city WHERE city_name = 'La Paz')
    BEGIN
        INSERT INTO city (city_name, zip_code, country_id) VALUES
        ('La Paz', '0001', (SELECT id FROM country WHERE country_name = 'Bolivia'));
    END

    IF NOT EXISTS (SELECT * FROM city WHERE city_name = 'Santa Cruz')
    BEGIN
        INSERT INTO city (city_name, zip_code, country_id) VALUES
        ('Santa Cruz', '0002', (SELECT id FROM country WHERE country_name = 'Bolivia'));
    END

    IF NOT EXISTS (SELECT * FROM city WHERE city_name = 'Cochabamba')
    BEGIN
        INSERT INTO city (city_name, zip_code, country_id) VALUES
        ('Cochabamba', '0003', (SELECT id FROM country WHERE country_name = 'Bolivia'));
    END

    IF NOT EXISTS (SELECT * FROM city WHERE city_name = 'Sucre')
    BEGIN
        INSERT INTO city (city_name, zip_code, country_id) VALUES
        ('Sucre', '0004', (SELECT id FROM country WHERE country_name = 'Bolivia'));
    END

    IF NOT EXISTS (SELECT * FROM city WHERE city_name = 'Potosí')
    BEGIN
        INSERT INTO city (city_name, zip_code, country_id) VALUES
        ('Potosí', '0005', (SELECT id FROM country WHERE country_name = 'Bolivia'));
    END

    -- Insertar clientes en Bolivia
    IF NOT EXISTS (SELECT * FROM customer WHERE name = 'Juan Perez')
    BEGIN
        INSERT INTO customer (name, date_of_birth) VALUES
        ('Juan Perez', '1985-06-15'),
        ('María Gomez', '1990-02-20'),
        ('Carlos Quispe', '1980-11-30'),
        ('Ana Condori', '1975-07-25'),
        ('Luis Mamani', '1995-01-05');
    END

    -- Insertar tarjetas de pasajero frecuente
    IF NOT EXISTS (SELECT * FROM frequent_flyer_card WHERE ftc_number = 123456)
    BEGIN
        INSERT INTO frequent_flyer_card (ftc_number, miles, meal_code, customer_id) 
        VALUES 
        (123456, 10000, 'VGML', (SELECT id FROM customer WHERE name = 'Juan Perez')),
        (789012, 20000, 'GLUT', (SELECT id FROM customer WHERE name = 'María Gomez')),
        (345678, 15000, 'KSML', (SELECT id FROM customer WHERE name = 'Carlos Quispe')),
        (901234, 25000, 'HNML', (SELECT id FROM customer WHERE name = 'Ana Condori')),
        (567890, 5000, 'VJML', (SELECT id FROM customer WHERE name = 'Luis Mamani'));
    END

    -- Insertar nacionalidades
    IF NOT EXISTS (SELECT * FROM nationality WHERE name = 'Boliviana')
    BEGIN
        INSERT INTO nationality (name) VALUES
        ('Boliviana'),
        ('Argentina'),
        ('Brasileña'),
        ('Chilena'),
        ('Peruana');
    END

    -- Insertar pasaportes
    IF NOT EXISTS (SELECT * FROM passport WHERE passport_number = 'BO123456')
    BEGIN
        INSERT INTO passport (passport_number, issue_date, expiration_date, customer_id, nationality_id) 
        VALUES 
        ('BO123456', '2020-01-01', '2030-01-01', 
         (SELECT id FROM customer WHERE name = 'Juan Perez'), 
         (SELECT id FROM nationality WHERE name = 'Boliviana')),
        ('BO654321', '2021-06-15', '2031-06-15', 
         (SELECT id FROM customer WHERE name = 'María Gomez'), 
         (SELECT id FROM nationality WHERE name = 'Boliviana')),
        ('BO789123', '2019-11-01', '2029-11-01', 
         (SELECT id FROM customer WHERE name = 'Carlos Quispe'), 
         (SELECT id FROM nationality WHERE name = 'Boliviana')),
        ('BO321987', '2022-03-10', '2032-03-10', 
         (SELECT id FROM customer WHERE name = 'Ana Condori'), 
         (SELECT id FROM nationality WHERE name = 'Boliviana')),
        ('BO456789', '2023-07-20', '2033-07-20', 
         (SELECT id FROM customer WHERE name = 'Luis Mamani'), 
         (SELECT id FROM nationality WHERE name = 'Boliviana'));
    END

    -- Insertar documentos de identidad
    IF NOT EXISTS (SELECT * FROM identity_document WHERE document_number = 'IDBOL123456')
    BEGIN
        INSERT INTO identity_document (document_type, document_number, customer_id, nationality_id) 
        VALUES 
        ('Cédula de Identidad', 'IDBOL123456', 
         (SELECT id FROM customer WHERE name = 'Juan Perez'), 
         (SELECT id FROM nationality WHERE name = 'Boliviana')),
        ('Licencia de Conducir', 'IDBOL654321', 
         (SELECT id FROM customer WHERE name = 'María Gomez'), 
         (SELECT id FROM nationality WHERE name = 'Boliviana')),
        ('Pasaporte', 'IDBOL789123', 
         (SELECT id FROM customer WHERE name = 'Carlos Quispe'), 
         (SELECT id FROM nationality WHERE name = 'Boliviana')),
        ('Cédula de Identidad', 'IDBOL321987', 
         (SELECT id FROM customer WHERE name = 'Ana Condori'), 
         (SELECT id FROM nationality WHERE name = 'Boliviana')),
        ('Licencia de Conducir', 'IDBOL456789', 
         (SELECT id FROM customer WHERE name = 'Luis Mamani'), 
         (SELECT id FROM nationality WHERE name = 'Boliviana'));
    END

    -- Insertar aeropuertos en Bolivia
    IF NOT EXISTS (SELECT * FROM airport WHERE name = 'Aeropuerto Internacional El Alto')
    BEGIN
        INSERT INTO airport (name, city_id) VALUES
        ('Aeropuerto Internacional El Alto', (SELECT id FROM city WHERE city_name = 'La Paz')),
        ('Aeropuerto Internacional Viru Viru', (SELECT id FROM city WHERE city_name = 'Santa Cruz')),
        ('Aeropuerto Internacional Jorge Wilstermann', (SELECT id FROM city WHERE city_name = 'Cochabamba'));
    END

    -- Insertar modelos de avión
    IF NOT EXISTS (SELECT * FROM plane_model WHERE description = 'Boeing 737')
    BEGIN
        INSERT INTO plane_model (description, graphic) VALUES
        ('Boeing 737', 'graphic_737.png'),
        ('Airbus A320', 'graphic_a320.png'),
        ('Boeing 777', 'graphic_777.png'),
        ('Airbus A380', 'graphic_a380.png');
    END

    -- Insertar números de vuelo
    IF NOT EXISTS (SELECT * FROM flight_number WHERE departure_time = '2024-09-01 08:00:00')
    BEGIN
        INSERT INTO flight_number (departure_time, description, type, airline, start_airport_id, goal_airport_id, plane_model_id) 
        VALUES 
        ('2024-09-01 08:00:00', 'Vuelo de La Paz a Santa Cruz', 'Doméstico', 'Boliviana de Aviación', 
         (SELECT id FROM airport WHERE name = 'Aeropuerto Internacional El Alto'), 
         (SELECT id FROM airport WHERE name = 'Aeropuerto Internacional Viru Viru'), 
         (SELECT id FROM plane_model WHERE description = 'Boeing 737')),
        ('2024-09-02 09:00:00', 'Vuelo de Cochabamba a La Paz', 'Doméstico', 'Amaszonas', 
         (SELECT id FROM airport WHERE name = 'Aeropuerto Internacional Jorge Wilstermann'), 
         (SELECT id FROM airport WHERE name = 'Aeropuerto Internacional El Alto'), 
         (SELECT id FROM plane_model WHERE description = 'Airbus A320'));
    END

    -- Insertar categorías
    IF NOT EXISTS (SELECT * FROM category WHERE name = 'Económica')
    BEGIN
        INSERT INTO category (name, description) VALUES
        ('Económica', 'Clase económica estándar'),
        ('Negocios', 'Clase de negocios con servicios premium'),
        ('Primera Clase', 'Servicios y comodidades de lujo');
    END

    -- Insertar vuelos
    IF NOT EXISTS (SELECT * FROM flight WHERE boarding_time = '2024-09-01 08:00:00')
    BEGIN
        INSERT INTO flight (boarding_time, flight_date, gate, check_in_counter, flight_number_id, category_id) 
        VALUES 
        ('2024-09-01 08:00:00', '2024-09-01', 'A1', 1, 
         (SELECT id FROM flight_number WHERE departure_time = '2024-09-01 08:00:00'), 
         (SELECT id FROM category WHERE name = 'Económica')),
        ('2024-09-02 09:00:00', '2024-09-02', 'B1', 2, 
         (SELECT id FROM flight_number WHERE departure_time = '2024-09-02 09:00:00'), 
         (SELECT id FROM category WHERE name = 'Negocios'));
    END

    -- Insertar aviones
    IF NOT EXISTS (SELECT * FROM airplane WHERE registration_number = 'CP1234')
    BEGIN
        INSERT INTO airplane (registration_number, begin_of_operation, status, plane_model_id) 
        VALUES 
        ('CP1234', '2010-01-01', 'Activo', 
         (SELECT id FROM plane_model WHERE description = 'Boeing 737')),
        ('CP5678', '2015-05-15', 'Activo', 
         (SELECT id FROM plane_model WHERE description = 'Airbus A320'));
    END

    -- Insertar asientos
    IF NOT EXISTS (SELECT * FROM seat WHERE location = '1A')
    BEGIN
        INSERT INTO seat (size, number, location, plane_model_id) 
        VALUES 
        ('Económica', 1, '1A', (SELECT id FROM plane_model WHERE description = 'Boeing 737')),
        ('Económica', 2, '1B', (SELECT id FROM plane_model WHERE description = 'Boeing 737')),
        ('Negocios', 3, '2A', (SELECT id FROM plane_model WHERE description = 'Airbus A320')),
        ('Negocios', 4, '2B', (SELECT id FROM plane_model WHERE description = 'Airbus A320'));
    END

    -- Insertar boletos
    IF NOT EXISTS (SELECT * FROM ticket WHERE ticketing_code = 'BOLETO001')
    BEGIN
        INSERT INTO ticket (ticketing_code, number, customer_id) 
        VALUES 
        ('BOLETO001', 1, (SELECT id FROM customer WHERE name = 'Juan Perez')),
        ('BOLETO002', 1, (SELECT id FROM customer WHERE name = 'María Gomez')),
        ('BOLETO003', 1, (SELECT id FROM customer WHERE name = 'Carlos Quispe')),
        ('BOLETO004', 1, (SELECT id FROM customer WHERE name = 'Ana Condori')),
        ('BOLETO005', 1, (SELECT id FROM customer WHERE name = 'Luis Mamani'));
    END

    -- Insertar cupones
    IF NOT EXISTS (SELECT * FROM coupon WHERE ticket_code = 'BOLETO001')
    BEGIN
        INSERT INTO coupon (date_of_redemption, class, standby, meal_code, ticket_code, flight_id) 
        VALUES 
        ('2024-09-01', 'E', 0, 'VGML', 'BOLETO001', 
         (SELECT id FROM flight WHERE boarding_time = '2024-09-01 08:00:00')),
        ('2024-09-02', 'B', 1, 'GLUT', 'BOLETO002', 
         (SELECT id FROM flight WHERE boarding_time = '2024-09-02 09:00:00'));
    END

    -- Insertar asientos disponibles
    IF NOT EXISTS (SELECT * FROM available_seat WHERE seat_id = (SELECT id FROM seat WHERE location = '1A'))
    BEGIN
        INSERT INTO available_seat (flight_id, seat_id) 
        VALUES 
        ((SELECT id FROM flight WHERE flight_date = '2024-09-01'), 
         (SELECT id FROM seat WHERE location = '1A')),
        ((SELECT id FROM flight WHERE flight_date = '2024-09-01'), 
         (SELECT id FROM seat WHERE location = '1B')),
        ((SELECT id FROM flight WHERE flight_date = '2024-09-02'), 
         (SELECT id FROM seat WHERE location = '2A')),
        ((SELECT id FROM flight WHERE flight_date = '2024-09-02'), 
         (SELECT id FROM seat WHERE location = '2B'));
    END

    -- Insertar piezas de equipaje
    IF NOT EXISTS (SELECT * FROM pieces_of_luggage WHERE coupon_id = (SELECT id FROM coupon WHERE ticket_code = 'BOLETO001'))
    BEGIN
        INSERT INTO pieces_of_luggage (number, weight, coupon_id) 
        VALUES 
        (2, 23.0, (SELECT id FROM coupon WHERE ticket_code = 'BOLETO001')),
        (1, 15.0, (SELECT id FROM coupon WHERE ticket_code = 'BOLETO002'));
    END

    -- Confirmar la transacción
    COMMIT TRANSACTION;
    PRINT 'Datos insertados correctamente.';
END TRY
BEGIN CATCH
    -- Deshacer la transacción en caso de error
    ROLLBACK TRANSACTION;
    PRINT 'Ocurrió un error al insertar los datos: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Listar todos los clientes y sus respectivas ciudades en Bolivia
SELECT c.name AS NombreCliente, ci.city_name AS NombreCiudad
FROM customer c
JOIN frequent_flyer_card ffc ON c.id = ffc.customer_id
JOIN passport p ON c.id = p.customer_id
JOIN nationality n ON p.nationality_id = n.id
JOIN country co ON n.name = 'Boliviana'
JOIN city ci ON co.id = ci.country_id;

-- Listar todos los vuelos que parten de La Paz
SELECT fn.description AS DescripcionVuelo, a.name AS NombreAeropuerto, fn.departure_time AS HoraSalida
FROM flight_number fn
JOIN airport a ON fn.start_airport_id = a.id
JOIN city ci ON a.city_id = ci.id
WHERE ci.city_name = 'La Paz';

-- Mostrar los boletos y nombres de clientes para el vuelo que sale de La Paz a Santa Cruz
SELECT t.ticketing_code AS CodigoBoleto, c.name AS NombreCliente, f.flight_date AS FechaVuelo, fn.description AS DescripcionVuelo
FROM ticket t
JOIN customer c ON t.customer_id = c.id
JOIN coupon cp ON t.ticketing_code = cp.ticket_code
JOIN flight f ON cp.flight_id = f.id
JOIN flight_number fn ON f.flight_number_id = fn.id
WHERE fn.description = 'Vuelo de La Paz a Santa Cruz';
