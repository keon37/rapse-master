import hashlib
import math
import datetime
from flask import request, jsonify, json, Response, current_app, abort
from geojson import Feature, Point
from flask_cors import cross_origin
import unicodecsv as csv

from . import routes
from app.util.roles import user_in_roles
from app.util.cache import cache
from app.util.csv_helper import csv_response
from app.util.r import calculate_breakout_optimization
from app.util.fcm import send_to_topics, send_to_devices
from app.database.query import read_gisFacilities, read_livestock_counts, read_cutScores, read_groupings_by, read_grouping, update_grouping, update_user_app, read_user_app_by_token, create_user_app, read_fac_capa_addr, read_farm_use_fac_addr
from app.database.models import CutScoreFmd, CutScoreHpai, GroupingFmd, GroupingHpai, GisFacility, UserApp
from app.util.codes import regions
from app.util.csv_helper import Line


def make_cache_key():
    args_as_sorted_tuple = tuple(sorted((pair for pair in request.form.items(multi=True))))
    args_as_bytes = str(args_as_sorted_tuple).encode()
    hashed_args = str(hashlib.md5(args_as_bytes).hexdigest())
    cache_key = request.path + hashed_args
    return cache_key


def json_cache_response(jsonData, hours=24):
    response = Response(response=json.dumps(jsonData, separators=(',', ':')), status=200, mimetype='application/json')
    response.headers.add('Cache-Control', 'public,max-age=%d' % int(3600 * hours))
    return response


# 시설정보 route
@routes.route('/api/facilities/<diseasetype>', methods=['GET'])
@cache.cached()
def api_facilities(diseasetype):
    facilities = read_gisFacilities(diseasetype)

    geoJsonFacilities = []
    for facility in facilities:
        geoJsonFacilities.append(
            Feature(
                geometry=Point((float(facility.lng), float(facility.lat))),
                properties={
                    "id": facility.id,
                    "name": facility.name,
                    "addr": facility.addr,
                    "addr_shp": facility.addr_shp,
                    "phone": facility.phone,
                    "species": facility.species,
                    "info": facility.info,
                    "scale": facility.scale_fmd if diseasetype == 'fmd' else facility.scale_hpai,
                    "scales": {
                        "chicken": facility.chicken,
                        "duck": facility.duck,
                        "pig": facility.pig,
                        "cow": facility.cow,
                        "production": facility.production,
                    },
                    "cat": facility.type,
                    "cat_detail": facility.type_detail,
                }
            )
        )

    return jsonify(geoJsonFacilities)
    # return json_cache_response(geoJsonFacilities, 240)


# 시설정보 route
@routes.route('/api/livestock_counts', methods=['GET'])
@cache.cached()
def api_livestock_counts():
    livestockCounts = read_livestock_counts()

    result = {}
    for l in livestockCounts:
        result[l.addr_shp] = {
            "chicken_sanlan": l.chicken_sanlan,
            "chicken_jong": l.chicken_jong,
            "chicken_yuk": l.chicken_yuk,
            "chicken_tojong": l.chicken_tojong,
            "chicken": l.chicken_sanlan + l.chicken_jong + l.chicken_tojong + l.chicken_yuk,
            "duck_yukyong": l.duck_yukyong,
            "duck_jong": l.duck_jong,
            "duck": l.duck_yukyong + l.duck_jong,
            "pig": l.pig,
            "cow_milk": l.cow_milk,
            "cow_beef": l.cow_hanwoo,
            "cow": l.cow_milk + l.cow_hanwoo,
            # "deer": l.deer,
            # "goat": l.goat,
        }

    return jsonify(result)


# 권역 shapefile route
# @routes.route('/api/regions', methods=['GET'])
# @cache.cached()
# def api_regions():
#     geoJsonRegions = readRegionsGeoJson()

#     return json_cache_response(geoJsonRegions, 2400)

