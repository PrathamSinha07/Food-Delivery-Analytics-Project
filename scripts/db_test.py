import psycopg2

try:
    conn = psycopg2.connect(
        host="localhost",
        database="postgres",
        user="postgres",
        password="postgres"
    )

    print("Connected successfully ✅")

    conn.close()

except Exception as e:
    print("Error:", e)