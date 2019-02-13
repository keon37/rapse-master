from flask import Blueprint
routes = Blueprint('routes', __name__)

# 기타
from .inject_values import *
from .index import *
from .dev import *
from .login import *
from .signup import *

from .api import *

from .me import *
from .manage.user import *
from .manage.push import *
from .manage.data import *

from .public import *

from .normal.fmd import *
from .normal.hpai import *

from .breakout.fmd import *
from .breakout.hpai import *
from .breakout.grouping import *

from .facilities import *
