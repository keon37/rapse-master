from flask import abort
from functools import wraps
from flask_login import current_user

from app.login_manager import login_manager

roles = {
    'admin': '관리자',
    'user': '사용자',
}


def user_in_roles(roles=['ANY']):
    def wrapper(func):
        @wraps(func)
        def inner(*args, **kwargs):

            if not current_user.is_authenticated:
                return login_manager.unauthorized()

            if getattr(current_user, 'USER_ROLE', []) not in roles and 'ANY' not in roles:
                raise abort(403)

            return func(*args, **kwargs)

        return inner

    return wrapper
