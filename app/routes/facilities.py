from flask import render_template

from . import routes


@routes.route('/facilities/fmd/density')
def facilities_fmd_density():
    return render_template('/facilities/density.html', diseaseType='fmd')


@routes.route('/facilities/fmd/scale')
def facilities_fmd_scale():
    return render_template('/facilities/scale.html', diseaseType='fmd')


@routes.route('/facilities/hpai/density')
def facilities_hpai_density():
    return render_template('/facilities/density.html', diseaseType='hpai')


@routes.route('/facilities/hpai/scale')
def facilities_hpai_scale():
    return render_template('/facilities/scale.html', diseaseType='hpai')
