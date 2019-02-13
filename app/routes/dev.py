from flask import current_app

from . import routes
from app.database import database_init
from app.util.roles import user_in_roles
from app.util.shape import readKorAdmShapeFileAddrs
# from app.util.r import calculate_breakout_optimization
# from app.database.query import update_gisFacility, read_gisFacility_by_id
# from app.database.models import GisFacility
# from app.database.database import db


@routes.route('/init_db')
# @user_in_roles(['admin'])
def init_db():
    # if current_app.debug:
    # database_init.init_db()
    return 'init_db'

    # return 'access denied'


# @routes.route('/init_datas')
# @user_in_roles(['admin'])
# def init_datas():
#     if current_app.debug:
#         database_init.init_datas()
#         return 'init_datas'

#     return 'access denied'


@routes.route('/shapefile_addresses')
@user_in_roles(['admin'])
def shapefile_addresses():
    return readKorAdmShapeFileAddrs()


# @routes.route('/test')
# @user_in_roles(['admin'])
# def test():
#     query = GisFacility.query.filter(GisFacility.info.like("%:%"))
#     query = query.filter(GisFacility.type.notin_(['가축시장', '도계장', '가금도축장', '도축장', '집유장']))
#     query = query.filter(GisFacility.scale == 0)
#     facs = query.all()

#     #
#     for fac in facs:
#         info = fac.info
#         p_s = info.find(":")
#         p_e = info.find("[")
#         # new_string = old_string[:k]
#         info_str = info[p_s + 1:p_e - 1]

#         try:
#             info_int = int(info_str)
#             current_app.logger.info(info_str)
#             fac.scale = info_int
#             db.session.merge(fac)
#             db.session.commit()
#         except ValueError:
#             pass

#     return ''

#     a = calculate_breakout_optimization(
#         'fmd', '10', '1000000', ["서울특별시|2018-03-21", "서울특별시|2018-03-21", "서울특별시|2018-03-21"], "전체시설균등"
#     )
#     print(a)
#     return 'tested'

# def updateGisFacilityShapeRegion():
#     from app.database.query import read_gisFacilities, update_gisFacility
#     facs = read_gisFacilities()
#     for fac in facs:
#         fac.addr_shp = fac.addr.replace(" ", "_")
#         update_gisFacility(fac)