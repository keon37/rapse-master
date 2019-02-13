import json

from flask import render_template, request, abort, flash, redirect, url_for

from .. import routes
from app.util.roles import user_in_roles
from app.database.query import read_groupings, read_grouping, update_grouping, create_grouping, delete_grouping
from app.database.models import Grouping
from app.util.forms import GroupingCreateForm, GroupingUpdateForm


@routes.route('/breakout/groupings/<diseaseType>')
@user_in_roles(['admin'])
def breakout_groupings(diseaseType):
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    groupings = read_groupings(page, per_page, diseaseType)
    return render_template('/breakout/groupings.html', diseaseType=diseaseType, groupings=groupings)


@routes.route('/breakout/groupings/<diseaseType>/<grouping_no>', methods=['GET', 'POST'])
@user_in_roles(['admin'])
def breakout_grouping(diseaseType, grouping_no):
    if request.method == 'GET':
        grouping = read_grouping(grouping_no)
        if grouping is None and grouping_no != 'create':
            return abort(404)

        if grouping_no == 'create':
            form = GroupingCreateForm(obj=grouping)
        else:
            form = GroupingUpdateForm(obj=grouping)

    if request.method == 'POST':
        if request.form['action'] == 'update':
            form = GroupingUpdateForm(request.form)

        if request.form['action'] == 'create':
            form = GroupingCreateForm(request.form)

        if request.form['action'] == 'delete':
            delete_grouping(grouping_no)
            flash('권역화 데이터가 삭제되었습니다.')
            return redirect(url_for('routes.breakout_groupings', diseaseType=diseaseType))

        if form.validate():
            grouping = Grouping(
                DISEASE_TYPE=form.DISEASE_TYPE.data,
                START_DATE=form.START_DATE.data,
                END_DATE=form.END_DATE.data,
            )

            if request.form['action'] == 'update':
                grouping.GROUPING_NO = form.GROUPING_NO.data
                update_grouping(grouping)
                flash('권역화 데이터가 업데이트 되었습니다.')

            if request.form['action'] == 'create':
                create_grouping(grouping)
                flash('권역화 데이터가 추가되었습니다.')
                return redirect(url_for('routes.breakout_groupings', diseaseType=diseaseType))

    return render_template('/breakout/grouping.html', diseaseType=diseaseType, form=form)


@routes.route('/breakout/groupings/map/<diseaseType>/<grouping_no>')
@user_in_roles(['admin'])
def breakout_grouping_map(diseaseType, grouping_no):
    grouping = read_grouping(grouping_no)
    clusters = json.dumps(grouping.CLUSTERS)
    return render_template('/breakout/grouping_map.html', diseaseType=diseaseType, grouping=grouping)
