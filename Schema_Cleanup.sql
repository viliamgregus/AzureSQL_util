CREATE PROCEDURE dbo.Schema_cleanup @schema_name nvarchar(4000)
AS

/*

Created by:		Viliam Gregus (S7A7VY)
Version 1.0:	13th March 2023
Project:		IRAMP ODS
Used for:		Risk System schema migration - IRI_RS

Generic procedure to drop selected schema and all its objects.

Example of use:
EXEC Schema_cleanup @schema_name = 'my_Schema_name'

Objects in scope, which will be deleted:
- Tables* 
- Views
- Procedures
- Functions
- Foreign Keys
-Sequences
*Primary Keys, Constraints and Indexes are dropped together with the table

*/

-- ##################################################################################
-- OPENING DECLARATIONS

-- for better performance
SET NOCOUNT ON

-- Variable declaration
DECLARE @sql nvarchar(4000)
DECLARE @table_name nvarchar(4000)
DECLARE @constraint_name nvarchar(4000)

-- ##################################################################################
-- VIEWS

WHILE
		
	--Loop while views exists
	EXISTS	(
			SELECT 
				1
			FROM   
				INFORMATION_SCHEMA.VIEWS
			WHERE  
				TABLE_SCHEMA = @schema_name
			)

BEGIN
	
	BEGIN TRY
			
		--Select View
		SET @table_name =	(
							SELECT TOP(1) 
								TABLE_NAME
							FROM
								INFORMATION_SCHEMA.VIEWS
							WHERE
								TABLE_SCHEMA	= @schema_name
							)
			
		--Create command to drop view
		SET @SQL = 	('DROP VIEW ' + @schema_name + '.' + @table_name)
			
		--Execute command
		EXEC	(@sql)
			
		--Print result
		PRINT	('View ' + @schema_name + '.' + @table_name + ' has been dropped.')
	
	END TRY

	BEGIN CATCH

		--Error handling:
		--Print at which view execution stopped
		PRINT	('Execution failed at view ' + @schema_name + '.' + @table_name + ' due to error: ')

		--Print error details
		PRINT	(ERROR_MESSAGE())
			
		--Stop execution
		BREAK

	END CATCH

END

--FOREIGN KEYS
--Note: Other types of constraints are dropped automatically with dropage of tables they are attached to
WHILE

	EXISTS	(
			SELECT	
				1
			FROM
				INFORMATION_SCHEMA.TABLE_CONSTRAINTS
			WHERE  
				TABLE_SCHEMA	= @schema_name AND	
				CONSTRAINT_TYPE = 'FOREIGN KEY'
			)

BEGIN
	
	BEGIN TRY

		SET @table_name =	(
							SELECT TOP(1) 
								TABLE_NAME
							FROM
								INFORMATION_SCHEMA.TABLE_CONSTRAINTS
							WHERE
								CONSTRAINT_TYPE = 'FOREIGN KEY' AND
								TABLE_SCHEMA = @schema_name
							ORDER BY 
								CONSTRAINT_NAME
							)

		SET @constraint_name =	(
								SELECT	TOP(1) 
									CONSTRAINT_NAME
								FROM	
									INFORMATION_SCHEMA.TABLE_CONSTRAINTS
								WHERE	
									CONSTRAINT_TYPE	= 'FOREIGN KEY' AND
									TABLE_SCHEMA	= @schema_name
								ORDER BY 
									CONSTRAINT_NAME 
								)

		SET @SQL =	(
					'ALTER TABLE ' +
						@schema_name + '.' + @table_name +
				    'DROP CONSTRAINT ' + 
						@constraint_name
					)

		EXEC(@sql)
	
	END TRY

	BEGIN CATCH
		
		--Print at which view execution stopped
		PRINT	('Execution failed at Constraint ' + @constraint_name + ' of object ' + @schema_name + '.' + @table_name + ' due to error: ')
		
		--Print error details 
		PRINT(ERROR_MESSAGE())
		
		--Stop execution
		BREAK

	END CATCH

