from app.database.database import db


# 데이터 베이스 생성
def init_db():
    import app.database.models
    db.create_all()
    db.session.commit()


# 데이터베이스 안의 데이터 생성
def init_datas():
    pass
