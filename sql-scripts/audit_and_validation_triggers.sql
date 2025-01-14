-- Question 1: How can we calculate the median salary of employees in the database?
CREATE OR REPLACE FUNCTION my_median RETURN NUMBER IS
    v_median NUMBER;
    v_count  NUMBER;
BEGIN
    -- Count the number of non-null salaries
    SELECT COUNT(SALARY)
    INTO v_count
    FROM a1_employee
    WHERE SALARY IS NOT NULL;

    IF v_count = 0 THEN
        RETURN NULL;  -- Handle empty list case
    END IF;

    IF MOD(v_count, 2) = 0 THEN
        -- Even number of elements: average of the middle two elements
        SELECT AVG(m.SALARY)
        INTO v_median
        FROM (
            SELECT SALARY
            FROM a1_employee
            WHERE SALARY IS NOT NULL
            ORDER BY SALARY
        ) m
        WHERE ROWNUM BETWEEN (v_count / 2) AND ((v_count / 2) + 1);
    ELSE
        -- Odd number of elements: middle element
        SELECT m.SALARY
        INTO v_median
        FROM (
            SELECT SALARY, ROWNUM AS rn
            FROM (
                SELECT SALARY
                FROM a1_employee
                WHERE SALARY IS NOT NULL
                ORDER BY SALARY
            )
        ) m
        WHERE m.rn = (v_count + 1) / 2;
    END IF;

    RETURN v_median;
END;
/
SELECT my_median FROM DUAL;


-- Question 2: How can we calculate and display the mean, median, and mode of employee salaries?
CREATE OR REPLACE PROCEDURE my_math_all AS
  v_median NUMBER;
  v_mode NUMBER;
  v_mean NUMBER;
  v_count NUMBER;
BEGIN
  -- Calculate mean
  SELECT AVG(SALARY) INTO v_mean FROM a1_employee;

  -- Calculate mode
  SELECT SALARY INTO v_mode 
  FROM (
    SELECT SALARY, COUNT(*) AS freq
    FROM a1_employee
    GROUP BY SALARY
    ORDER BY freq DESC, SALARY
  )
  WHERE ROWNUM = 1;

  -- Calculate median
  SELECT COUNT(*) INTO v_count FROM a1_employee;

  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Empty list');
  ELSE
    SELECT AVG(SAL)
    INTO v_median
    FROM (
      SELECT SALARY AS sal
      FROM a1_employee
      ORDER BY SALARY
    )
    WHERE ROWNUM IN (FLOOR((v_count + 1) / 2), CEIL((v_count + 1) / 2));
    
    -- Print the results
    DBMS_OUTPUT.PUT_LINE('Median: ' || v_median);
    DBMS_OUTPUT.PUT_LINE('Mode: ' || v_mode);
    DBMS_OUTPUT.PUT_LINE('Mean: ' || v_mean);
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Empty list');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/


-- Test the procedure
BEGIN
  my_math_all;
END;
/


-- Question 3: How can we find the mode(s) of employee salaries and return them as a comma-separated list?
CREATE OR REPLACE FUNCTION my_mode 
RETURN VARCHAR2 IS
  mode_result VARCHAR2(4000);
BEGIN
  -- Query to find the mode(s)
  SELECT LISTAGG(SALARY, ', ') WITHIN GROUP (ORDER BY SALARY)
  INTO mode_result
  FROM (
    SELECT SALARY, COUNT(*) AS freq
    FROM a1_employee
    GROUP BY SALARY
    HAVING COUNT(*) = (
      SELECT MAX(COUNT(*))
      FROM a1_employee
      GROUP BY SALARY
    )
  )
  WHERE freq > 1;

  -- Check if mode_result is empty, indicating no mode exists
  IF mode_result IS NULL THEN
    RETURN 'No mode';
  END IF;

  RETURN mode_result;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'Empty list';
  WHEN OTHERS THEN
    RETURN 'An error occurred: ' || SQLERRM;
END;
/

SELECT my_mode() AS mode_result FROM DUAL;
