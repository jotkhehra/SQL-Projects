--question 1: How can we add a new order for a customer while generating a unique order ID?
CREATE OR REPLACE PROCEDURE add_order (
    customer_id IN NUMBER,
    new_order_id OUT NUMBER
) AS
    max_order_id NUMBER;
BEGIN
    -- Generate the new order ID by finding the maximum order ID and incrementing by 1
    SELECT MAX(order_id) + 1 INTO new_order_id
    FROM orders;
    
    -- Insert a new order for the provided customer ID
    INSERT INTO orders (order_id, customer_id, status, salesman_id, order_date)
    VALUES (new_order_id, customer_id, 'Shipped', 56, SYSDATE);
    
    -- Commit the transaction to save the new order
    COMMIT;

    -- Display the new order details
    DBMS_OUTPUT.PUT_LINE('Order successfully created with the following details:');
    DBMS_OUTPUT.PUT_LINE('Order ID: ' || new_order_id);
    DBMS_OUTPUT.PUT_LINE('Customer ID: ' || customer_id);
    DBMS_OUTPUT.PUT_LINE('Status: Shipped');
    DBMS_OUTPUT.PUT_LINE('Salesman ID: 56');
    DBMS_OUTPUT.PUT_LINE('Order Date: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD'));

EXCEPTION
    -- Handle cases where the customer is not found
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid customer ID. Customer not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error');
END add_order;
/

-- Run the procedure
DECLARE
    new_order_id NUMBER;
BEGIN
    add_order(45, new_order_id); 
    -- Display the generated new order ID
    DBMS_OUTPUT.PUT_LINE('Generated Order ID: ' || new_order_id);
END;
/


--question 2: How can we verify if a customer exists in the database?
CREATE OR REPLACE PROCEDURE find_customer (
    customer_id IN NUMBER,
    found OUT NUMBER
) AS
BEGIN
    -- Attempt to find the customer by customer_id
    SELECT 1 INTO found
    FROM customers
    WHERE customer_id = find_customer.customer_id;
    
    -- If customer is found, set found to 1
    found := 1;
    
    -- Output message indicating customer was found
    DBMS_OUTPUT.PUT_LINE('Customer ID ' || customer_id || ' was found.');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- If no customer is found, set found to 0
        found := 0;
        
        -- Output message indicating customer was not found
        DBMS_OUTPUT.PUT_LINE('Customer ID ' || customer_id || ' was not found.');
END find_customer;
/

-- Run the procedure
DECLARE
    foundValue NUMBER;
BEGIN
    find_customer(-1, foundValue); 
    DBMS_OUTPUT.PUT_LINE('Found value: ' || foundValue); -- Displays the value of found
END;
/


--question 3: How can we retrieve the price of a product by its product ID?
CREATE OR REPLACE PROCEDURE find_product (
    productId IN NUMBER,
    price OUT products.list_price%TYPE
) AS
BEGIN
    -- Attempt to find the product's list price by product ID
    SELECT list_price INTO price
    FROM products
    WHERE product_id = find_product.productId;
    
    -- Output message indicating the product price
    DBMS_OUTPUT.PUT_LINE('Product ID ' || productId || ' has a price of: ' || price);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Set price to 0 if the product is not found
        price := 0;
        
        -- Output message indicating product was not found
        DBMS_OUTPUT.PUT_LINE('Product ID ' || productId || ' was not found. Price is set to 0.');
    WHEN OTHERS THEN
        -- Handle other errors
        DBMS_OUTPUT.PUT_LINE('Error');
END find_product;
/
--run

DECLARE
    price NUMBER;
BEGIN
    find_product(101, price);  
    DBMS_OUTPUT.PUT_LINE('Returned Price: ' || price); 
END;
/

--for not found
DECLARE
    price NUMBER;
BEGIN
    find_product(-1, price);  
    DBMS_OUTPUT.PUT_LINE('Returned Price: ' || price);
    -- Displays the price returned
END;
/


--question 4: How can we display all details of a specific order, including customer and item details?
CREATE OR REPLACE PROCEDURE display_order (
    orderId IN NUMBER
) AS
    customerId NUMBER;
    totalPrice NUMBER := 0;
BEGIN
    -- Retrieve the customer ID associated with the order
    SELECT customer_id INTO customerId
    FROM orders
    WHERE order_id = display_order.orderId;
    
    -- Display Order and Customer Information
    DBMS_OUTPUT.PUT_LINE('Order ID: ' || orderId);
    DBMS_OUTPUT.PUT_LINE('Customer ID: ' || customerId);
    
    -- Display the header for order items
    DBMS_OUTPUT.PUT_LINE('Item ID | Product ID | Quantity | Unit Price');
    
    -- Retrieve and display each item in the order
    FOR item IN (
        SELECT item_id, product_id, quantity, unit_price
        FROM order_items
        WHERE order_id = display_order.orderId
    ) LOOP
        -- Calculate total price for each item and add to overall total price
        totalPrice := totalPrice + (item.quantity * item.unit_price);
        
        -- Display each order item
        DBMS_OUTPUT.PUT_LINE(
            item.item_id || ' | ' ||
            item.product_id || ' | ' ||
            item.quantity || ' | ' ||
            TO_CHAR(item.unit_price, 'FM9990.00')
        );
    END LOOP;

    -- Display the total price for the order
    DBMS_OUTPUT.PUT_LINE('Total Order Price: ' || TO_CHAR(totalPrice, 'FM9990.00'));
    
