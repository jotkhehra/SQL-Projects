-- Question: How can we enforce rules on employee compensation while auditing all changes made to the employee table?
CREATE OR REPLACE TRIGGER varpaychk
BEFORE INSERT OR UPDATE ON A1_EMPLOYEE
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    exception_message VARCHAR2(50);
    transaction_type VARCHAR2(10);
    current_values VARCHAR2(400);
    supplied_values VARCHAR2(400);
BEGIN
    -- Determining transaction type if it's INSERT or UPDATE
    IF INSERTING THEN
        transaction_type := 'INSERT';
    ELSE
        transaction_type := 'UPDATE';
    END IF;

    -- Preparing the CURRENT_VALUES and SUPPLIED_VALUES
    IF UPDATING THEN
        current_values := 'EmpNO: ' || NVL(TO_CHAR(:OLD.EMPNO), 'NULL') ||
                          ', Salary: ' || NVL(TO_CHAR(:OLD.SALARY), 'NULL') ||
                          ', Bonus: ' || NVL(TO_CHAR(:OLD.BONUS), 'NULL') ||
                          ', Comm: ' || NVL(TO_CHAR(:OLD.COMM), 'NULL');
    ELSE
        current_values := 'NULL';
    END IF;

    supplied_values := 'EmpNO: ' || NVL(TO_CHAR(:NEW.EMPNO), 'NULL') ||
                       ', Salary: ' || NVL(TO_CHAR(:NEW.SALARY), 'NULL') ||
                       ', Bonus: ' || NVL(TO_CHAR(:NEW.BONUS), 'NULL') ||
                       ', Comm: ' || NVL(TO_CHAR(:NEW.COMM), 'NULL');

    -- Checking the compensation rules
    IF :NEW.BONUS < (0.2 * :NEW.SALARY) AND
       :NEW.COMM < (0.25 * :NEW.SALARY) AND
       (:NEW.BONUS + :NEW.COMM) < (0.4 * :NEW.SALARY) THEN
        -- If it's valid then set the exception message for success
        exception_message := 'Valid data supplied';
    ELSE
        -- If it's invalid then set the exception message for failure
        exception_message := 'Data did not meet requirements';
        -- Preventing the invalid data from being inserted or updated
        RAISE_APPLICATION_ERROR(-20001, exception_message);
    END IF;

    -- Inserting audit log
    INSERT INTO APPAUDIT (
        TABLE_NAME,
        TRANSACTION_NAME,
        A_CURRENT_USER,
        A_SESSION_USER,
        TRANSACTION_DATE_TIME,
        CLIENT_IP_ADDRESS,
        CLIENT_HOST_NAME,
        EXCEPTION_MSG,
        CURRENT_VALUES,
        SUPPLIED_VALUES
    ) VALUES (
        'A1_EMPLOYEE',
        transaction_type,
        SYS_CONTEXT('USERENV', 'CURRENT_USER'),
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        SYSTIMESTAMP,
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        SYS_CONTEXT('USERENV', 'HOST'),
        exception_message,
        current_values,
        supplied_values
    );

    -- Committing the audit log (autonomous transaction)
    COMMIT;
END varpaychk;


-- Query to check the audit log
SELECT * FROM APPAUDIT WHERE TABLE_NAME = 'A1_EMPLOYEE';
