from sqlalchemy.orm import Session

from app import models, schemas


def list_products(db: Session):
    return db.query(models.Product).order_by(models.Product.id.asc()).all()


def get_product(db: Session, product_id: int):
    return db.query(models.Product).filter(models.Product.id == product_id).first()


def create_product(db: Session, payload: schemas.ProductCreate):
    product = models.Product(name=payload.name.strip())
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


def update_product(db: Session, product: models.Product, payload: schemas.ProductUpdate):
    product.name = payload.name.strip()
    db.commit()
    db.refresh(product)
    return product


def delete_product(db: Session, product: models.Product):
    db.delete(product)
    db.commit()

