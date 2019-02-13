import json
from flask import render_template, request, current_app

from . import routes
from app.database.query import read_grouping_by_diseaseType


@routes.route('/public/<any(fmd, hpai):diseaseType>')
def public_fmd_hpai(diseaseType):
    grouping = read_grouping_by_diseaseType(diseaseType)
    grouping_no = grouping.GROUPING_NO if grouping else 0
    diseaseMenuName = "HPAI" if diseaseType == "hpai" else "구제역"

    isApp = request.args.get('app', default='false')
    return render_template(
        '/public/public.html',
        diseaseType=diseaseType,
        diseaseMenuName=diseaseMenuName,
        grouping_no=grouping_no,
        isApp=isApp,
    )


@routes.route('/public/restriction')
@routes.route('/public/restriction/<any(fmd, hpai):diseaseType>')
def public_restriction(diseaseType='fmd'):
    grouping = read_grouping_by_diseaseType(diseaseType)
    if grouping and grouping.CLUSTERS:
        grouping_exist = True

        clusters = json.loads(grouping.CLUSTERS)

        regions = []
        regions_short = []
        regions_parent = []

        for cluster in clusters:
            regions = regions + cluster['regions']

        SORT_ORDER = {
            "서울특별시": 0,
            "부산광역시": 1,
            "대구광역시": 2,
            "인천광역시": 3,
            "광주광역시": 4,
            "대전광역시": 5,
            "울산광역시": 6,
            "세종특별자치시": 7,
            "경기도": 8,
            "강원도": 9,
            "충청북도": 10,
            "충청남도": 11,
            "전라북도": 12,
            "전라남도": 13,
            "경상북도": 14,
            "경상남도": 15,
            "제주특별자치도": 16,
        }
        regions.sort(key=lambda val: SORT_ORDER[val.split('_', 1)[0]])
        for region in regions:
            if "_" in region:
                region_parent = region.split('_', 1)[0]
                if region_parent not in regions_parent:
                    regions_parent.append(region_parent)
                else:
                    region = region.split('_', 1)[-1]

            regions_short.append(region.replace("_", " "))

        clusters_name = ", ".join(regions_short)

        start_date = grouping.START_DATE.strftime("%Y-%m-%d")
        end_date = grouping.END_DATE.strftime("%Y-%m-%d")
    else:
        grouping_exist = False
        clusters_name = "OO시, OO시, OO군"
        start_date = "0000-00-00"
        end_date = "0000-00-00"

    diseaseMenuName = "HPAI" if diseaseType == "hpai" else "구제역"
    isApp = request.args.get('app', default='false')

    return render_template(
        '/public/restriction.html',
        isApp=isApp,
        diseaseType=diseaseType,
        diseaseMenuName=diseaseMenuName,
        grouping_exist=grouping_exist,
        clusters_name=clusters_name,
        start_date=start_date,
        end_date=end_date,
    )


@routes.route('/public/introduction')
def public_introduction():
    isApp = request.args.get('app', default='false')
    return render_template(
        '/public/introduction.html',
        isApp=isApp,
    )
