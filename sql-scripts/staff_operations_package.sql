-- Question 1: How can we add a new staff member while ensuring that their job title is valid?
CREATE OR REPLACE PROCEDURE staff_add (
    staff_name   IN VARCHAR2,
    staff_job    IN VARCHAR2,
    staff_salary IN NUMBER,
    staff_comm   IN NUMBER
)
AS
    new_staff_id NUMBER;
BEGIN
    -- Calculate the new ID
    SELECT MAX(ID) + 10 INTO new_staff_id FROM A1_STAFF;

    -- Validate the JOB input
    IF UPPER(staff_job) NOT IN ('SALES', 'CLERK', 'MGR', 'PREZ') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid JOB. Must be Sales, Clerk, Mgr, or Prez.');
    END IF;

    -- Insert the new record
    INSERT INTO A1_STAFF (ID, NAME, JOB, SALARY, COMM, DEPT, YEARS)
    VALUES (new_staff_id, staff_name, INITCAP(staff_job), staff_salary, staff_comm, 90, 1);

    DBMS_OUTPUT.PUT_LINE('Record successfully added with ID: ' || new_staff_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END;
/

ALTER TABLE A1_STAFF MODIFY (NAME VARCHAR2(50));

-- Successful insert example
BEGIN
    staff_add('jot khehra', 'sales', 50000, 2000);
END;
/

-- Unsuccessful insert example
BEGIN
    staff_add('bab mie', 'engineer', 60000, 2500); -- Invalid JOB
END;
/

-- Question 2: How can we ensure that only valid job titles are allowed during an INSERT operation?
CREATE OR REPLACE TRIGGER ins_job
BEFORE INSERT ON A1_STAFF
FOR EACH ROW
BEGIN
    -- Check if the JOB is valid
    IF UPPER(:NEW.JOB) NOT IN ('SALES', 'CLERK', 'MGR', 'PREZ') THEN
        -- Insert error record into staffAudit
        INSERT INTO staffAudit (ID, ACTION, INCJOB, OLDCOMM, NEWCOMM)
        VALUES (:NEW.ID, 'I', :NEW.JOB, NULL, NULL);
        -- Raise an error to stop the INSERT operation
        RAISE_APPLICATION_ERROR(-20002, 'Invalid JOB provided during INSERT operation.');
    END IF;
END;
/

-- Successful insert example
INSERT INTO A1_STAFF (ID, NAME, JOB, SALARY, COMM, DEPT, YEARS)
VALUES (1001, 'Arya Stark', 'Sales', 60000, 5000, 90, 1);

-- Unsuccessful insert example
INSERT INTO A1_STAFF (ID, NAME, JOB, SALARY, COMM, DEPT, YEARS)
VALUES (1002, 'A S', 'Engineer', 70000, 6000, 90, 1);

-- Question 3: How can we calculate the total compensation (salary + commission) for a given staff ID?
CREATE OR REPLACE FUNCTION total_cmp (
    staff_id IN NUMBER
)
RETURN NUMBER
AS
    total_comp NUMBER;
BEGIN
    -- Calculate total compensation
    SELECT SALARY + COMM
    INTO total_comp
    FROM A1_STAFF
    WHERE ID = staff_id;

    -- Return the result
    RETURN total_comp;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Handle invalid ID
        RAISE_APPLICATION_ERROR(-20003, 'Invalid ID: No staff member found with the provided ID.');
END;
/

-- Successful example
BEGIN
    DBMS_OUTPUT.PUT_LINE('Total Compensation: ' || total_cmp(1001)); 
END;
/

-- Unsuccessful example
BEGIN
    DBMS_OUTPUT.PUT_LINE('Total Compensation: ' || total_cmp(9999)); -- Invalid ID
END;
/

-- Question 4: How can we dynamically update the commission based on job titles?
CREATE OR REPLACE PROCEDURE set_comm
AS
    rows_updated NUMBER := 0;
BEGIN
    -- Update COMM for Mgr
    UPDATE A1_STAFF
    SET COMM = SALARY * 0.2
    WHERE UPPER(JOB) = 'MGR';
    rows_updated := rows_updated + SQL%ROWCOUNT;

    -- Update COMM for Clerk
    UPDATE A1_STAFF
    SET COMM = SALARY * 0.1
    WHERE UPPER(JOB) = 'CLERK';
    rows_updated := rows_updated + SQL%ROWCOUNT;

    -- Update COMM for Sales
    UPDATE A1_STAFF
    SET COMM = SALARY * 0.3
    WHERE UPPER(JOB) = 'SALES';
    rows_updated := rows_updated + SQL%ROWCOUNT;

    -- Update COMM for Prez
    UPDATE A1_STAFF
    SET COMM = SALARY * 0.5
    WHERE UPPER(JOB) = 'PREZ';
    rows_updated := rows_updated + SQL%ROWCOUNT;

    -- Display message with the total number of records updated
    DBMS_OUTPUT.PUT_LINE(rows_updated || ' records were changed');
END;
/

-- Calling procedure
BEGIN
    set_comm;
END;
/

-- Question 5: How can we log all changes to the commission column during an update?
CREATE OR REPLACE TRIGGER upd_comm
BEFORE UPDATE OF COMM ON A1_STAFF
FOR EACH ROW
BEGIN
    -- Check if COMM has actually changed
    IF :OLD.COMM != :NEW.COMM THEN
        -- Insert a record into staffAudit
        INSERT INTO staffAudit (ID, ACTION, INCJOB, OLDCOMM, NEWCOMM)
        VALUES (:OLD.ID, 'U', NULL, :OLD.COMM, :NEW.COMM);
    END IF;
END;
/

-- Testing the trigger
BEGIN
    set_comm;
END;
/

-- Question 6: How can we format staff names with alternating uppercase and lowercase characters?
CREATE OR REPLACE FUNCTION fun_name (
    staff_id IN NUMBER
)
RETURN VARCHAR2
AS
    original_name VARCHAR2(100);
    formatted_name VARCHAR2(100) := '';
BEGIN
    -- Retrieve the name for the given ID
    SELECT NAME
    INTO original_name
    FROM A1_STAFF
    WHERE ID = staff_id;

    -- Alternate characters between upper and lower case
    FOR i IN 1..LENGTH(original_name) LOOP
        IF MOD(i, 2) = 1 THEN
            formatted_name := formatted_name || UPPER(SUBSTR(original_name, i, 1));
        ELSE
            formatted_name := formatted_name || LOWER(SUBSTR(original_name, i, 1));
        END IF;
    END LOOP;

    -- Return the formatted name
    RETURN formatted_name;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Invalid ID: No staff member found with the provided ID.');
END;
/

-- Successful example
BEGIN
    DBMS_OUTPUT.PUT_LINE('Formatted Name: ' || fun_name(1001));
END;
/

-- Unsuccessful example
BEGIN
    DBMS_OUTPUT.PUT_LINE('Formatted Name: ' || fun_name(9999)); -- Invalid ID
END;
/

-- Question 7: How can we count the vowels in a specific column (NAME or JOB) for all staff members?
CREATE OR REPLACE FUNCTION vowel_cnt (
    column_name IN VARCHAR2
)
RETURN NUMBER
AS
    total_vowels NUMBER := 0;
BEGIN
    -- Validate the input column
    IF UPPER(column_name) NOT IN ('NAME', 'JOB') THEN
        RAISE_APPLICATION_ERROR(-20007, 'Invalid input: Only NAME or JOB is allowed.');
    END IF;

    -- Dynamically count vowels based on the column
    FOR row_cursor IN (SELECT CASE WHEN UPPER(column_name) = 'NAME' THEN NAME
                                   WHEN UPPER(column_name) = 'JOB' THEN JOB
                              END AS column_data
                       FROM A1_STAFF)
    LOOP
        -- Count vowels in each row
        FOR i IN 1..LENGTH(row_cursor.column_data) LOOP
            IF SUBSTR(UPPER(row_cursor.column_data), i, 1) IN ('A', 'E', 'I', 'O', 'U') THEN
                total_vowels := total_vowels + 1;
            END IF;
        END LOOP;
    END LOOP;

    -- Return the total vowel count
    RETURN total_vowels;
END;
/

-- Successful example
SELECT vowel_cnt('NAME') AS Total_Vowels FROM DUAL;

-- Unsuccessful example
SELECT vowel_cnt('SALARY') FROM DUAL; -- Invalid input

-- Question 8: How can we encapsulate all the above procedures and functions into a package for easy management?
CREATE OR REPLACE PACKAGE staff_pck AS
    -- Procedure from Question 1
    PROCEDURE staff_add (
        staff_name   IN VARCHAR2,
        staff_job    IN VARCHAR2,
        staff_salary IN NUMBER,
        staff_comm   IN NUMBER
    );

    -- Procedure from Question 4
    PROCEDURE set_comm;

    -- Function from Question 3
    FUNCTION total_cmp (
        staff_id IN NUMBER
    ) RETURN NUMBER;

    -- Function from Question 6
    FUNCTION fun_name (
        staff_id IN NUMBER
    ) RETURN VARCHAR2;

    -- Function from Question 7
    FUNCTION vowel_cnt (
        column_name IN VARCHAR2
    ) RETURN NUMBER;
END staff_pck;
/

-- Package body implementation
CREATE OR REPLACE PACKAGE BODY staff_pck AS
    -- Procedure from Question 1
    PROCEDURE staff_add (
        staff_name   IN VARCHAR2,
        staff_job    IN VARCHAR2,
        staff_salary IN NUMBER,
        staff_comm   IN NUMBER
    )
    AS
        new_id NUMBER;
    BEGIN
        SELECT MAX(ID) + 10 INTO new_id FROM A1_STAFF;

        IF UPPER(staff_job) NOT IN ('SALES', 'CLERK', 'MGR', 'PREZ') THEN
            RAISE_APPLICATION_ERROR(-20001, 'Invalid JOB. Must be Sales, Clerk, Mgr, or Prez.');
        END IF;

        INSERT INTO A1_STAFF (ID, NAME, JOB, SALARY, COMM, DEPT, YEARS)
        VALUES (new_id, staff_name, INITCAP(staff_job), staff_salary, staff_comm, 90, 1);

        DBMS_OUTPUT.PUT_LINE('Record successfully added with ID: ' || new_id);
    END staff_add;

    -- Procedure from Question 4
    PROCEDURE set_comm
    AS
        rows_updated NUMBER := 0;
    BEGIN
        UPDATE A1_STAFF SET COMM = SALARY * 0.2 WHERE UPPER(JOB) = 'MGR';
        rows_updated := rows_updated + SQL%ROWCOUNT;

        UPDATE A1_STAFF SET COMM = SALARY * 0.1 WHERE UPPER(JOB) = 'CLERK';
        rows_updated := rows_updated + SQL%ROWCOUNT;

        UPDATE A1_STAFF SET COMM = SALARY * 0.3 WHERE UPPER(JOB) = 'SALES';
        rows_updated := rows_updated + SQL%ROWCOUNT;

        UPDATE A1_STAFF SET COMM = SALARY * 0.5 WHERE UPPER(JOB) = 'PREZ';
        rows_updated := rows_updated + SQL%ROWCOUNT;

        DBMS_OUTPUT.PUT_LINE(rows_updated || ' records were changed');
    END set_comm;

    -- Function from Question 3
    FUNCTION total_cmp (
        staff_id IN NUMBER
    ) RETURN NUMBER
    AS
        total_comp NUMBER;
    BEGIN
        SELECT SALARY + COMM INTO total_comp FROM A1_STAFF WHERE ID = staff_id;

        RETURN total_comp;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Invalid ID: No staff member found with the provided ID.');
    END total_cmp;

    -- Function from Question 6
    FUNCTION fun_name (
        staff_id IN NUMBER
    ) RETURN VARCHAR2
    AS
        original_name VARCHAR2(100);
        formatted_name VARCHAR2(100) := '';
    BEGIN
        SELECT NAME INTO original_name FROM A1_STAFF WHERE ID = staff_id;

        FOR i IN 1..LENGTH(original_name) LOOP
            IF MOD(i, 2) = 1 THEN
                formatted_name := formatted_name || UPPER(SUBSTR(original_name, i, 1));
            ELSE
                formatted_name := formatted_name || LOWER(SUBSTR(original_name, i, 1));
            END IF;
        END LOOP;

        RETURN formatted_name;
    END fun_name;

    -- Function from Question 7
    FUNCTION vowel_cnt (
        column_name IN VARCHAR2
    ) RETURN NUMBER
    AS
        total_vowels NUMBER := 0;
    BEGIN
        IF UPPER(column_name) NOT IN ('NAME', 'JOB') THEN
            RAISE_APPLICATION_ERROR(-20007, 'Invalid input: Only NAME or JOB is allowed.');
        END IF;

        FOR row_cursor IN (SELECT CASE WHEN UPPER(column_name) = 'NAME' THEN NAME
                                       WHEN UPPER(column_name) = 'JOB' THEN JOB
                                  END AS column_data
                           FROM A1_STAFF)
        LOOP
            FOR i IN 1..LENGTH(row_cursor.column_data) LOOP
                IF SUBSTR(UPPER(row_cursor.column_data), i, 1) IN ('A', 'E', 'I', 'O', 'U') THEN
                    total_vowels := total_vowels + 1;
                END IF;
            END LOOP;
        END LOOP;

        RETURN total_vowels;
    END vowel_cnt;

END staff_pck;
/

-- Calling package procedure and functions for demonstration
BEGIN
    staff_pck.staff_add('Jon Snow', 'Sales', 50000, 0);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Total Compensation: ' || staff_pck.total_cmp(1011));
END;
/
