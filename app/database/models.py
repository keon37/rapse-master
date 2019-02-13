import json
# from datetime import datetime, timedelta
import unicodecsv as csv
from sqlalchemy import Column, DateTime, Date, Integer, String, text, Table, BigInteger, Float, Text, ForeignKey
from sqlalchemy.orm import relationship
from flask_login import UserMixin
from werkzeug import generate_password_hash, check_password_hash

from app.database.database import db
from app.util.roles import roles
from app.util.codes import job_state
from app.util.csv_helper import Line


# 사용자
class User(db.Model, UserMixin):
    __tablename__ = 'user'

    USER_NO = Column(Integer, primary_key=True, comment='사용자고유번호(PK)')
    USER_ID = Column(String(50), nullable=False, index=True, comment='아이디')
    USER_PW = Column(String(255), nullable=False, comment='패스워드')
    USER_ROLE = Column(String(20), server_default="user", nullable=False, comment='권한')
    USER_NM = Column(String(50), nullable=False, comment='이름(실명)')
    USER_COMP = Column(String(50), nullable=False, comment='소속')
    USER_EMAIL = Column(String(50), nullable=False, comment='이메일')
    USER_HP_NO = Column(String(50), nullable=False, comment='연락처')
    CREAT_DT = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"), comment='가입일')
    APPROVAL = Column(String(1), server_default="0", nullable=False, index=True, comment='사용자 사용/미사용')

    def set_password(self, password):
        self.USER_PW = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.USER_PW, password)

    # For Flask-Login
    def get_id(self):
        return self.USER_NO

    def USER_ROLE_NM(self):
        return roles[self.USER_ROLE]


# 사용자
class UserApp(db.Model):
    __tablename__ = 'user_app'

    TOKEN = Column(String(500), nullable=False, primary_key=True, comment='푸쉬용 FCM Token(PK)')
    HP_NO = Column(String(50), nullable=True, index=True, comment='연락처')
    DISEASE_TYPE = Column(String(10), nullable=False, index=True, comment='질병타입 fmd/hpai')
    OS = Column(String(20), nullable=True, comment='스마트폰 운영체제')
    PUSH = Column(String(1), server_default="0", nullable=False, index=True, comment='알림 사용/미사용')
    INTEREST_REGION = Column(String(50), nullable=True, index=True, comment='관심지역')
    CREAT_DT = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"), comment='가입일')


# 배치작업
class Job(db.Model):
    __tablename__ = 'job'

    JOB_NO = Column(Integer, primary_key=True, comment='배치작업고유번호(PK)')
    JOB_STATE = Column(String(1), server_default="r", nullable=False, comment='배치작업 상태')
    START_DT = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"), comment='시작시간')
    END_DT = Column(DateTime, nullable=True, comment='종료시간')

    def JOB_STATE_NM(self):
        return job_state[self.JOB_STATE]

    def PROCESSING_TIME(self):
        if self.END_DT:
            return self.END_DT - self.START_DT
        return None


