from flask import Flask, render_template, request, redirect, g, flash, url_for
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from flask_breadcrumbs import Breadcrumbs, register_breadcrumb
from flask_menu import Menu, register_menu
from forms.forms import *
from breadcrumbs_dlc import *
from user_login import *
from dotmap import DotMap
from db import *
import psycopg2
import requests
import base64
import os

imgbb_key = "c31a8b1bd295a75db042e6d001228034"
app = Flask(__name__)
app.config["SECRET_KEY"] = "9d3fc4c15037cf54e9e6ca948d99dda7f1823d1d"
app.config["UPLOAD_FOLDER"] = "/uploads/"
app.jinja_env.trim_blocks = True
Menu(app=app)
Breadcrumbs(app=app)
login_manager = LoginManager(app=app)
login_manager.login_view = "user_auth"
login_manager.login_message = "Для доступа требуется авторизация"
login_manager.login_message_category = "danger"

@app.route("/", methods=["POST", "GET"])
@register_breadcrumb(app, ".", "Главная")
@register_menu(app, ".", "Главная", order=0)
def index():
    if not current_user.is_authenticated:
        return redirect(url_for("user_auth"))
    clients = db.get_all_clients_short()
    filter = FormEstimatesFilters(clients)
    values = DotMap({
        "start_date": filter.start_date.data,
        "close_date": filter.close_date.data,
        "client_id": filter.client_id.data if filter.client_id.data != "-1" else None
    })
    estimates = db.get_filtered_estimates(values)
    return render_template("estimates/index.htm",
        filter=filter,
        estimates=estimates
    )

@app.route("/estimates/<int:estimate_id>/show", methods=["POST", "GET"])
@register_breadcrumb(app, ".estimates_show", "", dynamic_list_constructor=estimates_show_dlc)
@login_required
def estimates_show(estimate_id):
    estimate = db.get_estimate_by_id(estimate_id)
    if not estimate:
        return redirect(url_for("index"))
    equipments = db.get_estimates_details_by_id(estimate_id)
    return render_template("estimates/show.htm",
        estimate=estimate,
        equipments=equipments
    )

equipments = []
@app.route("/estimates/create", methods=["POST", "GET"])
@register_breadcrumb(app, ".estimates_create", "Создание сметы")
@register_menu(app, ".estimates_create", "Создание сметы", order=1)
@login_required
def estimates_create():
    global equipments
    clients = db.get_all_clients_short()
    form = FormEstimatesCreate(clients)
    if request.args.get("equipment_id"):
        id = int(request.args.get("equipment_id"))
        flag = False
        for equipment in equipments:
            if equipment.item.id == id:
                if not request.args.get("minus"):
                    if equipment.count + 1 <= equipment.item.count:
                        equipment.count += 1
                else:
                    equipment.count -= 1
                    if equipment.count == 0:
                        equipments.remove(equipment)
                flag = True
                break
        if not flag:
            equipments.append(DotMap({
                "item": db.get_equipment_by_id(id),
                "count": 1
            }))
    if form.validate_on_submit() and request.method == "POST":
        data = DotMap({
            "creator_id": current_user.user.id,
            "client_id": form.client_id.data,
            "project": form.project.data,
            "start_date": form.start_date.data,
            "close_date": form.close_date.data,
            "comment": form.comment.data if len(form.comment.data) != 0 else None
        })
        new_estimate = db.create_estimate(data)
        for equipment in equipments:
            item = DotMap({
                "estimate_id": new_estimate.new_id,
                "equipment_id": equipment.item.id,
                "price_id": equipment.item.price_id,
                "count": equipment.count
            })
            db.create_estimate_details(item)
        equipments = []
        # ! НЕ ЗАБЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫЫТЬ
        return redirect(url_for("estimates_create_reset",
            next=url_for("estimates_show", 
                estimate_id=new_estimate.new_id
            ))
        )
    return render_template("estimates/create.htm",
        form=form,
        equipments=equipments
    )
    
@app.route("/estimates/create/reset", methods=["POST", "GET"])
@login_required
def estimates_create_reset():
    global equipments
    equipments = []
    return redirect(request.args.get("next") or url_for("index"))

@app.route("/estimates/<int:estimate_id>/payed", methods=["POST", "GET"])
@login_required
def estimates_payed(estimate_id):
    estimate = db.get_estimate_by_id(estimate_id)
    if not estimate or estimate.is_payed:
        return redirect(url_for("estimates_show", estimate_id=estimate_id))
    db.estimate_set_payed(estimate_id)
    flash("Смета отмечена как оплаченная", "success")
    return redirect(url_for("estimates_show", estimate_id=estimate_id))

