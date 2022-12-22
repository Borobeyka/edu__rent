from flask_wtf import FlaskForm
from wtforms import SubmitField, SelectField, StringField, TextAreaField
from wtforms.fields import DateTimeLocalField

def FormEstimatesCreate(clients):
    class _FormEstimatesCreate(FlaskForm):
        choices = [(-1, "")] + \
            [(client.id, client.surname + " " + client.name) for client in clients]
        client_id = SelectField("Клиент", choices=choices)
        project = StringField("Проект")
        start_date = DateTimeLocalField("Дата выдачи", format="%Y-%m-%dT%H:%M")
        close_date = DateTimeLocalField("Дата возврата", format="%Y-%m-%dT%H:%M")
        comment = TextAreaField("Комментарий")
        create_submit = SubmitField("Создать смету")
    return _FormEstimatesCreate()