# @routes.route('/api/regions/mobile', methods=['GET'])
# @cache.cached()
# def api_regions_mobile():
#     geoJsonRegions = readRegionsMobileGeoJson()

#     return json_cache_response(geoJsonRegions, 2400)


@routes.route('/api/fac_capa_addr', methods=['GET'])
@user_in_roles(['admin'])
def api_fac_capa_addr():
    datas = read_fac_capa_addr()
    result = capacity_and_uses_table_data_to_json_format(datas)

    return jsonify(result)


@routes.route('/api/farm_use_fac_addr', methods=['GET'])
@user_in_roles(['admin'])
def api_farm_use_fac_addr():
    datas = read_farm_use_fac_addr()
    result = capacity_and_uses_table_data_to_json_format(datas)

    return jsonify(result)


def capacity_and_uses_table_data_to_json_format(datas):
    result = {}
    for data in datas:
        result[data.address] = [
            data.f1_chi,
            data.f2_chi,
            data.f3_chi,
            data.f4_chi,
            data.f1_duc,
            data.f2_duc,
            data.f3_duc,
            data.f4_duc,
            data.f1_pig,
            data.f2_pig,
            data.f3_pig,
            data.f4_pig,
            data.f1_cow,
            data.f2_cow,
            data.f3_cow,
            data.f4_cow,
        ]
    return result


# 평시 route
@routes.route('/api/normal', methods=['POST'])
@user_in_roles(['admin'])
def api_normal():
    option_type = request.form.get('type', None)
    option_species = request.form.get('species', None)
    option_facilities = request.form.get('facilities', None)
    option_level = request.form.get('level', None)

    independenceRate = getIndependenceRate(option_type, option_species, option_facilities, option_level)
    clusterMapping = getNormalClusterMapping(option_type, option_species, option_facilities, option_level)

    return jsonify({"independenceRate": independenceRate, "clusterMapping": clusterMapping})


# 평시 다운로드 route
@routes.route('/api/normal/download', methods=['GET'])
@user_in_roles(['admin'])
def api_normal_download():
    option_type = request.args.get('type', None)
    option_species = request.args.get('species', None)
    option_facilities = request.args.get('facilities', None)
    option_level = request.args.get('level', None)

    facilties = read_gisFacilities(option_type)
    clusterMapping = getNormalClusterMapping(option_type, option_species, option_facilities, option_level)

    csv_facilities = GisFacility.to_csv(facilties, clusterMapping, False)

    filename = "{}-{}-species_{}-facilities_{}-level_{}".format('normal', option_type, option_species, option_facilities, option_level)

    return csv_response(csv_facilities, filename)


# 발생시 route
@routes.route('/api/breakout', methods=['POST'])
@user_in_roles(['admin'])
# @cache.cached(key_prefix=make_cache_key)
def api_breakout():
    option_type = request.form.get('type', None)  # fmd hpai
    option_species = request.form.get('species', None)  # 10 01 11
    option_weights = request.form.get('weights', None)  # 0000000 ~ 5555555
    option_places = request.form.getlist('places[]')  # ["서울특별시|2018-03-21", "서울특별시|2018-03-21", "서울특별시|2018-03-21"]
    option_optimization = request.form.get('optimization', None)  # 전체시설균등, 도축장 중심, 사료공장 중심, 종축장 중심

    # independence_rate2 추가하여 축종별 시설자립도 가져오기  
    probability_and_optimal_cluster, independence_rate, independence_rate2  = calculate_breakout_optimization(
        option_type, option_species, option_weights, option_places, option_optimization
    )

    probabilityAndOptimalCluster = {}
    for i, row in probability_and_optimal_cluster.iterrows():
        probabilityAndOptimalCluster[row['address']] = {
            "prob": row['spread_probability'] * 100,
            "cluster": "최적권역" if row['optimal_cluster'] else "기타권역"
        }

    independenceRate = []
    for i, row in independence_rate.iterrows():
        rate = row['self_reliance']
        if (math.isnan(rate)):
            rate = "NA"
        independenceRate.append({"facility": row['facility'], "rate": rate})
    
    independenceRate2 = []
    for i, row in independence_rate2.iterrows():
        rate = row['self_reliance1']
        rate2 = row['self_reliance2']
        if (math.isnan(rate)):
            rate = "NA"
        if (math.isnan(rate2)):
            rate2 = "NA"
        independenceRate2.append({"facility": row['facility'], "rate": rate , "rate2":rate2 })

    return jsonify({"independenceRate": independenceRate2 , "probabilityAndOptimalCluster": probabilityAndOptimalCluster})