@app.route("/estimates/<int:estimate_id>/delete", methods=["GET"])
@register_breadcrumb(app, ".estimates.estimates_delete", "")
@login_required
def estimates_delete(estimate_id):
    # ! ДОБАВИТЬ ПРОВЕРКУ НА АДМИНА
    db.delete_estimate_by_id(estimate_id)
    return redirect(request.args.get("next") or url_for("index"))

@app.route("/storage", methods=["POST", "GET"])
@register_breadcrumb(app, ".storage", "Склад")
@register_menu(app, ".storage", "Склад", order=2)
@login_required
def storage():
    categories = db.get_categories_tree()
    search = FormStorageSearch(categories)
    values = DotMap({
        "category_id": int(search.category_id.data),
        "query": search.query.data if search.query.data is not None else ''
    })
    equipments = db.get_equipments(values)
    return render_template("storage/index.htm",
        search=search,
        equipments=equipments
    )

@app.route("/storage/<int:equipment_id>/show", methods=["POST", "GET"])
@register_breadcrumb(app, ".storage.storage_show", "", dynamic_list_constructor=storage_show_dlc)
@login_required
def storage_show(equipment_id):
    equipment = db.get_equipment_by_id(equipment_id)
    if not equipment:
        return redirect(url_for("storage"))
    return render_template("storage/show.htm",
        equipment=equipment
    )

@app.route("/storage/create", methods=["POST", "GET"])
@register_breadcrumb(app, ".storage.storage_create", "Добавление оборудования")
@login_required
def storage_create():
    # ! ДОБАВИТЬ ПРОВЕРКУ НА АДМИНА
    parents = db.get_equipments(DotMap({
        "category_id": -1,
        "query": None
    }))
    categories = db.get_categories_tree()
    form = FormStorageCreate(parents, categories)
    if form.validate_on_submit():
        urls = []
        files = request.files.getlist("files")
        for f in files:
            f.save(f.filename)
            f.close()
            with open(f.filename, "rb") as file:
                http = "https://api.imgbb.com/1/upload"
                payload = {
                    "key": imgbb_key,
                    "image": base64.b64encode(file.read()),
                }
                res = requests.post(http, payload)
                urls.append(res.json().get("data").get("url"))
            os.remove(f.filename)
        data = DotMap({
            "parent_id": form.parent_id.data if form.parent_id.data != "-1" else None,
            "title": form.title.data,
            "category_id": form.category_id.data,
            "description": form.description.data if len(form.description.data) != 0 else None,
            "images": [ url for url in urls ]
        })
        equipment = db.create_equipment(data)
        return redirect(url_for("storage_show", equipment_id=equipment.new_id))
    return render_template("storage/create.htm", 
        form=form
    )

@app.route("/storage/<int:equipment_id>/edit", methods=["POST", "GET"])
@register_breadcrumb(app, ".storage.storage_edit", "", dynamic_list_constructor=storage_edit_dlc)
@login_required
def storage_edit(equipment_id):
    # ! ДОБАВИТЬ ПРОВЕРКУ НА АДМИНА
    equipment = db.get_equipment_by_id(equipment_id)
    parents = db.get_equipments(DotMap({
        "category_id": -1,
        "query": None
    }))
    categories = db.get_categories_tree()
    form = FormStorageEdit(parents, categories, equipment)
    if form.validate_on_submit():
        data = DotMap({
            "equipment_id": equipment_id,
            "title": form.title.data,
            "parent_id": form.parent_id.data,
            "category_id": form.category_id.data,
            "description": form.description.data,
            "price": form.price.data,
            "count": form.count.data
        })
        try:
            db.equipments_update(data)
            flash("Данные оборудования обновлены", "success")
            return redirect(url_for("storage_show", equipment_id=equipment_id))
        except Exception:
            flash("Нет изменений для сохранения", "danger")
            return redirect(url_for("storage_edit", equipment_id=equipment_id))
    return render_template("storage/edit.htm", 
        equipment=equipment,
        form=form
    )