END

--TABLES
WHILE 

	EXISTS	(
			SELECT	
				1
			FROM    
				INFORMATION_SCHEMA.TABLES
			WHERE   
				TABLE_SCHEMA	= @schema_name AND	 
				TABLE_TYPE		= 'BASE TABLE'
			)

BEGIN
	
	BEGIN TRY

		SET @table_name =	(
							SELECT  TOP(1) 
								TABLE_NAME
							FROM	 
								INFORMATION_SCHEMA.tables
							WHERE	 
								TABLE_SCHEMA = @schema_name AND
								TABLE_TYPE = 'BASE TABLE'
							)

		SET @SQL =	('DROP TABLE ' + @schema_name + '.' + @table_name)

		EXEC(@sql)

	END TRY

	BEGIN CATCH
	
		--Print at which view execution stopped
		PRINT	('Execution failed at Table ' + @schema_name + '.' + @table_name + ' due to error: ')
		
		--Print error details 
		PRINT(ERROR_MESSAGE())
		
		--Stop execution
		BREAK

	END CATCH

END

--PROCEDURES
WHILE 

	EXISTS	(
			SELECT	 
				1
			FROM    
				INFORMATION_SCHEMA.ROUTINES
			WHERE 
				SPECIFIC_SCHEMA = @schema_name AND	 
				ROUTINE_TYPE	= 'PROCEDURE'
			)

BEGIN
	
	BEGIN TRY

		SET @SQL =	(
					SELECT TOP(1) 
						'DROP PROCEDURE ' + @schema_name + '.' + SPECIFIC_NAME
					FROM	
						INFORMATION_SCHEMA.ROUTINES
					WHERE	
						SPECIFIC_SCHEMA = @schema_name AND
						ROUTINE_TYPE = 'PROCEDURE'
					)

		EXEC(@sql)

	END TRY

	BEGIN CATCH
	
		--Print at which view execution stopped
		PRINT	('Execution failed at Procedure ' + @schema_name + '.' + @table_name + ' due to error: ')
		
		--Print error details 
		PRINT(ERROR_MESSAGE())
		
		--Stop execution
		BREAK

	END CATCH

END

--FUNCTIONS
WHILE 

	EXISTS	(
			SELECT	 
				1
			FROM    
				INFORMATION_SCHEMA.ROUTINES
			WHERE   
				SPECIFIC_SCHEMA = @schema_name AND
				ROUTINE_TYPE = 'FUNCTION'
			)

BEGIN
	
	BEGIN TRY

		SET @SQL = 	(
					SELECT TOP(1) 
						'DROP FUNCTION ' + @schema_name + '.' + SPECIFIC_NAME
					FROM	
						INFORMATION_SCHEMA.ROUTINES
					WHERE
						SPECIFIC_SCHEMA = @schema_name AND
						ROUTINE_TYPE = 'FUNCTION'
					)

		EXEC(@sql)

	END TRY

	BEGIN CATCH
	
		print(ERROR_MESSAGE())
		BREAK

	END CATCH

END

--Sequences
WHILE 

	EXISTS	(
			SELECT	
				1
			FROM    
				sys.sequences
			WHERE   
				schema_name(schema_id) = @schema_name
			)


	BEGIN TRY
	SET @SQL = (
				SELECT TOP(1) 
					'DROP SEQUENCE IF EXISTS ' + @schema_name + '.'+ NAME
				FROM 
					sys.sequences
				)

	EXEC(@SQL)
	
	END TRY

	BEGIN CATCH
	
		PRINT(ERROR_MESSAGE())
		BREAK

	END CATCH


--Drop the schema itself as a final step
IF @schema_name <> 'dbo'
	BEGIN

	EXEC('DROP SCHEMA IF EXISTS '+@schema_name)

	END

GO