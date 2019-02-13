import os
from flask import Flask

from app.config.config import get_config_object
from app.routes import *

from app.database.database import db
from app.login_manager import login_manager
from app.util.cache import cache
from flask_cors import CORS


def create_app(test_config=None):
    app = Flask(
        __name__,
        instance_relative_config=True,
        static_url_path='',
        static_folder='static',
        template_folder='templates',
    )

    # CORS 설정추가 - Ionic app을 위함
    CORS(app)

    # 설정 로드
    app.config.from_object(get_config_object())

    # URL라우트 등록
    app.register_blueprint(routes)

    # jinja에서 쓰는 pagination을 위한 do 명렁어 등록
    app.jinja_env.add_extension('jinja2.ext.do')

    # Database 로드
    db.init_app(app)

    # 로그인 매니져 로드
    login_manager.init_app(app)

    # 캐쉬 for api performance
    cache.init_app(
        app,
        config={
            'CACHE_TYPE': 'filesystem',
            'CACHE_DIR': app.config['CACHE_PATH'],
            'CACHE_DEFAULT_TIMEOUT': app.config['CACHE_DEFAULT_TIMEOUT']
        }
    )

    return app
