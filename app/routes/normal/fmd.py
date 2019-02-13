from flask import render_template
from .. import routes
from app.util.roles import user_in_roles


@routes.route('/normal/fmd')
@user_in_roles(['admin'])
def normal_fmd():
    return render_template('/normal/fmd.html')
