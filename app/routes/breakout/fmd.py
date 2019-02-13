from flask import render_template
from .. import routes
from app.util.roles import user_in_roles


@routes.route('/breakout/fmd')
@user_in_roles(['admin'])
def breakout_fmd():
    return render_template('/breakout/fmd.html')
