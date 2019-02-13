import subprocess
from flask import render_template, request, jsonify, current_app, flash

from .. import routes
from app.database.query import read_jobs, create_job
from app.util.roles import user_in_roles
from app.util.cache import clearCache
from app.util.r import batch_data


@routes.route('/manage/data')
@user_in_roles(['admin'])
def manage_data():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)

    jobs = read_jobs(page, per_page)
    return render_template('/manage/data.html', jobs=jobs)


@routes.route('/manage/data-batch/trigger', methods=['POST'])
@user_in_roles(['admin'])
def manage_data_batch_trigger():
    flash('데이터 일괄 처리가 실행되었습니다.')
    create_job()
    batch_data()
    return jsonify(result='ok')


@routes.route('/manage/data-remove-cache/trigger', methods=['POST'])
@user_in_roles(['admin'])
def manage_data_remove_cache_trigger():
    flash('캐쉬가 삭제되었습니다.')
    clearCache()
    return jsonify(result='ok')
