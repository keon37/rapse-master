from flask import render_template
from .. import routes
from app.util.roles import user_in_roles


@routes.route('/breakout/hpai')
@user_in_roles(['admin'])
def breakout_hpai():
    return render_template('/breakout/hpai.html')