# 발생시 다운로드 route
@routes.route('/api/breakout/download', methods=['GET'])
@user_in_roles(['admin'])
def api_breakout_download():
    option_type = request.args.get('type', None)
    option_species = request.args.get('species', None)
    option_weights = request.args.get('weights', None)
    option_places = request.args.getlist('places[]')
    option_optimization = request.args.get('optimization', None)

    facilties = read_gisFacilities(option_type)

    probability_and_optimal_cluster, independence_rate, independence_rate2 = calculate_breakout_optimization(
        option_type, option_species, option_weights, option_places, option_optimization
    )

    clusterMapping = {}
    for i, row in probability_and_optimal_cluster.iterrows():
        if row['optimal_cluster'] == 1:
            clusterMapping[row['address']] = "최적권역"
        else:
            clusterMapping[row['address']] = "기타권역"

    csv_facilities = GisFacility.to_csv(facilties, clusterMapping, True)

    filename = "{}-{}-species_{}-weights_{}-place_counts_{}-optimization_{}".format(
        'breakout', option_type, option_species, option_weights, len(option_places), optimizationToEnglish(option_optimization)
    )

    return csv_response(csv_facilities, filename)


# http://localhost:5060/api/breakout/all/download?type=fmd&species=10&weights=3121200&optimization=전체시설균등
# http://localhost:5060/api/breakout/all/download?type=fmd&species=01&weights=3200221&optimization=도축장 중심
# http://localhost:5060/api/breakout/all/download?type=fmd&species=01&weights=3200221&optimization=사료공장 중심
# http://localhost:5060/api/breakout/all/download?type=fmd&species=11&weights=3221211&optimization=전체시설균등


