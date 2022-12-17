from flask_wtf import FlaskForm
from wtforms import SubmitField, SelectField, StringField, BooleanField

class FormClientsSearch(FlaskForm):
    choices = [
        ("all", "Все поля"),
        ("name", "Имя"),
        ("phone", "Телефон"),
        ("telegram", "Telegram"),
        ("comment", "Комментарий")
    ]
    field_name = SelectField("", choices=choices, default="all")
    query = StringField("", render_kw={"placeholder": "Введите запрос..."})
    is_payed = BooleanField("Задолженность", default=False)
    search_submit = SubmitField("Поиск")