# 시설정보
class GisFacility(db.Model):
    __tablename__ = 'gis_fac'

    id = Column(Integer, primary_key=True, comment='시설고유번호(PK)')
    type = Column(String(50), server_default=text("''"), comment='시설형태')
    type_detail = Column(String(50), server_default=text("''"), comment='시설형태 상세구분')
    species = Column(String(50), comment='축종')
    name = Column(String(255), comment='시설명')
    addr = Column(String(255), server_default=text("''"), comment='주소')
    addr_shp = Column(String(255), comment='권역화용 주소')
    phone = Column(String(50), comment='전화번호')
    lat = Column(Float(asdecimal=True), comment='위도')
    lng = Column(Float(asdecimal=True), comment='경도')
    info = Column(String(500), comment='기타정보')
    scale_fmd = Column(Integer, server_default=text("'0'"), nullable=False, comment='FMD용 규모')
    scale_hpai = Column(Integer, server_default=text("'0'"), nullable=False, comment='HPAI용 규모')
    chicken = Column(Integer, server_default=text("'0'"), nullable=False, comment='닭')
    duck = Column(Integer, server_default=text("'0'"), nullable=False, comment='오리')
    pig = Column(Integer, server_default=text("'0'"), nullable=False, comment='돼지')
    cow = Column(Integer, server_default=text("'0'"), nullable=False, comment='소')
    production = Column(Integer, server_default=text("'0'"), nullable=False, comment='생산능력')
    newest = Column(Integer, server_default=text("'0'"), comment='새로입력했는지 여부')

    @staticmethod
    def to_csv(facilties, cluster_mapping, breakout=False):
        line = Line()
        writer = csv.writer(line, dialect='excel', encoding='utf-8-sig')
        writer.writerow([
            '권역',
            '시설구분',
            '상세구분',
            '축종',
            '시설명',
            '주소',
            '연락처',
            '위도',
            '경도',
            '기타정보',
            '닭',
            '오리',
            '돼지',
            '소',
            '생산능력',
        ])
        yield line.read()

        sortable_list = []

        for item in facilties:
            cluster = cluster_mapping.get(item.addr_shp, -1)
            sortable_list.append({"cluster": cluster, "addr": item.addr, "item": item})

        # 발생시는 cluster명이 String 형태로 넘어옴
        if breakout:
            sorted_list = sorted(sortable_list, key=lambda elem: "%s %s" % (elem['cluster'], elem['addr']), reverse=True)
        else:
            sorted_list = sorted(sortable_list, key=lambda elem: "%02d %s" % (elem['cluster'], elem['addr']))

        for sorted_item in sorted_list:
            item = sorted_item['item']

            writer.writerow(
                [
                    cluster_mapping.get(item.addr_shp, '비권역'),
                    item.type,
                    item.type_detail,
                    item.species,
                    item.name,
                    item.addr,
                    item.phone,
                    item.lat,
                    item.lng,
                    item.info,
                    item.chicken,
                    item.duck,
                    item.pig,
                    item.cow,
                    item.production,
                ]
            )
            yield line.read()


# 권역화 (수동)
class Grouping(db.Model):
    __tablename__ = 'grouping'

    GROUPING_NO = Column(Integer, primary_key=True, comment='권역화 고유번호(PK)')
    DISEASE_TYPE = Column(String(50), index=True, comment='질병타입 fmd / hpai')
    START_DATE = Column(Date, index=True, nullable=False, comment='시작시간')
    END_DATE = Column(Date, index=True, nullable=False, comment='종료시간')
    CREATE_DT = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"), comment='생성시간')
    CLUSTERS = Column(String(10000), comment='클러스터 리스트 json 타입')

    def as_dict(self):
        return {
            "grouping_no": self.GROUPING_NO,
            "start_date": self.START_DATE.strftime("%Y-%m-%d"),
            "end_date": self.END_DATE.strftime("%Y-%m-%d"),
            "clusters": json.loads(self.CLUSTERS) if self.CLUSTERS else '',
        }


# 사육수수
class LivestockCount(db.Model):
    __tablename__ = 'livestock_count'

    addr_shp = Column(String(30), primary_key=True, comment='지역명(PK)')
    chicken_sanlan = Column(Integer, server_default=text("'0'"), nullable=False, comment='산란계')
    chicken_jong = Column(Integer, server_default=text("'0'"), nullable=False, comment='종계')
    chicken_yuk = Column(Integer, server_default=text("'0'"), nullable=False, comment='육계')
    chicken_tojong = Column(Integer, server_default=text("'0'"), nullable=False, comment='토종닭')
    duck_yukyong = Column(Integer, server_default=text("'0'"), nullable=False, comment='육용오리')
    duck_jong = Column(Integer, server_default=text("'0'"), nullable=False, comment='종오리')
    pig = Column(Integer, server_default=text("'0'"), nullable=False, comment='돼지')
    cow_milk = Column(Integer, server_default=text("'0'"), nullable=False, comment='젖소')
    cow_hanwoo = Column(Integer, server_default=text("'0'"), nullable=False, comment='한우')
    deer = Column(Integer, server_default=text("'0'"), nullable=False, comment='사슴')
    goat = Column(Integer, server_default=text("'0'"), nullable=False, comment='염소')


# 서울대 생성
# 평시 권역화 컷스코어 돼지/소
CutScoreFmd = Table(
    'cut_score_fmd', db.Model.metadata, Column('condition_species', String(20), index=True),
    Column('condition_facilities', String(20), index=True), Column('level', Integer), Column('score', Float(asdecimal=True))
)

# 평시 권역화 컷스코어 닭/오리
CutScoreHpai = Table(
    'cut_score_hpai', db.Model.metadata, Column('condition_species', String(20), index=True),
    Column('condition_facilities', String(20), index=True), Column('level', Integer), Column('score', Float(asdecimal=True))
)

