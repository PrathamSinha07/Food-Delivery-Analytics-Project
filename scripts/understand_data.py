import pandas as pd

customers = pd.read_csv("data/customers_medium.csv")
orders = pd.read_csv("data/orders_medium.csv")

# Clean customers
customers = customers.drop_duplicates()

# Convert time
orders['order_time'] = pd.to_datetime(orders['order_time'])
orders['delivery_time'] = pd.to_datetime(orders['delivery_time'])

# Create delivery duration
orders['delivery_duration'] = (orders['delivery_time'] - orders['order_time']).dt.total_seconds() / 60

# Save cleaned files
customers.to_csv("data/customers_clean.csv", index=False)
orders.to_csv("data/orders_clean.csv", index=False)

print("Cleaned files saved ✅")