@app.route("/clients/<int:client_id>/show", methods=["POST", "GET"])
@register_breadcrumb(app, ".clients.clients_show", "Клиент")
@login_required
def clients_show(client_id):
    client = db.get_client_by_id(client_id)
    if not client:
        return redirect(url_for("clients"))
    personal = FormClientsPersonal(client)
    passport = FormClientsPassport(client)
    if personal.validate_on_submit() and personal.personal_submit.data:
        data = DotMap({
            "id": client.id,
            "name": personal.name.data,
            "surname": personal.surname.data,
            "phone": personal.phone.data,
            "telegram": personal.telegram.data,
            "discount": personal.discount.data,
            "comment": personal.comment.data
        })
        try:
            db.client_personal_update(data)
            flash("Личные данные клиента обновлены", "success")
        except Exception:
            flash("В личных данных нет изменений для сохранения", "danger")

    elif passport.validate_on_submit() and passport.passport_submit.data:
        data = DotMap({
            "id": client.id,
            "series": passport.series.data,
            "number": passport.number.data,
            "issued_by": passport.issued_by.data,
            "issue_date": passport.issue_date.data,
            "division_code": passport.division_code.data,
            "registration_address": passport.registration_address.data
        })
        try:
            db.client_passport_update(data)
            flash("Паспортные данные клиента обновлены", "success")
        except Exception:
            flash("В паспортных данных нет изменений для сохранения", "danger")

    return render_template("clients/show.htm",
        client=client,
        personal=personal,
        passport=passport
    )

@app.route("/clients/<int:client_id>/estimates", methods=["POST", "GET"])
@register_breadcrumb(app, ".clients.clients_estimates", "Клиент")
@login_required
def clients_estimates(client_id):
    client = db.get_client_by_id(client_id)
    if not client:
        return redirect(url_for("clients"))
    estimates = db.get_filtered_estimates(DotMap({
        "start_date": None,
        "close_date": None,
        "client_id": client_id
    }))
    return render_template("clients/estimates.htm",
        client=client,
        estimates=estimates
    )

# ! ДОБАВИТЬ ДОСТУП ТОЛЬКО АДМИНУ
@app.route("/clients/create", methods=["POST", "GET"])
@register_breadcrumb(app, ".clients.create", "Добавление клиента")
@login_required
def clients_create():
    form = FormClientsCreate()
    if form.validate_on_submit() and form.create_submit.data:
        data = DotMap({
            "name": form.name.data,
            "surname": form.surname.data if len(form.surname.data) != 0 else None,
            "phone": form.phone.data,
            "telegram": form.telegram.data if len(form.telegram.data) != 0 else None,
            "comment": form.comment.data if len(form.comment.data) != 0 else None,
            "discount": int(form.discount.data),
        })
        new_client = db.create_client(data)
        return redirect(url_for('clients_show', client_id=new_client.new_id))
    return render_template("clients/create.htm", form=form)

@app.route("/clients", methods=["POST", "GET"])
@register_breadcrumb(app, ".clients", "Клиенты")
@register_menu(app, ".clients", "Клиенты", order=3)
@login_required
def clients():
    search = FormClientsSearch()
    values = DotMap({
        "field_name": search.field_name.data,
        "query": search.query.data if search.query.data is not None else '',
        "is_payed": search.is_payed.data
    })
    clients = db.get_all_clients_details(values)
    return render_template("clients/index.htm",
        clients=clients,
        search=search
    )

@app.route("/user/logout")
def user_logout():
    if current_user.is_authenticated:
        logout_user()
        flash("Вы вышли из учетной записи", "success")
        return redirect(url_for("user_auth"))
    return redirect(url_for("user_auth"))

# ! ДОБАВИТЬ ДОБАВЛЕНИ ПОЛЬЗОВАТЕЛЯ ДЛЯ АДМИНА
@app.route("/user/auth", methods=["POST", "GET"])
@register_breadcrumb(app, ".user_auth", "Авторизация")
def user_auth():
    if current_user.is_authenticated:
        return redirect(url_for("index"))
    form = FormUserAuth()
    if form.validate_on_submit():
        user = db.get_user_by_login(DotMap({"login": form.login}))
        if user != False and check_password_hash(user.password, form.pswd.data):
            user_login = UserLogin().create(user)
            login_user(user_login)
            return redirect(request.args.get("next") or url_for("index"))
        form.login.errors.append("Логин или пароль введен неверно")
    return render_template("user/auth.htm", form=form)

@app.context_processor
def context_processor():
    if current_user.is_authenticated:
        return dict(user=current_user.user)
    return dict()

db = None
@app.before_request
def before_request():
    global db
    db = DB(get_db())

@app.teardown_appcontext
def close_db(error):
    if hasattr(g, 'link_db'):
        g.link_db.close()

def connect_db():
    # ! ВНЕСТИ ИЗМЕНЕНИЯ (ИЗМЕНИТЬ ПОЛЬЗОВАТЕЛЯ)
    return psycopg2.connect("dbname=rent user=postgres password=1234 host=localhost")

def get_db():
    if not hasattr(g, "link_db"):
        g.link_db = connect_db()
    return g.link_db

@login_manager.user_loader
def load_user(user_id):
    return UserLogin().fromDB(user_id, db)

if __name__ == "__main__":
    app.run(debug=True)