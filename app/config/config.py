import os


def get_config_object():
    application_mode = os.getenv('APPLICATION_MODE', 'DEVELOPMENT')
    print('application_mode : {0}'.format(application_mode))
    if (application_mode == 'DEVELOPMENT'):
        return DevelopmentConfig
    else:
        return ProductionConfig


class Config(object):
    DEBUG = False
    TESTING = False

    SECRET_KEY = ''

    DB_TYPE = ''
    DB_HOST = ''
    DB_USER = ''
    DB_PASS = ''
    DB_PORT = ''
    DB_ARGS = ''
    SQLALCHEMY_DATABASE_URI = ''
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    JSON_SORT_KEYS = False
    JSON_AS_ASCII = False
    TEMPLATES_AUTO_RELOAD = True

    # BASE_PATH = /root/app
    BASE_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    CACHE_PATH = os.path.join(BASE_PATH, 'cache')
    if not os.path.exists(CACHE_PATH):
        os.makedirs(CACHE_PATH)
    CACHE_DEFAULT_TIMEOUT = 0

    SHAPEFILE_PATH = os.path.join(BASE_PATH, 'shapefile/TL_SCCO_SIG2.shp')
    SHAPEFILE_MOBILE_PATH = os.path.join(BASE_PATH, 'shapefile/simplify_0.001/TL_SCCO_SIG4.shp')

    R_PATH = ''
    R_SCRIPT_BATCH_DATA = os.path.join(BASE_PATH, 'r/batch_data.R')
    R_SCRIPT_CALCULATE_BREAKOUT_OPTIMIZATION = os.path.join(BASE_PATH, 'r/calculate_breakout_optimization.R')


class ProductionConfig(Config):
    DEBUG = False

    SECRET_KEY = b'\x15;zV\xbet\x15\tZ\xc1t\x9a\xa0\xda;\x83\xcd\xac\xe2P<5\xe6*'

    DB_TYPE = 'mysql+pymysql'
    DB_HOST = 'host.docker.internal'  # docker에서 host로 접근하기 위한 주소
    DB_USER = 'rapse_dlqldbwj'
    DB_PASS = 'CZwAfcWizT7qtkaDDQz'
    DB_PORT = '33060'
    DB_ARGS = 'rapse?charset=utf8'
    SQLALCHEMY_DATABASE_URI = '{0}://{1}:{2}@{3}:{4}/{5}'.format(DB_TYPE, DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_ARGS)

    # R_PATH = 'C:\Program Files\R\R-3.4.4\bin\Rscript.exe'
    R_PATH = '/usr/local/bin/Rscript'


class DevelopmentConfig(Config):
    DEBUG = True

    SECRET_KEY = b'\x15;zV\xbet\x15\tZ\xc1t\x9a\xa0\xda;\x83\xcd\xac\xe2P<5\xe6*'

    DB_TYPE = 'mysql+pymysql'
    DB_HOST = 'host.docker.internal'
    DB_USER = 'rapse_dlqldbwj'
    DB_PASS = 'CZwAfcWizT7qtkaDDQz'
    DB_PORT = '3306'
    DB_ARGS = 'rapse?charset=utf8'
    SQLALCHEMY_DATABASE_URI = '{0}://{1}:{2}@{3}:{4}/{5}'.format(DB_TYPE, DB_USER, DB_PASS, DB_HOST, DB_PORT, DB_ARGS)

    R_PATH = '/usr/local/bin/Rscript'


class TestingConfig(Config):
    TESTING = True
