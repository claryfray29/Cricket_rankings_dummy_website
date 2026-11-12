"""Thin PyMySQL helpers. Every query is a raw SQL string with %s parameters."""
from contextlib import contextmanager

from config import get_db_connection


def fetch_all(sql, params=()):
    """Run a SELECT and return all rows as a list of dicts."""
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.fetchall()
    finally:
        conn.close()


def fetch_one(sql, params=()):
    """Run a SELECT and return the first row (or None)."""
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.fetchone()
    finally:
        conn.close()


@contextmanager
def transaction():
    """Yield a cursor; commit on success, roll back on any error.

    Usage:
        with transaction() as cur:
            cur.execute("INSERT ...", (...))
            cur.execute("INSERT ...", (...))
    """
    conn = get_db_connection()          # autocommit=False (see config.py)
    try:
        with conn.cursor() as cur:
            yield cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()