# Database Schema Description

This document provides an overview of the database schema and its structure. The schema file (`ot_schema.sql`) sets up the necessary tables, constraints, and relationships for the projects.

## 📂 Schema Overview

The schema defines the following main components:

### Tables
1. **`orders`**  
   - **Description**: Stores information about customer orders.
   - **Key Columns**:  
     - `order_id` (Primary Key): Unique identifier for each order.  
     - `customer_id`: References the customer who placed the order.  
     - `order_date`: Date when the order was placed.  

2. **`customers`**  
   - **Description**: Contains customer data.  
   - **Key Columns**:  
     - `customer_id` (Primary Key): Unique identifier for each customer.  
     - `customer_name`: Name of the customer.  
     - `contact_info`: Contact details of the customer.

3. **`products`**  
   - **Description**: Stores details about available products.  
   - **Key Columns**:  
     - `product_id` (Primary Key): Unique identifier for each product.  
     - `product_name`: Name of the product.  
     - `list_price`: Price of the product.  

4. **`order_items`**  
   - **Description**: Tracks items within an order.  
   - **Key Columns**:  
     - `item_id` (Primary Key): Unique identifier for each item.  
     - `order_id`: References the associated order.  
     - `product_id`: References the product being ordered.  
     - `quantity`: Quantity of the product ordered.

5. **`employees`**  
   - **Description**: Contains employee data, including job roles and compensation.  
   - **Key Columns**:  
     - `employee_id` (Primary Key): Unique identifier for each employee.  
     - `job_title`: The role of the employee.  
     - `salary`: Base salary of the employee.

### Relationships
- **Customers and Orders**: `customers.customer_id` → `orders.customer_id`  
- **Orders and Order Items**: `orders.order_id` → `order_items.order_id`  
- **Products in Order Items**: `products.product_id` → `order_items.product_id`  

## 🔧 How to Set Up the Schema
1. Open the `ot_schema.sql` file in your SQL environment (e.g., SQL Developer or MySQL Workbench).
2. Execute the script to create the tables and relationships.
3. Verify the schema creation by checking the database structure.

## ✨ Key Features
- Primary and Foreign Key Constraints.
- Normalized table design to reduce redundancy.
- Well-defined relationships for integrity and analytical purposes.

For further details, refer to the schema file or contact me with questions.