# 발생시 다운로드 route
@routes.route('/api/breakout/all/download', methods=['GET'])
@user_in_roles(['admin'])
def api_breakout_all_download():
    option_type = request.args.get('type', None)
    option_species = request.args.get('species', None)
    option_weights = request.args.get('weights', None)
    option_optimization = request.args.get('optimization', None)

    optimizations = []
    for region, _value in regions.items():
        if region == '모든 지역':
            continue

        option_places = ['{}|{}'.format(region.replace(" ", "_"), datetime.datetime.now().strftime("%Y-%m-%d"))]
        current_app.logger.info(option_places)
        probability_and_optimal_cluster, independence_rate, independence_rate2 = calculate_breakout_optimization(
            option_type, option_species, option_weights, option_places, option_optimization
        )

        independenceRate = {}
        for i, row in independence_rate.iterrows():
            rate = row['self_reliance']
            if (math.isnan(rate)):
                rate = "NA"
            independenceRate[row['facility']] = rate * 100
        optimalClusters = []

        for i, row in probability_and_optimal_cluster.iterrows():
            if row['optimal_cluster'] == 1:
                optimalClusters.append(row['address'].replace('_', ' '))

        # print("=============================================")
        # print("facility : ", independence_rate['facility'])


        # print("-----------------------------------------------")
        # print("independenceRate : " , independenceRate)
        # print("option_type :" , option_type)
        # #print("independenceRate[row['facility']] :" , independenceRate['facility'])
        # print("-----------------------------------------------")
        # print("independenceRate['도계/도압장']" , independenceRate['도계/도압장'])
    
        if option_type =="hpai":
            optimization = {
                '발생지': region,
                '최적권역리스트': ', '.join(optimalClusters),
                '자립도 도축장': round(independenceRate['도계/도압장'], 2),
                '자립도 사료공장': round(independenceRate['사료공장'], 2),
                '자립도 종축장': round(independenceRate['종축장'], 2),
                '자립도 분뇨처리장': round(independenceRate['분뇨처리장'], 2),
            }

        else:
            optimization = {
                '발생지': region,
                '최적권역리스트': ', '.join(optimalClusters),
                '자립도 도축장': round(independenceRate['도축장'], 2),
                '자립도 사료공장': round(independenceRate['사료공장'], 2),
                '자립도 종축장': round(independenceRate['종축장'], 2),
                '자립도 분뇨처리장': round(independenceRate['분뇨처리장'], 2),
            }
        
        optimizations.append(optimization)

        # print("optimization : " , optimization)
        # print("optimization 타입 : " , type(optimization))
        # print(" ============optimizations =====================")
        # print(optimizations)
    filename = "{}-{}-species_{}-weights_{}-optimization_{}".format(
        'breakout', option_type, option_species, option_weights, optimizationToEnglish(option_optimization)
    )

    def generate(optimizations):
        line = Line()
        writer = csv.writer(line, dialect='excel', encoding='utf-8-sig')
        writer.writerow([
            '발생지',
            '최적권역리스트',
            '자립도 도축장',
            '자립도 사료공장',
            '자립도 종축장',
            '자립도 분뇨처리장',
        ])
        yield line.read()

        for optimization in optimizations:
            writer.writerow(
                [
                    optimization['발생지'],
                    optimization['최적권역리스트'],
                    optimization['자립도 도축장'],
                    optimization['자립도 사료공장'],
                    optimization['자립도 종축장'],
                    optimization['자립도 분뇨처리장'],
                ]
            )
            yield line.read()

    return csv_response(generate(optimizations), filename)


# 수동권역화 정보 route
@routes.route('/api/grouping/<grouping_no>', methods=['GET'])
def api_grouping(grouping_no):
    grouping = read_grouping(grouping_no)
    if grouping:
        return jsonify(grouping.as_dict())
    else:
        return jsonify({})


# 수동권역화 다운로드 route
@routes.route('/api/grouping/download', methods=['GET'])
@user_in_roles(['admin'])
def api_grouping_download():
    grouping_no = request.args.get('grouping_no', None)

    grouping = read_grouping(grouping_no)
    facilties = read_gisFacilities(grouping.DISEASE_TYPE)

    clusterMapping = {}
    clusters = json.loads(grouping.CLUSTERS)
    for cluster in clusters:
        for addr_shp in cluster['regions']:
            clusterMapping[addr_shp] = cluster['number']

    csv_facilities = GisFacility.to_csv(facilties, clusterMapping, False)

    filename = "grouping_{}_{}_{}_{}".format(grouping.DISEASE_TYPE, grouping_no, grouping.START_DATE, grouping.END_DATE)

    return csv_response(csv_facilities, filename)


@routes.route('/api/grouping', methods=['POST'])
@user_in_roles(['admin'])
def api_grouping_update():
    content = request.json
    grouping = read_grouping(content['grouping_no'])

    grouping.CLUSTERS = json.dumps(content['clusters'])
    update_grouping(grouping)

    return jsonify({"result": "ok"})


@routes.route('/api/push/send/topics', methods=['POST'])
@user_in_roles(['admin'])
def api_push_send_topics():
    diseaseType = request.form.get('diseaseType', None)
    topics = request.form.getlist('topics[]')
    title = request.form.get('title', None)
    body = request.form.get('body', None)

    result = send_to_topics(diseaseType, topics, title, body)

    return jsonify(result)


@routes.route('/api/push/send/devices', methods=['POST'])
@user_in_roles(['admin'])
def api_push_send_devices():
    devices = request.form.getlist('devices[]')
    title = request.form.get('title', None)
    body = request.form.get('body', None)

    result = send_to_devices(devices, title, body)

    return jsonify(result)


