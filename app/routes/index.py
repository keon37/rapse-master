from flask import render_template, redirect, url_for, request
from flask_login import current_user

from . import routes


@routes.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404


@routes.route('/')
def index():
    user_role = getattr(current_user, 'USER_ROLE', [])
    if user_role in ['admin']:
        # return redirect(url_for('routes.normal_fmd'))
        return render_template('index.html')

    return redirect(url_for('routes.public_fmd_hpai', diseaseType='fmd'))


@routes.route('/privacy')
def privacy():
    isApp = request.args.get('app', default='false')
    return render_template(
        'privacy.html',
        isApp=isApp,
    )
