import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Keeps imports stable when running tests from the repository root.
sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.db import Base, get_db
from app.main import app

SQLALCHEMY_DATABASE_URL = "sqlite+pysqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)


def test_crud_flow():
    create_response = client.post("/api/products", json={"name": "Mouse"})
    assert create_response.status_code == 201
    created = create_response.json()
    assert created["name"] == "Mouse"
    product_id = created["id"]

    list_response = client.get("/api/products")
    assert list_response.status_code == 200
    assert len(list_response.json()) == 1

    get_response = client.get(f"/api/products/{product_id}")
    assert get_response.status_code == 200
    assert get_response.json()["id"] == product_id

    update_response = client.put(f"/api/products/{product_id}", json={"name": "Mouse Gamer"})
    assert update_response.status_code == 200
    assert update_response.json()["name"] == "Mouse Gamer"

    delete_response = client.delete(f"/api/products/{product_id}")
    assert delete_response.status_code == 204

    not_found_response = client.get(f"/api/products/{product_id}")
    assert not_found_response.status_code == 404

