from flask import render_template
from .. import routes
from app.util.roles import user_in_roles


@routes.route('/normal/hpai')
@user_in_roles(['admin'])
def normal_hpai():
    return render_template('/normal/hpai.html')
