
# Data Pipelining from PostgreSQL to Snowflake using Hevo

The project demonstrates a complete data engineering workflow, from setting up a PostgreSQL database in Docker, replicating data to Snowflake using Hevo Data's Logical Replication Ingestion mode, and transforming the data with dbt to create a final **customers** model. 

## Objectives

The objective is to: 

1. Install and configure a **PostgreSQL DB Instance** using **Docker**.
2. In the PostgreSQL DB, create three **tables** and load the respective CSV File into each table.
   * **raw_orders**
   * **raw_cusotmers**
   * **raw_payments**
3.  Set up **Snowflake** as the destination.
4.  Configure a **Hevo Data Pipeline** with PostgreSQL as the source and Snowflake warehouse as the destination using **Logical Replication Ingestion mode** to sync data in real time.
5.  Use **dbt (Data Build Tool)** to transform data and create a materialized table **customers**.
6.  Add **dbt tests** and push the project to GitHub.  

---

## Instructions

### Step 1: Setting up PostgreSQL using Docker

1. Go to Docker Hub and search for the official PostgreSQL image.
2. Pull the image using the command:
    ```bash
    docker pull postgres:latest
    ```
3. Run a new container with PostgreSQL using:
   ```bash
   docker run -d --name <POSTGRESQL_CONTAINER_NAME> -e POSTGRES_PASSWORD=<POSTGRESQL_PASSWORD> postgres:latest
   ```
4. Go to the PostgreSQL cofiguration directory and edit the file `postgresql.conf` and set the parameter `wal_level` to `logical`. Configure other replication settings as well:
    ```bash
    cd /var/lib/postgresql/18/docker
    nano postgresql.conf
    wal_level = logical
    max_replication_slots = 10
    max_wal_senders = 10
    wal_sender_timeout = 0
    ```
5. Restart the PostgreSQL container to apply changes:
    ```bash
    sudo docker restart <POSTGRESQL_CONTAINER_NAME>
    ```

---

### Step 2: Connecting to the PostgreSQL DB Instance, Creating Tables and Loading the Data from CSV Files

1. Install PostgreSQL client tools via homebrew to connect locally:
   ```bash
   brew install postgresql
   brew services start postgresql
   psql --version
   ```

2. Connect to the PostgreSQL database locally:
    ```sql
    psql --host=localhost --port=<POSTGRESQL_PORT_NUMBER> --username=<POSTGRESQL_USER_NAME>
    ```
3. Grant necessary permissions and replication access:
    ```sql
    CREATE SCHEMA <POSTGRESQL_SCHEMA_NAME>;
    GRANT CONNECT ON DATABASE <POSTGRESQL_DB> TO <POSTGRESQL_USER_NAME>;
    GRANT USAGE ON SCHEMA <POSTGRESQL_SCHEMA_Name> TO <POSTGRESQL_USER_NAME>;
    GRANT SELECT ON ALL TABLES IN SCHEMA <POSTGRESQL_SCHEMA_NAME> TO <POSTGRESQL_USER_NAME>;
    ALTER USER <POSTGRESQL_USER_NAME> WITH REPLICATION;
    ALTER DEFAULT PRIVILEGES IN SCHEMA <POSTGRESQL_SCHEMA_NAME> GRANT SELECT ON TABLES TO <POSTGRESQL_USER_NAME>;
    ```
4. Create three Tables for raw data ingestion:
   ```sql
    CREATE TABLE <POSTGRESQL_SCHEMA_NAME>.raw_customers (
    id SERIAL PRIMARY KEY,
    first_name TEXT,
    last_name TEXT
    );

    CREATE TABLE <POSTGRESQL_SCHEMA_NAME>.raw_orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES <POSTGRESQL_SCHEMA_NAME>.raw_customers(id),
    order_date DATE,
    status TEXT
    );

    CREATE TABLE <POSTGRESQL_SCHEMA_NAME>.raw_payments (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES <POSTGRESQL_SCHEMA_NAME>.raw_orders(id),
    payment_method TEXT,
    amount INTEGER
    );
    ```
6. Load Data into PostgreSQL:
   
   Use `\COPY`to Load data from local directory into the tables and verify the data:
   
    ```sql
    \COPY <POSTGRES_CONTAINER_NAME>.raw_customers (id, first_name, last_name)
    FROM '<PATH_TO_raw_customers.csv>'
    DELIMITER ','
    CSV HEADER;

    \COPY <POSTGRES_CONTAINER_NAME>.raw_orders (id, user_id, order_date, status)
    FROM '<PATH_TO_raw_orders.csv>'
    DELIMITER ','
    CSV HEADER;

    \COPY <POSTGRES_CONTAINER_NAME>.raw_payments (id, order_id, payment_method, amount)
    FROM '<PATH_TO_raw_payments.csv>'
    DELIMITER ','
    CSV HEADER;

    SELECT Count(*) from <POSTGRES_CONTAINER_NAME>.raw_customers;
    SELECT Count(*) from <POSTGRES_CONTAINER_NAME>.raw_orders;
    SELECT Count(*) from <POSTGRES_CONTAINER_NAME>.raw_payments;
    ```

---

### Step 3: Loading Data from PostgreSQL to Snowflake using Hevo

