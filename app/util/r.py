import subprocess
from flask import current_app

import warnings
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
from rpy2.rinterface import RRuntimeWarning


def batch_data():
    subprocess.Popen([current_app.config['R_PATH'], current_app.config['R_SCRIPT_BATCH_DATA']])


def calculate_breakout_optimization(type, species, weights, places, optimization):
    warnings.filterwarnings("ignore", category=RRuntimeWarning)
    r_source = robjects.r['source']
    r_source(current_app.config['R_SCRIPT_CALCULATE_BREAKOUT_OPTIMIZATION'])

    robjects.r.assign("type", type)
    robjects.r.assign("species", species)
    robjects.r.assign("weights", weights)
    robjects.r.assign("places", places)
    robjects.r.assign("optimization", optimization)

    #print("places", places)
    r_result = "getResult(type, species, weights, places, optimization)"

    result = robjects.r(r_result)

    probability_and_optimal_cluster = pandas2ri.ri2py_dataframe(result[0])
    independence_rate = pandas2ri.ri2py_dataframe(result[1])
    independence_rate2 = pandas2ri.ri2py_dataframe(result[2])

    # print('probability_and_optimal_cluster {0} , independence_rate : {1}'.format('2', '3'))
    # print('probability_and_optimal_cluster {0} , independence_rate : {1}  , independence_rate2 : {2}'.format(probability_and_optimal_cluster, independence_rate , independence_rate2))
    return (probability_and_optimal_cluster, independence_rate, independence_rate2)


# json 테스트
# windows 인코딩 문제로 실패
# def calculate_breakout_optimization(type, species, weights, places, optimization):

#     r_result = subprocess.check_output(
#         [
#             "/usr/local/bin/Rscript",
#             "--vanilla",
#             "/Users/bpk/Works/ezfarm/rapse/app/r/calculate_breakout_optimization.R",
#             # current_app.config['R_PATH'],
#             # "--vanilla",
#             # current_app.config['R_SCRIPT_CALCULATE_BREAKOUT_OPTIMIZATION'],
#             'type={}'.format(type),
#             'species={}'.format(species),
#             'weights={}'.format(weights),
#             'places={}'.format(array_to_R(places)),
#             'optimization={}'.format(optimization),
#         ],
#     )

#     data = json.loads(r_result.decode('utf-8'))
#     return data

# def array_to_R(array):
#     return "c({})".format(", ".join('"{}"'.format(x) for x in array))

# print(
#     calculate_breakout_optimization(
#         "fmd", "10", "1100000", ["서울특별시|2018-03-21", "서울특별시|2018-03-21", "서울특별시|2018-03-21"], "전체시설균등"
#     )
# )

# Rscript app/r/calculate_breakout_optimization.R type="fmd" species="10" weights="1100000" places="c('서울특별시|2018-03-21', '서울특별시|2018-03-21', '서울특별시|2018-03-21')" optimization="전체시설균등"
# Rscript app\r\calculate_breakout_optimization_win.R type="fmd" species="10" weights="1100000" places="c('서울특별시|2018-03-21', '서울특별시|2018-03-21', '서울특별시|2018-03-21')" optimization="전체시설균등"