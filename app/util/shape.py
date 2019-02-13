import fiona
from flask import current_app, json
from geojson import Feature


def readRegionsGeoJson():
    shapes = fiona.open(current_app.config['SHAPEFILE_PATH'], encoding='euc-kr')
    # shape = fiona.open(current_app.config['SHAPEFILE_PATH'])
    return shapesToGeoJson(shapes)


def readRegionsMobileGeoJson():
    shapes = fiona.open(current_app.config['SHAPEFILE_MOBILE_PATH'], encoding='euc-kr')
    return shapesToGeoJson(shapes)


def shapesToGeoJson(shapes):
    geoJsonRegions = []

    for shape in shapes:
        addr_shp = shape['properties']['NL_NAME_3']

        if addr_shp == '경상북도_울릉군':
            continue

        geoJsonRegions.append(Feature(geometry=shape['geometry'], properties={
            "addr_shp": addr_shp,
        }))

    # geoJsonRegionsToFile(geoJsonRegions)

    return geoJsonRegions


def geoJsonRegionsToFile(geoJsonRegions):
    with open("regions.json", "w") as text_file:
        text_file.write(json.dumps(geoJsonRegions, separators=(',', ':')))


def readKorAdmShapeFileAddrs():
    shapes = fiona.open(current_app.config['SHAPEFILE_PATH'], encoding='euc-kr')
    addrs = []
    for shape in shapes:
        NL_NAME_3 = shape['properties']['NL_NAME_3']
        if NL_NAME_3 not in addrs:
            addrs.append(NL_NAME_3)

    return "<br>".join(addrs)