EXCEPTION
    -- Handle case when the order ID does not exist
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Order ID ' || orderId || ' does not exist.');
    WHEN OTHERS THEN
        -- Handle other errors if necessary
        DBMS_OUTPUT.PUT_LINE('Error');
END display_order;
/

BEGIN
    display_order(-1); 
END;
/


--question 5: How can we update the education level of an employee based on a given code, ensuring no reduction in level?
CREATE OR REPLACE PROCEDURE update_education_level (
    empNo IN NUMBER,
    eduCode IN CHAR
) AS
    currentLevel NUMBER;
    newLevel NUMBER;
BEGIN
    -- Check if the employee exists and retrieve their current education level
    SELECT edlevel INTO currentLevel
    FROM a1_employee
    WHERE empno = empNo
    AND ROWNUM = 1;  -- Ensure only one row is fetched, if not then i get the error that more than one row fetching
    
    -- Determine the new education level based on the input code
    CASE eduCode
        WHEN 'H' THEN newLevel := 16;
        WHEN 'C' THEN newLevel := 19;
        WHEN 'U' THEN newLevel := 20;
        WHEN 'M' THEN newLevel := 23;
        WHEN 'P' THEN newLevel := 25;
        ELSE
            -- Handle invalid education level input
            DBMS_OUTPUT.PUT_LINE('Error: Invalid education level code.');
            RETURN;
    END CASE;
    
    -- Check if the new education level is not less than the current level
    IF newLevel < currentLevel THEN
        DBMS_OUTPUT.PUT_LINE('Error: Education level cannot be reduced.');
    ELSE
        -- Update the education level in the table
        UPDATE a1_employee
        SET edlevel = newLevel
        WHERE empno = empNo;

        -- Commit the transaction
        COMMIT;

        -- Output the details of the update
        DBMS_OUTPUT.PUT_LINE('Employee Number: ' || empNo);
        DBMS_OUTPUT.PUT_LINE('Original Education Level: ' || currentLevel);
        DBMS_OUTPUT.PUT_LINE('Updated Education Level: ' || newLevel);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Handle the case when the employee number does not exist
        DBMS_OUTPUT.PUT_LINE('Error: Employee number ' || empNo || ' does not exist.');
END update_education_level;
/

BEGIN
    update_education_level(000010, 'M');  
END;
/


--question 6: How can we update the salary, bonus, and commission of an employee based on their performance rating?
CREATE OR REPLACE PROCEDURE salary (
    empNo IN NUMBER,
    rating IN NUMBER
) AS
    -- Variables to hold original compensation values
    originalSalary NUMBER;
    originalBonus NUMBER;
    originalComm NUMBER;
    -- Variables to hold updated compensation values
    newSalary NUMBER;
    newBonus NUMBER;
    newCommRate NUMBER;
    newComm NUMBER;
BEGIN
    -- Retrieve current salary, bonus, and commission for the employee, limiting to one row
    SELECT salary, bonus, comm INTO originalSalary, originalBonus, originalComm
    FROM a1_employee
    WHERE empno = empNo
    AND ROWNUM = 1;  -- Fetch only one row

    -- Initialize new values with current ones
    newSalary := originalSalary;
    newBonus := originalBonus;
    newComm := originalComm;
    newCommRate := originalComm / originalSalary;

    -- Update compensation based on rating
    CASE rating
        WHEN 1 THEN
            newSalary := originalSalary + 10000;
            newBonus := originalBonus + 300;
            newCommRate := newCommRate * 1.05;
        WHEN 2 THEN
            newSalary := originalSalary + 5000;
            newBonus := originalBonus + 200;
            newCommRate := newCommRate * 1.02;
        WHEN 3 THEN
            newSalary := originalSalary + 2000;
            -- No change to bonus or commission for rating 3
        ELSE
            -- Handle invalid rating
            DBMS_OUTPUT.PUT_LINE('Error: Invalid rating. Please enter a rating of 1, 2, or 3.');
            RETURN;
    END CASE;

    -- Calculate the new commission based on updated rate
    newComm := newCommRate * newSalary;

    -- Update the employee's compensation in the table
    UPDATE a1_employee
    SET salary = newSalary,
        bonus = newBonus,
        comm = newComm
    WHERE empno = empNo;

    -- Commit the transaction
    COMMIT;

    -- Output original and new compensation details
    DBMS_OUTPUT.PUT_LINE('Employee Number: ' || empNo);
    DBMS_OUTPUT.PUT_LINE('Original Salary: ' || originalSalary);
    DBMS_OUTPUT.PUT_LINE('Original Bonus: ' || originalBonus);
    DBMS_OUTPUT.PUT_LINE('Original Commission: ' || originalComm);
    DBMS_OUTPUT.PUT_LINE('NEW Salary: ' || newSalary);
    DBMS_OUTPUT.PUT_LINE('NEW Bonus: ' || newBonus);
    DBMS_OUTPUT.PUT_LINE('NEW Commission: ' || newComm);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Handle case when the employee number does not exist
        DBMS_OUTPUT.PUT_LINE('Error: Employee number ' || empNo || ' does not exist.');
END salary;
/

BEGIN
    salary(-1, -1);
END;