1. Setting Up Hevo Pipeline:

    1. Log in in to your Snowflake account. 
    2. Log in to your Hevo Data account from Snowflake Partner Connect.
    3. Create a new pipeline and choose PostgreSQL as the source.
    4. Enter the required connection details to link the PostgreSQL Database:
       
       ```bash
       Host: `<NGROK_IP>` {I have exposed my local database to a remote server using Ngrok Tunnel}
       Port: `<NGROK_PORT>`
       Database: `<POSTGRESQL_DB>`
       Username: `<POSTGRESQL_USER_NAME>`
       Password: `<POSTGRESQL_PASSWORD>`
       ```

2. Configuring Snowflake as the Destination:

    1. In the destination setup, select Snowflake as the destination.
    2. Provide the required configuration details for your Snowflake acount:

       ```bash
       Snowflake URL: `<SNOWFLAKE_URL>`
       Database: `<SNOWFLAKE_DATABASE>`
       Warehouse: `<SNOWFLAKE_WAREHOUSE>`
       Schema: `<SNOWFLAKE_SCHEMA>`
       Username: `<SNOWFLAKE_USER_NAME>`
       Password: `<SNOWFLAKE_PASSWORD>`
       ```
     
   3. Choose the Ingestion mode as Logical Replication.
   4. Set the data load frequency as per your requirement. 

3. Data Loading and Verification:

   1. Map the three PostgreSQL tables - `raw_customers`, `raw_orders`, and `raw_payments` to your Target Snowflake tables (you can either manually map each table or use Hevo's Auto-Mapping feature).
   2. Launch the Pipeline and Inspect the load status on the Hevo dashboard.
   3. Once data transfer completes, log in to Snowflake and verify data by running:

      ```sql
      SELECT COUNT(*) FROM <YOUR_SNOWFLAKE_DATABASE>.<YOUR_SNOWFLAKE_SCHEMA>.raw_customers;
      SELECT COUNT(*) FROM <YOUR_SNOWFLAKE_DATABASE>.<YOUR_SNOWFLAKE_SCHEMA>.raw_orders;
      SELECT COUNT(*) FROM <YOUR_SNOWFLAKE_DATABASE>.<YOUR_SNOWFLAKE_SCHEMA>.raw_payments;
      ```
      
   4. Confirm that record counts in Snowflake match your PostgreSQL source tables. 

### Step 4: Setting Up dbt Project

1. Login to [DBT](https://www.getdbt.com/), choose Hevo Data --> Account Settings --> Connections --> New Connection, then add Snowflake details:

   ```bash
   Type: Snowflake
   Connection name: `<NAME_OF_CONNECTION>`
   Account: `<SNOWFLAKE_ACCOUNT>`
   Database: `<SNOWFLAKE_DATABASE>`
   Warehouse: `<SNOWFLAKE_WAREHOUSE>`
   ```
   
2. Save the connection.
3. Create a GitHub Repository 'HevoData' and link to the DBT Project.
4. Once linked, go to Studio and under the File Explorer, select the HevoData folder.
5. In the `models` folder, create the metadata configuration file `schema.yml` that declares the data sources (where to find the raw data),
   documents the models (what the model means) and defines the tests (what the user wants to test).
   ```yaml
   version: 2

   sources:
     - name: PUBLIC
       database: PC_HEVODATA_DB
       schema: PUBLIC
       tables:
         - name: raw_customers
         - name: raw_orders
         - name: raw_payments
   
   models:
     - name: lifetime_value
       description: "A model combining customer order history with their lifetime value."
       columns:
         - name: customer_id
           description: "Unique identifier for the customer"
         - name: first_name
           description: "Customer's first name"
         - name: last_name
           description: "Customer's last name"
      - name: first_order
        description: "Date of the customer's first order"
      - name: most_recent_order
        description: "Date of the customer's most recent order"
      - name: number_of_orders
        description: "Total number of orders by the customer"
      - name: customer_lifetime_value
        description: "Total value of payments made by the customer"
   ```
6. Additionally, create the DBT model file `lifetime_value.sql` that combines and aggregates raw data from the three tables.
   
   ```yaml
   WITH customer_orders AS (
     SELECT
        cx.id AS customer_id,
        cx.first_name,
        cx.last_name,
        MIN(ord.order_date) AS first_order,
        MAX(ord.order_date) AS most_recent_order,
        COUNT(ord.id) AS number_of_orders
     FROM {{ source('PUBLIC', 'raw_customers') }} cx
     LEFT JOIN {{ source('PUBLIC', 'raw_orders') }} ord
     ON cx.id = ord.user_id
     GROUP BY cx.id, cx.first_name, cx.last_name
   ),
   customer_lifetime_value AS (
     SELECT
        ord.user_id AS customer_id,
        SUM(pyt.amount) AS customer_lifetime_value
     FROM {{ source('PUBLIC', 'raw_orders') }} ord
     LEFT JOIN {{ source('PUBLIC', 'raw_payments') }} pyt
     ON ord.id = pyt.order_id
     GROUP BY ord.user_id
   )
   SELECT
    cxord.customer_id,
    cxord.first_name,
    cxord.last_name,
    cxord.first_order,
    cxord.most_recent_order,
    cxord.number_of_orders,
    cxlv.customer_lifetime_value
   FROM customer_orders cxord
   LEFT JOIN customer_lifetime_value cxlv
   ON cxord.customer_id = cxlv.customer_id
   ```
8. Click on Compile and Preview to run the query and get the desired output.
9. Push all the files and the changes in the GitHub repository, in the correct branch.
10. The resultant customers CSV file is attached [here](https://drive.google.com/file/d/163Q9RbqQuhZl2pBpNXCAT5wyNKqLs2Jx/view?usp=drive_link).