@routes.route('/api/push/preference', methods=['POST'])
@cross_origin()
def api_push_preference():
    content = request.json

    # e6f8ktQogZQ:APA91bHV12Frzzf9U6NhxfQ0uxuXPnoOP4jrU6RZAW-0pJpQFYGazKagHOmX3SaWWYFBaUT5foPmaOugYPpYPede3Z96wIhtlGiA45eEZhxJvVQ8AbwIBX4t67CRTrSxb5YBc9vZijY6hElhnO-H6n9OQkNtDWmzeQ
    token = content.get('token', None)
    token_previous = content.get('tokenPrevious', None)  # 있을수도 있고 없을수도 있음
    hp = content.get('hp', None)  # 01012341234
    disease_type = content.get('diseaseType', None)  # 01012341234
    os = content.get('os', None)  # android / ios
    push = content.get('push', None)  # 1 / 0
    interest_region = content.get('interestRegion', None)  # 경기도 수원시

    current_app.logger.info(content)
    if not token or os is None or push is None or interest_region is None:
        return abort(400)

    if token_previous:
        user_app = read_user_app_by_token(token_previous)

        if user_app is None:
            user_app = UserApp()
            user_app.TOKEN = token
            user_app.OS = os
            user_app.HP_NO = hp
            user_app.DISEASE_TYPE = disease_type
            user_app.PUSH = push
            user_app.INTEREST_REGION = interest_region
            create_user_app(user_app)
        else:
            user_app.TOKEN = token
            user_app.OS = os
            user_app.HP_NO = hp
            user_app.DISEASE_TYPE = disease_type
            user_app.PUSH = push
            user_app.INTEREST_REGION = interest_region
            update_user_app(user_app)
    else:
        user_app = read_user_app_by_token(token)

        if user_app is None:
            user_app = UserApp()
            user_app.TOKEN = token
            user_app.OS = os
            user_app.HP_NO = hp
            user_app.DISEASE_TYPE = disease_type
            user_app.PUSH = push
            user_app.INTEREST_REGION = interest_region
            create_user_app(user_app)
        else:
            user_app.OS = os
            user_app.HP_NO = hp
            user_app.DISEASE_TYPE = disease_type
            user_app.PUSH = push
            user_app.INTEREST_REGION = interest_region
            update_user_app(user_app)

    # else:
    #     pass

    # register_or_update_push(grouping)

    return jsonify({"result": "ok"})


# 시설자립도 최적화 한글 to 영문
def optimizationToEnglish(optimization):
    engMapping = {}
    engMapping['전체시설균등'] = 'equal'
    engMapping['도축장 중심'] = 'slaughter'
    engMapping['사료공장 중심'] = 'feedmill'
    engMapping['종축장 중심'] = 'breedingfarm'
    return engMapping.get(optimization, "error")


# 권역별 자치스코어
def getIndependenceRate(option_type, option_species, option_facilities, option_level):
    if option_type == 'fmd':
        cutScoreTable = CutScoreFmd
    if option_type == 'hpai':
        cutScoreTable = CutScoreHpai

    cutScores = read_cutScores(cutScoreTable, option_species, option_facilities, option_level)
    independenceRate = []
    for cutScore in cutScores:
        independenceRate.append({"level": cutScore.level, "rate": float(cutScore.score)})

    return independenceRate


# 지역 클러스터링 데이터 로드
def getNormalClusterMapping(option_type, option_species, option_facilities, option_level):
    if option_type == 'fmd':
        groupingTable = GroupingFmd
    if option_type == 'hpai':
        groupingTable = GroupingHpai

    groupings = read_groupings_by(groupingTable, option_species, option_facilities, option_level)
    clusterMapping = {}
    for grouping in groupings:
        clusterMapping[grouping.address] = grouping.cluster

    return clusterMapping