# 평시 권역화 군집결과 돼지/소
GroupingFmd = Table(
    'grouping_fmd', db.Model.metadata, Column('address', String(255), server_default=text("''")),
    Column('metro_name', String(255), server_default=text("''")), Column('city_name', String(255), server_default=text("''")),
    Column('condition_species', String(20), index=True), Column('condition_facilities', String(20), index=True), Column('level', Integer),
    Column('cluster', Integer)
)

# 평시 권역화 군집결과 닭/오리
GroupingHpai = Table(
    'grouping_hpai', db.Model.metadata, Column('address', String(255), server_default=text("''")),
    Column('metro_name', String(255), server_default=text("''")), Column('city_name', String(255), server_default=text("''")),
    Column('condition_species', String(20), index=True), Column('condition_facilities', String(20), index=True), Column('level', Integer),
    Column('cluster', Integer)
)

t_fac_capa_addr = Table(
    'fac_capa_addr', db.Model.metadata, Column('address', String(255)), Column('f1_chi', Integer), Column('f2_chi', Integer),
    Column('f3_chi', Integer), Column('f4_chi', Integer), Column('f1_duc', Integer), Column('f2_duc', Integer), Column('f3_duc', Integer),
    Column('f4_duc', Integer), Column('f1_pig', Integer), Column('f2_pig', Integer), Column('f3_pig', Integer), Column('f4_pig', Integer),
    Column('f1_cow', Integer), Column('f2_cow', Integer), Column('f3_cow', Integer), Column('f4_cow', Integer)
)

t_farm_use_fac_addr = Table(
    'farm_use_fac_addr', db.Model.metadata, Column('address', String(255)), Column('f1_chi', Integer), Column('f2_chi', Integer),
    Column('f3_chi', Integer), Column('f4_chi', Integer), Column('f1_duc', Integer), Column('f2_duc', Integer), Column('f3_duc', Integer),
    Column('f4_duc', Integer), Column('f1_pig', Integer), Column('f2_pig', Integer), Column('f3_pig', Integer), Column('f4_pig', Integer),
    Column('f1_cow', Integer), Column('f2_cow', Integer), Column('f3_cow', Integer), Column('f4_cow', Integer)
)

t_tb_adm_adj = Table(
    'tb_adm_adj', db.Model.metadata, Column('address', String(255)), Column('address2', String(255)), Column('adj', Integer)
)

t_trmat_chi = Table(
    'trmat_chi', db.Model.metadata, Column('addr_from', String(255)), Column('addr_to', String(255)), Column('f1', Integer),
    Column('f2', Integer), Column('f3', Integer), Column('f4', Integer), Column('f5', Integer), Column('f6', Integer),
    Column('f7', Integer)
)

t_trmat_cow = Table(
    'trmat_cow', db.Model.metadata, Column('addr_from', String(255)), Column('addr_to', String(255)), Column('f1', Integer),
    Column('f2', Integer), Column('f3', Integer), Column('f4', Integer), Column('f5', Integer), Column('f6', Integer),
    Column('f7', Integer)
)

t_trmat_duc = Table(
    'trmat_duc', db.Model.metadata, Column('addr_from', String(255)), Column('addr_to', String(255)), Column('f1', Integer),
    Column('f2', Integer), Column('f3', Integer), Column('f4', Integer), Column('f5', Integer), Column('f6', Integer),
    Column('f7', Integer)
)

t_trmat_hoof = Table(
    'trmat_hoof', db.Model.metadata, Column('addr_from', String(255)), Column('addr_to', String(255)), Column('f1', Integer),
    Column('f2', Integer), Column('f3', Integer), Column('f4', Integer), Column('f5', Integer), Column('f6', Integer),
    Column('f7', Integer)
)

t_trmat_pig = Table(
    'trmat_pig', db.Model.metadata, Column('addr_from', String(255)), Column('addr_to', String(255)), Column('f1', Integer),
    Column('f2', Integer), Column('f3', Integer), Column('f4', Integer), Column('f5', Integer), Column('f6', Integer),
    Column('f7', Integer)
)

t_trmat_poul = Table(
    'trmat_poul', db.Model.metadata, Column('addr_from', String(255)), Column('addr_to', String(255)), Column('f1', Integer),
    Column('f2', Integer), Column('f3', Integer), Column('f4', Integer), Column('f5', Integer), Column('f6', Integer),
    Column('f7', Integer)
)
