import csv
import os
from pathlib import Path

import psycopg2


DATA_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"


def connect():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "movieflix"),
        user=os.getenv("DB_USER", "movieflix"),
        password=os.getenv("DB_PASSWORD", "movieflix"),
    )


def load_table(cursor, table, filename, columns):
    cursor.execute(f"TRUNCATE TABLE {table} CASCADE")
    with (DATA_DIR / filename).open(newline="", encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)
        rows = [[row[column] for column in columns] for row in reader]
    placeholders = ", ".join(["%s"] * len(columns))
    cursor.executemany(
        f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({placeholders})",
        rows,
    )
    print(f"{table}: {len(rows)} registros carregados")


def main():
    with connect() as connection:
        with connection.cursor() as cursor:
            load_table(cursor, "movies", "movies.csv",
                       ["movie_id", "title", "genre", "release_year"])
            load_table(cursor, "users", "users.csv",
                       ["user_id", "name", "age", "country"])
            load_table(cursor, "ratings", "ratings.csv",
                       ["rating_id", "user_id", "movie_id", "rating", "rated_at"])
    print("Carga concluida.")


if __name__ == "__main__":
    main()
