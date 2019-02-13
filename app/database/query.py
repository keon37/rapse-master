import datetime

from app.database.models import User, Job, GisFacility, Grouping, UserApp, LivestockCount, t_fac_capa_addr, t_farm_use_fac_addr
from app.database.database import db


# 관리자 - 사용자 리스트에서 사용
def read_users(page, per_page, condition_key, condition_value):
    query = User.query

    if condition_key and condition_value:
        if condition_key == 'user_name':
            query = query.filter(User.USER_NM.like('%' + condition_value + '%'))
        if condition_key == 'user_id':
            query = query.filter(User.USER_ID.like('%' + condition_value + '%'))

    return query.order_by(User.USER_NO.desc()).paginate(page, per_page)


def read_user_by_no(user_no):
    return User.query.filter(User.USER_NO == user_no).first()


def read_user_by_id(user_id):
    return User.query.filter(User.USER_ID == user_id).first()


def read_approved_user_by_no(user_no):
    return User.query.filter(User.APPROVAL == '1').filter(User.USER_NO == user_no).first()


def read_approved_user_by_id(user_id):
    return User.query.filter(User.APPROVAL == '1').filter(User.USER_ID == user_id).first()


def update_user(user):
    db.session.merge(user)
    db.session.commit()


def create_user(user):
    db.session.add(user)
    db.session.commit()
    if user.USER_NO is None:
        return False
    return True


def read_jobs(page, per_page):
    return Job.query.order_by(Job.JOB_NO.desc()).paginate(page, per_page)


def create_job():
    db.session.add(Job())
    db.session.commit()


def read_gisFacilities(diseaseType):
    query = GisFacility.query
    facilityTypes = []

    if diseaseType == "all":
        # facilityTypes = ["종축장", "종압장", "도계장", "도축장", "집유장", "부화장", "AI센터", "가축분뇨처리장", "사료공장", "도압장", "가축시장", "식용란판매업", "가축검정기관", "비료제조업", "가든형식당", "기타시설", "전통시장", "가축인공수정소", "거점소독시설"]
        pass

    if diseaseType == "fmd":
        facilityTypes = ["종축장", "도축장", "집유장", "사료공장", "가축시장", "가축검정기관", "비료제조업", "AI센터", "가축분뇨처리장", "비료제조업", "거점소독시설", "가축인공수정소"]
        query = query.filter(GisFacility.type.in_(facilityTypes))

    if diseaseType == "hpai":
        facilityTypes = [
            "종계장", "종압장", "도계장", "도압장", "사료공장", "부화장", "비료제조업", "가축분뇨처리장", "비료제조업", "철새도래지", "식용란판매업", "거점소독시설", "전통시장", "가든형식당"
        ]
        query = query.filter(GisFacility.type.in_(facilityTypes))

    return query.order_by(GisFacility.addr_shp).all()


def read_gisFacility_by_id(id):
    return GisFacility.query.filter(GisFacility.id == id).first()


def update_gisFacility(facility):
    db.session.merge(facility)
    db.session.commit()


def read_livestock_counts():
    return LivestockCount.query.all()


def read_cutScores(table, species, facilities, level):
    query = db.session.query(table).order_by(table.c.level)
    query = query.filter(table.c.condition_species == species).filter(table.c.condition_facilities == facilities
                                                                      ).filter(table.c.level <= level)
    return query.all()


def read_groupings_by(table, species, facilities, level):
    query = db.session.query(table)
    query = query.filter(table.c.condition_species == species).filter(table.c.condition_facilities == facilities
                                                                      ).filter(table.c.level == level)
    return query.all()


def read_groupings(page, per_page, diseaseType):
    query = Grouping.query
    query = query.filter(Grouping.DISEASE_TYPE == diseaseType)
    return query.order_by(Grouping.GROUPING_NO.desc()).paginate(page, per_page)


def read_grouping(grouping_no):
    query = Grouping.query
    return query.filter(Grouping.GROUPING_NO == grouping_no).first()


def read_grouping_by_diseaseType(diseaseType):
    query = Grouping.query
    query = query.filter(Grouping.DISEASE_TYPE == diseaseType)
    query = query.filter(Grouping.START_DATE <= datetime.datetime.now().date())
    query = query.filter(Grouping.END_DATE >= datetime.datetime.now().date())
    return query.first()


def update_grouping(grouping):
    db.session.merge(grouping)
    db.session.commit()


def create_grouping(grouping):
    db.session.add(grouping)
    db.session.commit()
    if grouping.GROUPING_NO is None:
        return False
    return True


def delete_grouping(grouping_no):
    Grouping.query.filter(Grouping.GROUPING_NO == grouping_no).delete()
    db.session.commit()


def read_user_app_by_token(token):
    return UserApp.query.filter(UserApp.TOKEN == token).first()


def read_user_app_by_hp(hp):
    return UserApp.query.filter(UserApp.HP_NO == hp).first()


# 관리자 - 앱 사용자 리스트에서 사용
def read_user_apps(page, per_page, condition_key, condition_value):
    query = UserApp.query

    if condition_key and condition_value:
        if condition_key == 'os':
            query = query.filter(UserApp.OS.like('%' + condition_value + '%'))
        if condition_key == 'disease_type':
            query = query.filter(UserApp.DISEASE_TYPE.like('%' + condition_value + '%'))

    return query.order_by(UserApp.CREAT_DT.desc()).paginate(page, per_page)


def create_user_app(user_app):
    db.session.add(user_app)
    db.session.commit()


def update_user_app(user_app):
    db.session.merge(user_app)
    db.session.commit()


def read_fac_capa_addr():
    return db.session.query(t_fac_capa_addr).all()


def read_farm_use_fac_addr():
    return db.session.query(t_farm_use_fac_addr).all()
