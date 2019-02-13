import shapely.geometry
from shapely.ops import cascaded_union, unary_union
import multiprocessing
from geojson import Feature


# 권역정보 로드
def apiSample(shapes, groupingDictionary, key):
    clusters = {}
    for shape in shapes:
        cluster_id = groupingDictionary.get(key, None)
        if cluster_id not in clusters:
            clusters[cluster_id] = []

        clusters[cluster_id].append(shapely.geometry.shape(shape['geometry']))


# 권역 합치기(멀티프로세싱)
def multiprocessingUnionClusters(clusters):
    pool = multiprocessing.Pool(multiprocessing.cpu_count())
    unionFeatures = pool.map(unionClusterWrapper, clusters.items())
    return unionFeatures


def unionClusters(cluster_id, clusters):
    union_poly = unary_union(clusters)
    return Feature(
        geometry=union_poly, properties={
            "type": "c",
            "cluster": cluster_id,
        }
    )


def unionClusterWrapper(args):
    return unionClusters(*args)