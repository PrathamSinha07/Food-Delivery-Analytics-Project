import pandas as pd
import psycopg2

# Connect to DB
conn = psycopg2.connect(
    host="localhost",
    database="food_delivery_db",
    user="postgres",
    password="postgres" 
)

cur = conn.cursor()

# Load data
customers = pd.read_csv("data/customers_clean.csv")
orders = pd.read_csv("data/orders_clean.csv")
restaurants = pd.read_csv("data/restaurants.csv")
menu = pd.read_csv("data/menu_items.csv")
order_items = pd.read_csv("data/order_items.csv")

# Insert customers
for _, row in customers.iterrows():
    cur.execute(
        "INSERT INTO customers VALUES (%s, %s, %s)",
        (row['customer_id'], row['city'], row['signup_date'])
    )

# Insert restaurants
for _, row in restaurants.iterrows():
    cur.execute(
        "INSERT INTO restaurants VALUES (%s, %s, %s, %s)",
       (row['restaurant_id'], row['cuisine'], row['city'], row['rating'])
    )

# Insert orders
for _, row in orders.iterrows():
    cur.execute(
        "INSERT INTO orders VALUES (%s, %s, %s, %s, %s, %s, %s)",
        (row['order_id'], row['customer_id'], row['restaurant_id'],
         row['order_time'], row['delivery_time'],
         row['status'], row['delivery_duration'])
    )

# Insert menu
for _, row in menu.iterrows():
    cur.execute(
        "INSERT INTO menu_items VALUES (%s, %s, %s)",
        (row['item_id'], row['restaurant_id'], row['price'])
    )

# Insert order_items
for _, row in order_items.iterrows():
    cur.execute(
        "INSERT INTO order_items VALUES (%s, %s, %s)",
        (row['order_id'], row['item_id'], row['quantity'])
    )

# Commit
conn.commit()

print("Data inserted successfully ✅")

cur.close()
conn.close()